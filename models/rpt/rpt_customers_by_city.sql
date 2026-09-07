-- rpt model — lands in RPT schema (or CI_<actor>_RPT on PR)
-- reads from prep model to show cross-folder dependency
select
    city,
    count(*) as customer_count
from {{ ref('prep_customers') }}
group by city
