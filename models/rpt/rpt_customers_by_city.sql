-- rpt model — lands in RPT schema (or CI_<actor>_RPT on PR)
-- reads from the prep model to show cross-folder dependency
select
    CITY,
    count(*) as CUSTOMER_COUNT
from {{ ref('prep_customers') }}
group by CITY
