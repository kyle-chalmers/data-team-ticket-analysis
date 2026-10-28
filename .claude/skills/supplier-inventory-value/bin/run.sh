#!/usr/bin/env bash
# run.sh — Phases 0-3 of /supplier-inventory-value: validate params, render + gate the SQL, run QC
# and the step query read-only, export the CSV, and re-read it. Leaf helper: it may name the
# warehouse CLI (snow); the SKILL.md orchestration stays tool-neutral.
#
# Usage:
#   bash .claude/skills/supplier-inventory-value/bin/run.sh --ticket DATA-13 --group-by nation \
#        [--region EUROPE] [--top-n 10] [--assignee kyle] [--out DIR]
#
#   --out DIR  write everything under DIR instead of the ticket folder (the golden test uses this).
#
# Exit codes: 0 ok · 1 bad params · 2 render gate · 3 warehouse error · 4 QC hard-halt · 5 CSV check
set -uo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
SKILL="$ROOT/.claude/skills/supplier-inventory-value"
TW=(bash "$ROOT/bin/tw")

ticket="" group_by="" region="ALL" top_n=0 top_n_given=0 assignee="" out=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --ticket)   ticket="${2:-}"; shift 2 ;;
    --group-by) group_by="${2:-}"; shift 2 ;;
    --region)   region="${2:-}"; shift 2 ;;
    --top-n)    top_n="${2:-}"; top_n_given=1; shift 2 ;;
    --assignee) assignee="${2:-}"; shift 2 ;;
    --out)      out="${2:-}"; shift 2 ;;
    *) echo "run: unknown argument: $1" >&2; exit 1 ;;
  esac
done

# ---- Phase 0: parameter validation ----
[[ "$ticket" =~ ^DATA-[0-9]+$ ]] || { echo "run: --ticket must look like DATA-<n> (got '$ticket')" >&2; exit 1; }
case "$group_by" in
  region)    label="region_name" ;;
  nation)    label="nation_name" ;;
  part_type) label="part_type" ;;
  *) echo "run: --group-by must be region, nation or part_type (got '$group_by')" >&2; exit 1 ;;
esac
region="$(printf '%s' "$region" | tr '[:lower:]' '[:upper:]')"
[[ "$region" =~ ^[A-Z][A-Z\ ]*$ ]] || { echo "run: --region must be a region name like EUROPE (got '$region')" >&2; exit 1; }
[[ "$top_n" =~ ^[0-9]+$ && ( "$top_n" -ge 1 || "$top_n_given" -eq 0 ) ]] || { echo "run: --top-n must be a whole number >= 1 (got '$top_n')" >&2; exit 1; }
# (whether the region exists is a QC hard-halt check, against the live REGION table)

conn="$("${TW[@]}" effective_config.py --root "$ROOT" --json \
  | python3 -c "import json,sys;print(json.load(sys.stdin)['seams']['warehouse']['connection'])")" \
  || { echo "run: could not resolve the warehouse connection from the effective config" >&2; exit 3; }

if [[ -n "$out" ]]; then
  tdir="$out"
else
  if [[ -z "$assignee" ]]; then
    existing="$(ls -d "$ROOT"/tickets/*/"$ticket" 2>/dev/null | head -1)"
    if [[ -n "$existing" ]]; then
      tdir="$existing"
    else
      assignee="$("${TW[@]}" effective_config.py --root "$ROOT" --json \
        | python3 -c "import json,sys;print(json.load(sys.stdin)['project']['assignee_dir'])")"
      tdir="$ROOT/tickets/$assignee/$ticket"
    fi
  else
    tdir="$ROOT/tickets/$assignee/$ticket"
  fi
fi
mkdir -p "$tdir"/{source_materials,final_deliverables,qc_queries,exploratory_analysis}

scope=""
[[ "$region" != "ALL" ]] && scope="$(printf '%s' "$region" | tr '[:upper:] ' '[:lower:]_')_"
stem="1_${scope}inventory_value_by_${group_by}"
vars=(group_by="$group_by" group_label="$label" region_filter="$region" top_n="$top_n")
header="-- warehouse-target: SNOWFLAKE_SAMPLE_DATA.TPCH_SF1 (read-only)"

