-- models/example/status_new_scd1.sql

{% set meta = get_scd1_metadata('status_new_scd1') %}

{{ scd1_merge(
    model_name = 'status_new_scd1',
    source_table = meta.source_table,
    unique_key = meta.unique_key,
    order_by = meta.order_by,
    columns = meta.columns
) }}
