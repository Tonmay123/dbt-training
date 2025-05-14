WITH staging_status_scd2 AS (
    SELECT
        status.patient_id as patient_id,
        status.status AS status,          
        status.substatus AS substatus,
        status.status_date AS status_date,
        status.referral_date AS referral_date,
        CAST(status.npi AS STRING) AS npi,
        status.NDC AS NDC
    FROM raw.status
),

with_ranks AS (
    SELECT
        patient_id,
        status,
        substatus,
        status_date,
        referral_date,
        npi,
        NDC,
        ROW_NUMBER() OVER (PARTITION BY patient_id ORDER BY status_date) AS rn,
        LEAD(status_date) OVER (PARTITION BY patient_id ORDER BY status_date) AS dbt_valid_to
    FROM staging_status_scd2
),

final AS (
    SELECT
        ROW_NUMBER() OVER () AS surrogate_key,  -- new surrogate key
        patient_id,
        status,
        substatus,
        status_date,
        referral_date,
        npi,
        NDC,
        CASE 
            WHEN rn = 1 THEN referral_date
            ELSE status_date
        END AS dbt_valid_from,
        dbt_valid_to,
        CURRENT_DATE() AS dbt_updated_at,
        CASE 
            WHEN dbt_valid_to IS NULL THEN 'Y'
            ELSE 'N'
        END AS active_flag
    FROM with_ranks
)

SELECT
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
    dbt_updated_at,
    active_flag
FROM final
ORDER BY surrogate_key ASC, patient_id ASC