# ---- Phase 1: render + gate (halt on any gate error, warnings included) ----
render() {  # render TEMPLATE DEST
  local body
  body="$("${TW[@]}" render_and_validate.sh "$1" "${vars[@]}" --strict)" \
    || { echo "run: render gate failed for $1" >&2; exit 2; }
  { echo "$header"; echo "-- $ticket: rendered by /supplier-inventory-value (group_by=$group_by region=$region top_n=$top_n)"; echo "$body"; } > "$2"
}
render "$SKILL/sql/qc.sql.tmpl" "$tdir/qc_queries/1_reconciliation.sql"
render "$SKILL/sql/inventory_value.sql.tmpl" "$tdir/final_deliverables/$stem.sql"

query() {  # query SQLFILE CSVOUT
  snow sql -f "$1" --format csv -c "$conn" > "$2" 2>"$2.err" \
    || { echo "run: warehouse error on $1:" >&2; cat "$2.err" >&2; rm -f "$2.err"; exit 3; }
  rm -f "$2.err"
  "${TW[@]}" split_and_export.sh --strip-only "$2" >/dev/null
}

# ---- Phase 2: QC (atomic checkpoint) ----
qc_csv="$(mktemp)"; trap 'rm -f "$qc_csv"' EXIT
query "$tdir/qc_queries/1_reconciliation.sql" "$qc_csv"
python3 - "$qc_csv" <<'PY' || exit 4
import csv, sys
rows = list(csv.DictReader(open(sys.argv[1])))
rows = [{k.lower(): v for k, v in r.items()} for r in rows]
if len(rows) != 8:
    sys.exit(f"QC: expected 8 check rows, got {len(rows)}")
hard_fail = 0
for r in rows:
    ok = r["pass"].strip().lower() == "true"
    mark = "PASS" if ok else ("FAIL" if r["tier"] == "hard-halt" else "WARN")
    print(f"  {mark:4} [{r['tier']}] {r['check_name']}: expected {r['expected']}, actual {r['actual']}")
    if not ok and r["tier"] == "hard-halt":
        hard_fail += 1
if hard_fail:
    sys.exit(f"QC: {hard_fail} hard-halt check(s) failed; nothing exported")
PY

# ---- Phase 3: export (deterministic) + re-read ----
tmp_csv="$tdir/final_deliverables/$stem.csv.tmp"
query "$tdir/final_deliverables/$stem.sql" "$tmp_csv"
# Snowflake returns the header in uppercase; lowercase row 1 only, data rows stay exactly as returned.
python3 - "$tmp_csv" <<'PY'
import sys
p = sys.argv[1]
lines = open(p, encoding="utf-8").read().splitlines()
lines[0] = lines[0].lower()
open(p, "w", encoding="utf-8").write("\n".join(lines) + "\n")
PY
n="$(($(wc -l < "$tmp_csv") - 1))"
final="$tdir/final_deliverables/${stem}_${n}_records.csv"
rm -f "$tdir"/final_deliverables/"${stem}"_*_records.csv
mv "$tmp_csv" "$final"

python3 - "$final" "$label" "$top_n" <<'PY' || exit 5
import csv, sys
path, label, top_n = sys.argv[1], sys.argv[2], int(sys.argv[3])
raw = open(path, "rb").read()
errs = []
if any(b > 127 for b in raw):
    errs.append("non-ASCII bytes in the CSV")
rows = list(csv.reader(raw.decode("ascii", "replace").splitlines()))
if rows[0] != ["rank", label, "inventory_value"]:
    errs.append(f"header is {rows[0]}, expected rank,{label},inventory_value")
data = rows[1:]
if not data:
    errs.append("no data rows")
if top_n and len(data) > top_n:
    errs.append(f"{len(data)} rows exceed --top-n {top_n}")
groups = [r[1] for r in data]
if len(set(groups)) != len(groups):
    errs.append("duplicate groups in the output")
vals = [float(r[2]) for r in data]
if any(a < b for a, b in zip(vals, vals[1:])):
    errs.append("inventory_value is not non-increasing")
ranks = [int(r[0]) for r in data]
if ranks and (ranks[0] != 1 or any(b < a for a, b in zip(ranks, ranks[1:]))):
    errs.append("ranks do not start at 1 and ascend")
for e in errs:
    print("  CSV FAIL " + e, file=sys.stderr)
if errs:
    sys.exit(1)
print(f"  CSV PASS {len(data)} rows, header row 1, unique groups, sorted, ASCII only; total {sum(vals):,.2f}")
PY

echo "run: wrote $final"
