-- ============================================================
-- customers_view: a VIEW built on top of the customers seed
-- Simple columns first, calculated columns last (SQLFluff ST06)
-- ============================================================

select
    customer_id,
    city,
    signup_date,
    first_name || ' ' || last_name as full_name
from {{ ref('customers') }}
-- WIF test
-- fix token
-- fix token
-- wif fix
-- wif fix
-- wif fix
-- test ci dev prod
-- test composite action setup-snowflake
-- test 2 manifest cache
