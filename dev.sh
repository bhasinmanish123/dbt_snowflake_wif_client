#!/usr/bin/env bash
# ============================================================
# dev.sh — dbt DEV deploy (runs AFTER CI passes, before TEST)
# Edit this per repo to customize the DEV dbt commands.
# The workflow (dbt_ci.yml → dev-deploy job) just runs: ./dev.sh
#
# Purpose:
#   CI (ci.sh) VALIDATES in a throwaway personal schema (CI_<user>).
#   This step DEPLOYS the models into the SHARED DEV database (AIRBNB)
#   using stable schemas (MAIN / PREP / RPT) — the shared dev landing
#   zone before promoting to TEST and PROD.
#
# NOTE: `dbt build` ALREADY runs seeds + models + tests together.
#
# Env vars available:
#   DBT_TARGET     (default: dev)
#   DBT_SELECT     (optional — e.g. "state:modified+")
#   FULL_REFRESH   (default: false)
# ============================================================
set -euo pipefail

TARGET="${DBT_TARGET:-dev}"

echo "=== dbt DEV deploy (target: $TARGET) ==="

dbt deps || true

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

echo "=== DEV deploy complete ==="
