{% macro scd1_merge(model_name, source_table, unique_key, order_by, columns) %}
    {{ config(
        materialized = 'incremental',
        unique_key = unique_key,
        invalidate_hard_deletes=True
    ) }}

    with source_data as (
        select
            {% for col in columns %}
                {{ col }},
            {% endfor %}
            row_number() over (partition by {{ unique_key }} order by {{ order_by }}) as row_num
        from {{ source('raw', source_table) }}
    ),

    latest_source as (
        select *
        from source_data
        where row_num = 1
    ),

    final as (
    select 
        {% for col in columns %}
            s.{{ col }}{{ "," if not loop.last }}
        {% endfor %},
        {% if is_incremental() %}
            coalesce(t.inserted_at, current_timestamp()) as inserted_at,
        {% else %}
            current_timestamp() as inserted_at,
        {% endif %}
        current_timestamp() as updated_at
    from latest_source s
    {% if is_incremental() %}
    left join {{ this }} t
        on s.{{ unique_key }} = t.{{ unique_key }}
    where 
        t.{{ unique_key }} is null
        or {% for col in columns %}
            s.{{ col }} != t.{{ col }}{% if not loop.last %} or {% endif %}
        {% endfor %}
    {% endif %}
)


    select * 
    from final
    order by {{ unique_key }}
{% endmacro %}