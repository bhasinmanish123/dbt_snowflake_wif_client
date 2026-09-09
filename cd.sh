#!/usr/bin/env bash
# ============================================================
# cd.sh — dbt CD commands (runs on merge to main)
# Edit this per repo to customize the CD dbt commands.
# The workflow (dbt_cd.yml) just runs: ./cd.sh
#
# NOTE: `dbt build` ALREADY runs seeds + models + tests together.
#       Set RUN_SEED_FIRST=true ONLY if you must load seeds
#       BEFORE the build (e.g. seeds feed a pre-hook). Rare.
#
# Env vars available:
#   DBT_TARGET       (default: prod)
#   RUN_SEED_FIRST   (default: false)
#   DBT_SELECT       (optional — e.g. "tag:nightly")
#   FULL_REFRESH     (default: false)
# ============================================================
set -euo pipefail

TARGET="${DBT_TARGET:-prod}"

echo "=== dbt CD deploy (target: $TARGET) ==="

dbt deps || true

# ---- Optional: seed BEFORE build (rare — build already seeds) ----
if [ "${RUN_SEED_FIRST:-false}" = "true" ]; then
  echo "Loading seeds first..."
  dbt seed --target "$TARGET"
fi

# ---- Build (seeds + models + tests) ----
BUILD_CMD="dbt build --target $TARGET"

if [ -n "${DBT_SELECT:-}" ]; then
  BUILD_CMD="$BUILD_CMD --select ${DBT_SELECT}"
fi

if [ "${FULL_REFRESH:-false}" = "true" ]; then
  BUILD_CMD="$BUILD_CMD --full-refresh"
fi

echo "Running: $BUILD_CMD"
$BUILD_CMD

echo "=== CD complete ==="
