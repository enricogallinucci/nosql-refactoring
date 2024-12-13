SELECT 
    nspname AS schema_name,
    relname AS table_name,
	pg_total_relation_size(c.oid) total_size,
    pg_size_pretty(pg_total_relation_size(c.oid)) AS total_size_h,
    pg_size_pretty(pg_relation_size(c.oid)) AS table_size,
    pg_size_pretty(pg_indexes_size(c.oid)) AS indexes_size
FROM 
    pg_class c
JOIN 
    pg_namespace n ON n.oid = c.relnamespace
WHERE 
    (nspname like 'aa_%' or nspname like 'sdss_%')
    AND c.relkind = 'r'  -- Only include ordinary tables
ORDER BY 
    nspname, table_name, pg_total_relation_size(c.oid) DESC;

