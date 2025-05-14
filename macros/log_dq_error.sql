{% macro log_dq_error(model_name, error_type, column_name, failed_count) %}
    {{ return(adapter.dispatch('log_dq_error', 'my_project')(
        model_name=model_name,
        error_type=error_type,
        column_name=column_name,
        failed_count=failed_count
    )) }}
{% endmacro %}

{% macro default__log_dq_error(model_name, error_type, column_name, failed_count) %}
    insert into {{ target.database }}.{{ target.schema }}.dq_audit_log (
        model_name,
        error_type,
        column_name,
        failed_count,
        logged_at
    )
    values (
        '{{ model_name }}',
        '{{ error_type }}',
        '{{ column_name }}',
        {{ failed_count }},
        current_timestamp()
    )
{% endmacro %}
