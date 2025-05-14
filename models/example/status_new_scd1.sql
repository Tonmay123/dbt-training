-- models/example/status_new_scd1.sql

{% set meta_data = load_result('meta_config').table[0] %}
{% set model_name = 'status_new_scd1' %}
{% set source_table = meta_data['source_table'] %}
{% set unique_key = meta_data['unique_key'] %}
{% set order_by = meta_data['order_by'] %}
{% set columns = meta_data['columns'].split(',') %}

-- Ensure metadata dependency
{{ ref('meta_config') }}

{{ scd1_merge(
    model_name = model_name,
    source_table = source_table,
    unique_key = unique_key,
    order_by = order_by,
    columns = columns
) }}
