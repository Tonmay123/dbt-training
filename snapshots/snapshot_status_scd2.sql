-- snapshots/status_snapshot.sql

{% snapshot status_snapshot %}
    {{
        config(
            target_schema='snapshots',
            unique_key='patient_id',
            strategy='timestamp',
            updated_at='status_date'
        )
    }}

    WITH staging_status_scd2 AS (
        SELECT
            *
        FROM raw.status
    )
    SELECT * FROM raw.status
    ORDER BY patient_id

{% endsnapshot %}
