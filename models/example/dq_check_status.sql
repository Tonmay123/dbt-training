WITH dq_check_status AS (
    SELECT * FROM {{ ref('staging_status_scd2') }}
),

not_null_errors AS (
    SELECT 
        'patient_id is null' AS error_type,
        surrogate_key,
        patient_id,
        status,
        substatus,
        status_date,
        referral_date,
        npi,
        NDC,
        dbt_valid_from,
        dbt_valid_to,
        dbt_updated_at
    FROM dq_check_status WHERE patient_id IS NULL

    UNION ALL

    SELECT 
        'status is null' AS error_type,
        surrogate_key,
        patient_id,
        status,
        substatus,
        status_date,
        referral_date,
        npi,
        NDC,
        dbt_valid_from,
        dbt_valid_to,
        dbt_updated_at
    FROM dq_check_status WHERE status IS NULL
),

duplicate_errors AS (
    SELECT 
        'duplicate patient_id + status_date' AS error_type,
        surrogate_key,
        patient_id,
        status,
        substatus,
        status_date,
        referral_date,
        npi,
        NDC,
        dbt_valid_from,
        dbt_valid_to,
        dbt_updated_at
    FROM dq_check_status
    GROUP BY 
        surrogate_key,
        patient_id,
        status,
        substatus,
        status_date,
        referral_date,
        npi,
        NDC,
        dbt_valid_from,
        dbt_valid_to,
        dbt_updated_at
    HAVING COUNT(*) > 1
),

domain_errors AS (
    SELECT 
        'invalid status value' AS error_type,
        surrogate_key,
        patient_id,
        status,
        substatus,
        status_date,
        referral_date,
        npi,
        NDC,
        dbt_valid_from,
        dbt_valid_to,
        dbt_updated_at
    FROM dq_check_status
    WHERE status NOT IN ('Pending', 'Active', 'Cancelled')
),

length_errors AS (
    SELECT 
        'npi not 10 digits' AS error_type,
        surrogate_key,
        patient_id,
        status,
        substatus,
        status_date,
        referral_date,
        npi,
        NDC,
        dbt_valid_from,
        dbt_valid_to,
        dbt_updated_at
    FROM dq_check_status
    WHERE LENGTH(CAST(npi AS STRING)) != 10
),

date_format_errors AS (
    SELECT 
        'referral_date is invalid' AS error_type,
        surrogate_key,
        patient_id,
        status,
        substatus,
        status_date,
        referral_date,
        npi,
        NDC,
        dbt_valid_from,
        dbt_valid_to,
        dbt_updated_at
    FROM dq_check_status
    WHERE SAFE.PARSE_DATE('%Y-%m-%d', CAST(referral_date AS STRING)) IS NULL
),

all_errors AS (
    SELECT * FROM not_null_errors
    UNION ALL
    SELECT * FROM duplicate_errors
    UNION ALL
    SELECT * FROM domain_errors
    UNION ALL
    SELECT * FROM length_errors
    UNION ALL
    SELECT * FROM date_format_errors
)

SELECT * FROM all_errors
