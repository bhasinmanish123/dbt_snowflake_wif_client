#!/usr/bin/env bash
# ============================================================
# ci.sh — dbt CI commands (runs on PR)
# Edit this per repo to customize the CI dbt commands.
# The workflow (dbt_ci.yml) just runs: ./ci.sh
#
# NOTE: `dbt build` ALREADY runs seeds + models + tests together.
#       Only add a separate `dbt seed` if you need seeds loaded
#       BEFORE build for a specific reason (rare).
#
# Env vars available:
#   DBT_TARGET   (default: ci)
#   DBT_SELECT   (optional — e.g. "tag:daily" or "state:modified+")
# ============================================================
set -euo pipefail

TARGET="${DBT_TARGET:-ci}"

echo "=== dbt CI (target: $TARGET) ==="

dbt deps || true

# ---- Build (seeds + models + tests) ----
# dbt build handles seeds automatically. Use --select for subset.
if [ -n "${DBT_SELECT:-}" ]; then
  echo "Building selected: ${DBT_SELECT}"
  dbt build --target "$TARGET" --select "${DBT_SELECT}"
else
  echo "Building all (seeds + models + tests)"
  dbt build --target "$TARGET"
fi

echo "=== CI complete ==="
