-- models/kpis/kpi_count_by_status.sql

WITH kpi_count_by_status AS (
    {{ get_latest_status('staging_status_scd2') }}
)

SELECT
    status,
    COUNT(DISTINCT patient_id) AS patient_count
FROM kpi_count_by_status
GROUP BY status
