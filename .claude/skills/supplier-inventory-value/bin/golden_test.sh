#!/usr/bin/env bash
# golden_test.sh — replay every golden/*.json fixture into a scratch folder and byte-compare the
# export against the reference CSV from the ticket it was built from. Read-only; the ticket
# folders are never touched. Exit 0 only if every fixture matches.
set -uo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
SKILL="$ROOT/.claude/skills/supplier-inventory-value"
scratch="$(mktemp -d)"; trap 'rm -rf "$scratch"' EXIT

fail=0
for fx in "$SKILL"/golden/*.json; do
  name="$(basename "$fx" .json)"
  read -r invocation ref rows < <(python3 -c "
import json,sys; d=json.load(open(sys.argv[1]))
print(d['invocation'].replace(' ', '\x1f'), d['reference_output'], d['expect']['row_count'])" "$fx")
  IFS=$'\x1f' read -r -a args <<< "$invocation"
  echo "== $name: ${args[*]}"
  out="$scratch/$name"
  if ! bash "$SKILL/bin/run.sh" "${args[@]}" --out "$out"; then
    echo "✗ $name: run.sh failed" >&2; fail=1; continue
  fi
  got="$(ls "$out"/final_deliverables/*_records.csv)"
  if [[ "$(basename "$got")" != "$(basename "$ref")" ]]; then
    echo "✗ $name: filename $(basename "$got") != $(basename "$ref")" >&2; fail=1
  elif cmp -s "$got" "$ROOT/$ref"; then
    echo "✓ $name: byte-identical to $ref ($rows rows)"
  else
    echo "✗ $name: export differs from $ref" >&2; diff "$ROOT/$ref" "$got" | head -20 >&2; fail=1
  fi
done
exit $fail
