DO $$
DECLARE
    n INT := 2; -- Set this to the desired value or pass it dynamically
    dupl_schema_name TEXT := format('sdss_relational_%sx', n);
    new_id_offset BIGINT := 1e15; -- Offset for generating new IDs (ensures uniqueness)
	current_new_id BIGINT := 0;
	all_columns TEXT;
BEGIN
    -- Step 1: Drop the schema if it exists
    IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = dupl_schema_name) THEN
        EXECUTE format('DROP SCHEMA %I CASCADE', dupl_schema_name);
    END IF;

    -- Step 2: Create the new schema
    EXECUTE format('CREATE SCHEMA %I', dupl_schema_name);

    -- Step 3: Create the mapping table in the new schema
    EXECUTE format('CREATE TABLE %I.mapping (
                        objid_orig BIGINT NOT NULL,
                        objid_new BIGINT NOT NULL
                    )', dupl_schema_name);

    -- Step 4: Insert original values into the mapping table
    EXECUTE format('INSERT INTO %I.mapping (objid_orig, objid_new)
                    SELECT objid, objid
                    FROM sdss_relational2.photoobjall', dupl_schema_name);

    -- Step 5: Insert duplicates into the mapping table
    FOR i IN 2..n LOOP
        EXECUTE format('INSERT INTO %I.mapping (objid_orig, objid_new)
                        SELECT objid, (row_number() OVER ()) + %s - 1
                        FROM sdss_relational2.photoobjall', dupl_schema_name, current_new_id);
        current_new_id := current_new_id + (SELECT COUNT(*) FROM sdss_relational2.photoobjall);
    END LOOP;

    -- Step 6: Create the new photoobjall table in the new schema
    EXECUTE format('CREATE TABLE %I.photoobjall AS
                    SELECT * FROM sdss_relational2.photoobjall WHERE FALSE', dupl_schema_name);

    -- Step 7: Insert duplicates into the new photoobjall table
	SELECT string_agg(('p.'||column_name), ', ')
    INTO all_columns
    FROM information_schema.columns
    WHERE table_schema = 'sdss_relational2' AND table_name = 'photoobjall' AND column_name != 'objid';
	
	EXECUTE format('INSERT INTO %I.photoobjall
					SELECT m.objid_new AS objid, %s
					FROM sdss_relational2.photoobjall p
					JOIN %I.mapping m ON p.objid = m.objid_orig',
					dupl_schema_name, all_columns, dupl_schema_name);

	-- Step 8: Insert duplicates into the new specobjall table
    EXECUTE format('CREATE TABLE %I.specobjall AS
                    SELECT * FROM sdss_relational2.specobjall WHERE FALSE', dupl_schema_name);
					
    EXECUTE format('ALTER TABLE %I.specobjall ADD COLUMN specobjid_orig double precision', dupl_schema_name);
					
	SELECT string_agg(('s.'||column_name), ', ')
    INTO all_columns
    FROM information_schema.columns
    WHERE table_schema = 'sdss_relational2' AND table_name = 'specobjall' 
		AND column_name NOT IN ('bestobjid','specobjid');
	
    EXECUTE format('INSERT INTO %I.specobjall
                    SELECT 
						CASE WHEN m.objid_orig=m.objid_new
						THEN s.specobjid
						ELSE (row_number() OVER ())
						END AS specobijd,
					m.objid_new as bestobjid, %s, s.specobjid as specobjid_orig
					FROM sdss_relational2.specobjall s
					JOIN %I.mapping m ON s.bestobjid = m.objid_orig', dupl_schema_name, all_columns, dupl_schema_name);

	-- Step 9: galspecextra
    EXECUTE format('CREATE TABLE %I.galspecextra AS
                    SELECT * FROM sdss_relational2.galspecextra WHERE FALSE', dupl_schema_name);

	EXECUTE format('alter table %I.galspecextra 
					alter column specobjid type double precision', dupl_schema_name);
					
	SELECT string_agg(('x.'||column_name), ', ')
    INTO all_columns
    FROM information_schema.columns
    WHERE table_schema = 'sdss_relational2' AND table_name = 'galspecextra' 
		AND column_name NOT IN ('specobjid');
		
    EXECUTE format('INSERT INTO %I.galspecextra
                    SELECT s2.specobjid, %s
					FROM sdss_relational2.galspecextra x
					JOIN %I.specobjall s2 ON s2.specobjid_orig = x.specobjid', dupl_schema_name, all_columns, dupl_schema_name);

	-- Step 10: galspecindx
    EXECUTE format('CREATE TABLE %I.galspecindx AS
                    SELECT * FROM sdss_relational2.galspecindx WHERE FALSE', dupl_schema_name);

	EXECUTE format('alter table %I.galspecindx 
					alter column specobjid type double precision', dupl_schema_name);
					
	SELECT string_agg(('x.'||column_name), ', ')
    INTO all_columns
    FROM information_schema.columns
    WHERE table_schema = 'sdss_relational2' AND table_name = 'galspecindx' 
		AND column_name NOT IN ('specobjid');
		
    EXECUTE format('INSERT INTO %I.galspecindx
                    SELECT s2.specobjid, %s
					FROM sdss_relational2.galspecindx x
					JOIN %I.specobjall s2 ON s2.specobjid_orig = x.specobjid', dupl_schema_name, all_columns, dupl_schema_name);

	-- Step 11: photoz
    EXECUTE format('CREATE TABLE %I.photoz AS
                    SELECT * FROM sdss_relational2.photoz WHERE FALSE', dupl_schema_name);
					
	SELECT string_agg(('x.'||column_name), ', ')
    INTO all_columns
    FROM information_schema.columns
    WHERE table_schema = 'sdss_relational2' AND table_name = 'photoz' 
		AND column_name NOT IN ('objid');
		
    EXECUTE format('INSERT INTO %I.photoz
                    SELECT m.objid_new, %s
					FROM sdss_relational2.photoz x
					JOIN %I.mapping m ON x.objid = m.objid_orig', dupl_schema_name, all_columns, dupl_schema_name);

	-- Step 12: photozrf
    EXECUTE format('CREATE TABLE %I.photozrf AS
                    SELECT * FROM sdss_relational2.photozrf WHERE FALSE', dupl_schema_name);
					
	SELECT string_agg(('x.'||column_name), ', ')
    INTO all_columns
    FROM information_schema.columns
    WHERE table_schema = 'sdss_relational2' AND table_name = 'photozrf' 
		AND column_name NOT IN ('objid');
		
    EXECUTE format('INSERT INTO %I.photozrf
                    SELECT m.objid_new, %s
					FROM sdss_relational2.photozrf x
					JOIN %I.mapping m ON x.objid = m.objid_orig', dupl_schema_name, all_columns, dupl_schema_name);

	-- Step 13: zoospec
    EXECUTE format('CREATE TABLE %I.zoospec AS
                    SELECT * FROM sdss_relational2.zoospec WHERE FALSE', dupl_schema_name);
					
	SELECT string_agg(('x.'||column_name), ', ')
    INTO all_columns
    FROM information_schema.columns
    WHERE table_schema = 'sdss_relational2' AND table_name = 'zoospec' 
		AND column_name NOT IN ('objid');
		
    EXECUTE format('INSERT INTO %I.zoospec
                    SELECT m.objid_new, %s
					FROM sdss_relational2.zoospec x
					JOIN %I.mapping m ON x.objid = m.objid_orig', dupl_schema_name, all_columns, dupl_schema_name);

    -- Step 14: copy/paste other tables: field, frame, platex
    EXECUTE format('CREATE TABLE %I.field AS SELECT * FROM sdss_relational2.field', dupl_schema_name);
    EXECUTE format('CREATE TABLE %I.frame AS SELECT * FROM sdss_relational2.frame', dupl_schema_name);
    EXECUTE format('CREATE TABLE %I.platex AS SELECT * FROM sdss_relational2.platex', dupl_schema_name);

    RAISE NOTICE 'Schema % created successfully.', dupl_schema_name;

    
END;
$$;
