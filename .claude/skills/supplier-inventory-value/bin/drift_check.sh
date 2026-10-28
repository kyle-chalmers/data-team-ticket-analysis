#!/usr/bin/env bash
# drift_check.sh — Phase-0 catch: confirm every object/view this workflow reads is still reachable.
# Exit non-zero on any unreachable object so the skill halts before doing work.
set -uo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
# Connection comes from the merged config (never read stack.yaml directly).
CONN="$(bash "$ROOT/bin/tw" effective_config.py --root "$ROOT" --json \
  | python3 -c "import json,sys;print(json.load(sys.stdin)['seams']['warehouse']['connection'])")"

# The objects this workflow reads (matches read_objects in SKILL.md).
OBJECTS=(
  "SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.PARTSUPP"
  "SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.PART"
  "SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.SUPPLIER"
  "SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.NATION"
  "SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.REGION"
)

if [[ ${#OBJECTS[@]} -eq 0 ]]; then
  echo "drift_check: no OBJECTS defined yet — edit this file when you stamp the skill." >&2
  exit 0
fi

# Example for a Snowflake warehouse (swap the probe for your adapter's `describe`/`query` verb).
fail=0
for obj in "${OBJECTS[@]}"; do
  if snow sql -q "DESCRIBE TABLE $obj" -c "$CONN" >/dev/null 2>&1 \
     || snow sql -q "DESCRIBE VIEW $obj" -c "$CONN" >/dev/null 2>&1; then
    echo "✓ $obj"
  else
    echo "✗ UNREACHABLE: $obj" >&2; fail=1
  fi
done
exit $fail
