-- prep model — lands in PREP schema (or CI_<actor>_PREP on PR)
select
    customer_id,
    first_name,
    last_name,
    city,
    signup_date
from {{ ref('customers') }}
-- ci test 1788777651
-- retrigger 1788778405
