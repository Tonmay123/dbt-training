-- macros/get_metadata_from_table.sql
{% macro get_metadata_from_table(model_name) %}
    {% set query %}
        select
            source_table,
            unique_key,
            order_by,
            columns  -- Columns are stored as an array
        from `your_project.your_dataset.tbl_meta_dp`
        where model_name = '{{ model_name }}'
    {% endset %}

    {% set results = run_query(query) %}
    
    {% if execute %}
        {% set row = results[0] %}
        
        {% set source_table = row['source_table'] %}
        {% set unique_key = row['unique_key'] %}
        {% set order_by = row['order_by'] %}
        {% set columns = row['columns'] %}
        
        {% set meta_dict = {
            'source_table': source_table,
            'unique_key': unique_key,
            'order_by': order_by,
            'columns': columns
        } %}
        
        -- Debug print to ensure the metadata is being correctly set
        {% do log(meta_dict, info=True) %}
        
        {{ return(meta_dict) }}
    {% endif %}
{% endmacro %}
