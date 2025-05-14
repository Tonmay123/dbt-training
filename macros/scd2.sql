-- macros/scd2.sql

{% macro apply_scd2(source_relation, unique_key, order_by_col) %}
  WITH base AS (
    SELECT * FROM {{ source_relation }}
  ),
  
  with_ranks AS (
    SELECT *,
      ROW_NUMBER() OVER (
        PARTITION BY {{ unique_key }} ORDER BY {{ order_by_col }}
      ) AS rn,
      LEAD({{ order_by_col }}) OVER (
        PARTITION BY {{ unique_key }} ORDER BY {{ order_by_col }}
      ) AS dbt_valid_to
    FROM base
  ),
  
  final AS (
    SELECT
        ROW_NUMBER() OVER () AS surrogate_key,
        *,
        CASE WHEN rn = 1 THEN status_date ELSE status_date END AS dbt_valid_from,
        CURRENT_DATE() AS dbt_updated_at,
        CASE WHEN dbt_valid_to IS NULL THEN 'Y' ELSE 'N' END AS active_flag
    FROM with_ranks
  )

  SELECT
    *
  EXCEPT(rn)
  FROM final
  ORDER BY surrogate_key ASC, patient_id ASC
{% endmacro %}
