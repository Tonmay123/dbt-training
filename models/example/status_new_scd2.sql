{% set columns = ['patient_id', 'status', 'substatus', 'status_date', 'referral_date', 'npi', 'ndc'] %}

{{ scd2_merge(
    model_name=this.name,
    source_table='status_scd2',
    unique_key='patient_id',
    order_by='status_date desc',
    columns=columns
) }}
