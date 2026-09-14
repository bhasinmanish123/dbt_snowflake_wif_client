-- ==================================================================
-- SNOWFLAKE CI/CD SETUP — DATABASE-BASED SEPARATION  (WIF / OIDC)
-- Run as ACCOUNTADMIN — one time.
--
-- Model:
--   CI   (PR opened)      → database AIRBNB, personal CI_<user> schemas
--   TEST (after CI passes) → database TEST  (folder routing → TEST.PREP / TEST.RPT)
--   PROD (on merge)        → database PROD  (folder routing → PROD.PREP / PROD.RPT)
--
-- Conventions:
--   warehouse = COMPUTE_WH
--   service   = GITHUB_ACTIONS_SERVICE_USER  (already exists, WIF OIDC)
--   auth      = Workload Identity Federation (OIDC) — no new secrets
--
-- Roles (each scoped to its own database):
--   DBT_CI_ROLE   → AIRBNB   (assumed already set up; shown for reference)
--   DBT_TEST_ROLE → TEST
--   DBT_PROD_ROLE → PROD
-- ==================================================================

USE ROLE ACCOUNTADMIN;

-- ==================================================================
-- STEP 1: Create the dedicated databases
-- ==================================================================
CREATE DATABASE IF NOT EXISTS TEST COMMENT = 'dbt TEST deploys (after CI passes, before merge)';
CREATE DATABASE IF NOT EXISTS PROD COMMENT = 'dbt PROD deploys (on merge to main)';

-- (Optional) pre-create the folder-routed schemas. dbt will create them
-- anyway given the DB-wide grants below, but pre-creating makes grants explicit.
CREATE SCHEMA IF NOT EXISTS TEST.MAIN COMMENT = 'dbt TEST — base/root models';
CREATE SCHEMA IF NOT EXISTS TEST.PREP COMMENT = 'dbt TEST — models/prep';
CREATE SCHEMA IF NOT EXISTS TEST.RPT  COMMENT = 'dbt TEST — models/rpt';
CREATE SCHEMA IF NOT EXISTS PROD.MAIN COMMENT = 'dbt PROD — base/root models';
CREATE SCHEMA IF NOT EXISTS PROD.PREP COMMENT = 'dbt PROD — models/prep';
CREATE SCHEMA IF NOT EXISTS PROD.RPT  COMMENT = 'dbt PROD — models/rpt';

-- ==================================================================
-- STEP 2: TEST role — scoped to the TEST database
-- ==================================================================
CREATE ROLE IF NOT EXISTS DBT_TEST_ROLE;

GRANT USAGE   ON WAREHOUSE COMPUTE_WH          TO ROLE DBT_TEST_ROLE;
GRANT USAGE   ON DATABASE  TEST                TO ROLE DBT_TEST_ROLE;
GRANT CREATE SCHEMA ON DATABASE TEST           TO ROLE DBT_TEST_ROLE;
GRANT ALL PRIVILEGES ON FUTURE SCHEMAS IN DATABASE TEST TO ROLE DBT_TEST_ROLE;
GRANT ALL PRIVILEGES ON FUTURE TABLES  IN DATABASE TEST TO ROLE DBT_TEST_ROLE;
GRANT ALL PRIVILEGES ON FUTURE VIEWS   IN DATABASE TEST TO ROLE DBT_TEST_ROLE;
-- existing (pre-created) schemas
GRANT USAGE, CREATE TABLE, CREATE VIEW ON ALL SCHEMAS IN DATABASE TEST TO ROLE DBT_TEST_ROLE;
-- explicit base-schema grants (MAIN is the profile base schema; PUBLIC as fallback)
GRANT USAGE, CREATE TABLE, CREATE VIEW ON SCHEMA TEST.MAIN   TO ROLE DBT_TEST_ROLE;
GRANT USAGE, CREATE TABLE, CREATE VIEW ON SCHEMA TEST.PUBLIC TO ROLE DBT_TEST_ROLE;

-- ==================================================================
-- STEP 3: PROD role — scoped to the PROD database
-- ==================================================================
CREATE ROLE IF NOT EXISTS DBT_PROD_ROLE;

GRANT USAGE   ON WAREHOUSE COMPUTE_WH          TO ROLE DBT_PROD_ROLE;
GRANT USAGE   ON DATABASE  PROD                TO ROLE DBT_PROD_ROLE;
GRANT CREATE SCHEMA ON DATABASE PROD           TO ROLE DBT_PROD_ROLE;
GRANT ALL PRIVILEGES ON FUTURE SCHEMAS IN DATABASE PROD TO ROLE DBT_PROD_ROLE;
GRANT ALL PRIVILEGES ON FUTURE TABLES  IN DATABASE PROD TO ROLE DBT_PROD_ROLE;
GRANT ALL PRIVILEGES ON FUTURE VIEWS   IN DATABASE PROD TO ROLE DBT_PROD_ROLE;
GRANT USAGE, CREATE TABLE, CREATE VIEW ON ALL SCHEMAS IN DATABASE PROD TO ROLE DBT_PROD_ROLE;
-- explicit base-schema grants (MAIN is the profile base schema; PUBLIC as fallback)
GRANT USAGE, CREATE TABLE, CREATE VIEW ON SCHEMA PROD.MAIN   TO ROLE DBT_PROD_ROLE;
GRANT USAGE, CREATE TABLE, CREATE VIEW ON SCHEMA PROD.PUBLIC TO ROLE DBT_PROD_ROLE;

