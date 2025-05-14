-- models/metadata/meta_status_new_scd1.sql

select *
from {{ source('raw', 'meta_table') }}
where model_name = 'status_new_scd1'
