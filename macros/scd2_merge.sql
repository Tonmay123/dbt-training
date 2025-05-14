{% macro scd2_merge(model_name, source_table, unique_key, order_by, columns) %}
    {{ config(
        materialized = 'incremental',
        unique_key = 'scd_id',
        on_schema_change = 'ignore'
    ) }}

    -- Step 1: Source data with latest record per unique_key
    with source_data as (
        select 
            {% for col in columns %}
                {{ col }},
            {% endfor %}
            row_number() over (partition by {{ unique_key }} order by {{ order_by }}) as row_num
        from {{ source('raw', source_table) }}
    )

    {% if is_incremental() %}

    -- Step 2: Get active records
    , active_records as (
        select *
        from {{ this }}
        where is_active = TRUE
    )

    -- Step 3: Detect changed or new rows
    , changed_records as (
        select s.*
        from (
            select * from source_data where row_num = 1
        ) s
        left join active_records t
            on s.{{ unique_key }} = t.{{ unique_key }}
        where 
            t.{{ unique_key }} is null
            or {% for col in columns %}
                s.{{ col }} != t.{{ col }}{% if not loop.last %} or {% endif %}
            {% endfor %}
    )

    -- Step 4: Expire existing records
    , expired_records as (
        select 
            {% for col in columns %}
                t.{{ col }},
            {% endfor %}
            current_timestamp() as updated_at,
            t.valid_from,
            current_timestamp() as valid_to,
            FALSE as is_active,
            t.scd_id
        from {{ this }} t
        join changed_records s
          on s.{{ unique_key }} = t.{{ unique_key }}
        where t.is_active = TRUE
    )

    -- Step 5: New versions
    , new_records as (
        select
            {% for col in columns %}
                s.{{ col }},
            {% endfor %}
            current_timestamp() as updated_at,
            current_timestamp() as valid_from,
            timestamp '9999-12-31' as valid_to,
            TRUE as is_active,
            GENERATE_UUID() as scd_id
        from changed_records s
    )

    select * from new_records
    union all
    select * from expired_records

    {% else %}

    -- Full refresh: all rows with active/latest flagged
    , with_flags as (
        select *, row_number() over (partition by {{ unique_key }} order by {{ order_by }}) as rn
        from source_data
    )

    select
        {% for col in columns %}
            {{ col }},
        {% endfor %}
        current_timestamp() as updated_at,
        current_timestamp() as valid_from,
        timestamp '9999-12-31' as valid_to,
        case when rn = 1 then TRUE else FALSE end as is_active,
        GENERATE_UUID() as scd_id
    from with_flags

    {% endif %}

    order by {{ unique_key }}

{% endmacro %}
