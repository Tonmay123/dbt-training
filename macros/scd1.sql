-- macros/scd1.sql

{% macro apply_scd1(source_relation, unique_key, order_by_col) %}
  WITH ranked_source AS (
    SELECT *,
      ROW_NUMBER() OVER (
        PARTITION BY {{ unique_key }}
        ORDER BY {{ order_by_col }} DESC
      ) AS row_num,
      FIRST_VALUE({{ order_by_col }}) OVER (PARTITION BY {{ unique_key }} ORDER BY {{ order_by_col }}) AS insert_date,
      MAX({{ order_by_col }}) OVER (PARTITION BY {{ unique_key }}) AS update_date
    FROM {{ source_relation }}
  )

  SELECT
    *
  EXCEPT(row_num)
  FROM ranked_source
  WHERE row_num = 1
  ORDER BY patient_id
{% endmacro %}
