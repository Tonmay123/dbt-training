-- macros/get_latest_status.sql

{% macro get_latest_status(model_name) %}
    SELECT *
    FROM {{ ref(model_name) }}
    WHERE dbt_valid_to IS NULL
{% endmacro %}
