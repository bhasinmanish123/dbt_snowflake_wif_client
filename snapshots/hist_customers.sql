{% snapshot hist_customers %}

{{
    config(
      target_schema='HIST',
      unique_key='customer_id',
      strategy='check',
      check_cols=['city']
    )
}}

select
    customer_id,
    first_name,
    last_name,
    city,
    signup_date
from {{ ref('customers') }}

{% endsnapshot %}
