#!/usr/bin/env bash
# ============================================================
# test.sh — dbt TEST-DB deploy (runs AFTER CI passes, before merge)
# Edit this per repo to customize the TEST dbt commands.
# The workflow (dbt_ci.yml → test-deploy job) just runs: ./test.sh
#
# Purpose:
#   CI (ci.sh) builds in a throwaway personal schema (CI_<user>).
#   This step deploys the same models into a SHARED, stable TEST
#   database/schema so reviewers can inspect real data before merge.
#
# NOTE: `dbt build` ALREADY runs seeds + models + tests together.
#
# Env vars available:
#   DBT_TARGET     (default: test)
#   DBT_SELECT     (optional — e.g. "state:modified+")
#   FULL_REFRESH   (default: false)
# ============================================================
set -euo pipefail

TARGET="${DBT_TARGET:-test}"

echo "=== dbt TEST deploy (target: $TARGET) ==="

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

echo "=== TEST deploy complete ==="