-- ==================================================================
-- STEP 4: CI role — stays on AIRBNB (reference; likely already exists)
--   CI still builds personal CI_<user> schemas inside AIRBNB.
-- ==================================================================
CREATE ROLE IF NOT EXISTS DBT_CI_ROLE;
GRANT USAGE   ON WAREHOUSE COMPUTE_WH            TO ROLE DBT_CI_ROLE;
GRANT USAGE   ON DATABASE  AIRBNB                TO ROLE DBT_CI_ROLE;
GRANT CREATE SCHEMA ON DATABASE AIRBNB           TO ROLE DBT_CI_ROLE;
GRANT ALL PRIVILEGES ON FUTURE SCHEMAS IN DATABASE AIRBNB TO ROLE DBT_CI_ROLE;
GRANT ALL PRIVILEGES ON FUTURE TABLES  IN DATABASE AIRBNB TO ROLE DBT_CI_ROLE;
GRANT ALL PRIVILEGES ON FUTURE VIEWS   IN DATABASE AIRBNB TO ROLE DBT_CI_ROLE;

-- ==================================================================
-- STEP 5: (Optional) read access to source data
-- If TEST/PROD models read from raw sources that live in AIRBNB (or a
-- RAW database), grant SELECT so the deploy roles can read them.
-- Uncomment and adjust to your source location:
-- ------------------------------------------------------------------
-- GRANT USAGE  ON DATABASE AIRBNB                       TO ROLE DBT_TEST_ROLE;
-- GRANT USAGE  ON SCHEMA   AIRBNB.RAW                   TO ROLE DBT_TEST_ROLE;
-- GRANT SELECT ON ALL    TABLES IN SCHEMA AIRBNB.RAW    TO ROLE DBT_TEST_ROLE;
-- GRANT SELECT ON FUTURE TABLES IN SCHEMA AIRBNB.RAW    TO ROLE DBT_TEST_ROLE;
-- GRANT USAGE  ON DATABASE AIRBNB                       TO ROLE DBT_PROD_ROLE;
-- GRANT USAGE  ON SCHEMA   AIRBNB.RAW                   TO ROLE DBT_PROD_ROLE;
-- GRANT SELECT ON ALL    TABLES IN SCHEMA AIRBNB.RAW    TO ROLE DBT_PROD_ROLE;
-- GRANT SELECT ON FUTURE TABLES IN SCHEMA AIRBNB.RAW    TO ROLE DBT_PROD_ROLE;

-- ==================================================================
-- STEP 6: Grant roles to the EXISTING WIF service user (no new secret)
-- ==================================================================
GRANT ROLE DBT_CI_ROLE   TO USER GITHUB_ACTIONS_SERVICE_USER;
GRANT ROLE DBT_TEST_ROLE TO USER GITHUB_ACTIONS_SERVICE_USER;
GRANT ROLE DBT_PROD_ROLE TO USER GITHUB_ACTIONS_SERVICE_USER;

-- Optional: grant to ACCOUNTADMIN for manual inspection
GRANT ROLE DBT_TEST_ROLE TO ROLE ACCOUNTADMIN;
GRANT ROLE DBT_PROD_ROLE TO ROLE ACCOUNTADMIN;

-- ==================================================================
-- STEP 7: Verify
-- ==================================================================
SHOW DATABASES LIKE 'TEST';
SHOW DATABASES LIKE 'PROD';
SHOW ROLES LIKE 'DBT_%_ROLE';
SHOW GRANTS TO ROLE DBT_TEST_ROLE;
SHOW GRANTS TO ROLE DBT_PROD_ROLE;
SHOW GRANTS OF ROLE DBT_TEST_ROLE;   -- confirm granted to GITHUB_ACTIONS_SERVICE_USER
SHOW GRANTS OF ROLE DBT_PROD_ROLE;


-- ==================================================================
-- NOTES
-- ------------------------------------------------------------------
-- * WIF SUBJECT: the service user already has WORKLOAD_IDENTITY set for
--   the 'prod' GitHub environment, and every job (CI, test-deploy, CD)
--   runs in `environment: prod` — so the SAME OIDC subject is reused.
--   No WIF/subject changes needed.
--
-- * The generate_schema_name macro:
--     - CI  targets on pull_request → CI_<actor>_<PREP|RPT> in AIRBNB
--     - test/prod targets           → PREP / RPT (custom schema honored)
--   Because database is now set per target, PREP/RPT land in TEST.* and
--   PROD.* respectively — clean database separation.
-- ==================================================================


-- ==================================================================
-- CLEAN UP (if you ever need to tear the databases down):
-- ==================================================================
-- USE ROLE ACCOUNTADMIN;
-- REVOKE ROLE DBT_TEST_ROLE FROM USER GITHUB_ACTIONS_SERVICE_USER;
-- REVOKE ROLE DBT_PROD_ROLE FROM USER GITHUB_ACTIONS_SERVICE_USER;
-- DROP DATABASE IF EXISTS TEST;
-- DROP DATABASE IF EXISTS PROD;
-- DROP ROLE IF EXISTS DBT_TEST_ROLE;
-- DROP ROLE IF EXISTS DBT_PROD_ROLE;
-- ==================================================================
