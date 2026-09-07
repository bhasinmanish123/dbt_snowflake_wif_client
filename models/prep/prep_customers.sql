-- prep model — lands in PREP schema (or CI_<actor>_PREP on PR)
select
    ID,
    FIRST_NAME,
    LAST_NAME,
    EMAIL,
    CITY
from {{ ref('customers') }}
