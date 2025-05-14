-- models/audit/dq_audit_log.sql

{{ config(
    materialized='table'
) }}

select
    cast(null as string) as model_name,
    cast(null as string) as error_type,
    cast(null as string) as column_name,
    cast(null as int64) as failed_count,
    current_timestamp() as logged_at
from unnest([1])  -- Dummy FROM clause
where false       -- Ensures no rows are inserted initially
