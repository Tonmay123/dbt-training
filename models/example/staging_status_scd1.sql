{{ config(
    materialized='incremental',
    unique_key='scd_id'
) }}

WITH source_data AS (
    SELECT
        *,
        current_timestamp() AS updated_at
    FROM `festive-nova-446203-c5`.`raw`.`status_new`
),

-- Step 1: Existing active records in the target table
existing_active AS (
    SELECT *
    FROM {{ this }}
    WHERE is_active = TRUE
),

-- Step 2: Detect changes or new records, ensuring only one row per patient
changed_records AS (
    SELECT
        s.*,
        ROW_NUMBER() OVER (PARTITION BY s.patient_id ORDER BY s.status_date DESC) AS row_num
    FROM source_data s
    LEFT JOIN existing_active e
        ON s.patient_id = e.patient_id
        AND s.status = e.status
        AND s.substatus = e.substatus
        AND s.status_date = e.status_date
        AND s.referral_date = e.referral_date
        AND s.npi = e.npi
        AND s.ndc = e.ndc
    WHERE e.patient_id IS NULL  -- Insert new records
       OR s.updated_at > e.updated_at  -- Insert updated records
),

-- Step 3: Expire previous records (only one record per patient should be expired)
records_to_expire AS (
    SELECT
        e.*
    FROM existing_active e
    JOIN changed_records c
        ON e.patient_id = c.patient_id
    WHERE c.row_num = 1  -- Only expire the previous version if a new version exists
)

-- Final output: Insert new records and expire old records
SELECT
    s.patient_id,
    s.status,
    s.substatus,
    s.status_date,
    s.referral_date,
    s.npi,
    s.ndc,
    s.updated_at,
    s.updated_at AS valid_from,
    TIMESTAMP '9999-12-31' AS valid_to,
    TRUE AS is_active,
    GENERATE_UUID() AS scd_id
FROM changed_records s
WHERE s.row_num = 1  -- Only insert the most recent record

{% if is_incremental() %}
UNION ALL

-- Expire the previous records
SELECT
    e.patient_id,
    e.status,
    e.substatus,
    e.status_date,
    e.referral_date,
    e.npi,
    e.ndc,
    e.updated_at,
    e.valid_from,
    CURRENT_TIMESTAMP() AS valid_to,
    FALSE AS is_active,
    e.scd_id
FROM records_to_expire e
{% else %}

-- For full refresh, insert all records as new and active
SELECT
    s.patient_id,
    s.status,
    s.substatus,
    s.status_date,
    s.referral_date,
    s.npi,
    s.ndc,
    s.updated_at,
    s.updated_at AS valid_from,
    TIMESTAMP '9999-12-31' AS valid_to,
    TRUE AS is_active,
    GENERATE_UUID() AS scd_id
FROM source_data s
{% endif %}

-- Ensure proper ordering
ORDER BY patient_id ASC
