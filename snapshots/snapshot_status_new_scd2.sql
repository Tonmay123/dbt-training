{% snapshot snapshot_status_new_scd2 %}
{{
    config(
      target_schema='dbt_training',
      unique_key='patient_id',
      strategy='check',
      check_cols=['status', 'substatus', 'status_date', 'referral_date', 'npi', 'ndc']
    )
}}
select
    patient_id,
    status,
    substatus,
    status_date,
    referral_date,
    npi,
    ndc
from {{ source('raw', 'status_new') }}
{% endsnapshot %}
