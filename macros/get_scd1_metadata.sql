{% macro get_scd1_metadata(model_name) %}
  {% set query %}
    select source_table, unique_key, order_by, columns
    from {{ source('raw', 'meta_table') }}
    where trim(lower(model_name)) = '{{ model_name | lower }}'
  {% endset %}

  {% do log("SCD1 Metadata Query: " ~ query, info=True) %}

  {% set results = run_query(query) %}

  {% if execute and results and results.columns | length > 0 %}
    {% set row = results.rows[0] %}
    {% do log("SCD1 Metadata Result: " ~ row, info=True) %}
    {% set source_table = row[0] %}
    {% set unique_key = row[1] %}
    {% set order_by = row[2] %}
    {% set columns = row[3].split(',') | map('trim') | list %}

    {{ return({
      "source_table": source_table,
      "unique_key": unique_key,
      "order_by": order_by,
      "columns": columns
    }) }}
  {% else %}
    {% do log("No metadata found for model: " ~ model_name, info=True) %}
    {% do exceptions.raise_compiler_error("No metadata found for model: " ~ model_name) %}
  {% endif %}
{% endmacro %}
