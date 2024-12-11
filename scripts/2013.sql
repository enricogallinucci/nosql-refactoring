--========================================================= 2003 Original ===============================================================================
DROP SCHEMA IF EXISTS aa_SDSS2013 CASCADE;
CREATE SCHEMA aa_SDSS2013;
SET search_path TO aa_SDSS2013, public;
SHOW search_path;

DROP TABLE IF EXISTS PhotoObjAll;
CREATE TABLE PhotoObjAll AS (
	SELECT	p.objid as key,
    			(to_jsonb(p.*) - 'objid') AS value 
  FROM sdss_relational2.PhotoObjAll AS p);
ALTER TABLE PhotoObjAll ADD PRIMARY KEY (key);
ANALYZE PhotoObjAll;

-- Photoz should have a FK to PhotoObjAll correspondin to a 0..1-1 relationship
DROP TABLE IF EXISTS Photoz;
CREATE TABLE Photoz AS (
	SELECT p.objid as key,
    		(to_jsonb(p.*) - 'objid') AS value
	FROM sdss_relational2.photoz p);
ALTER TABLE Photoz ADD PRIMARY KEY (key);
ANALYZE Photoz;

-- SpecObjAll should have a FK to PhotoObjAll correspondin to a *-1 relationship
DROP TABLE IF EXISTS SpecObjAll;
CREATE TABLE SpecObjAll AS (
	SELECT s.specObjID as key,
    		(to_jsonb(s.*) - 'specObjID') AS value
	FROM sdss_relational2.SpecObjAll AS s);
ALTER TABLE SpecObjAll ADD PRIMARY KEY (key);
ANALYZE SpecObjAll;

DROP TABLE IF EXISTS PhotozRF;
CREATE TABLE PhotozRF AS (
	SELECT p.objid as key,
    			(to_jsonb(p.*) - 'objid') AS value 
	FROM sdss_relational2.PhotozRF p
);
ALTER TABLE PhotozRF ADD PRIMARY KEY (key);
ANALYZE PhotozRF;

DROP TABLE IF EXISTS Field;
CREATE TABLE Field AS (
	SELECT f.fieldid as key,
    			(to_jsonb(f.*) - 'fieldid') AS value 
	FROM sdss_relational2.Field f
);
ALTER TABLE Field ADD PRIMARY KEY (key);
ANALYZE Field;

DROP TABLE IF EXISTS Frame;
CREATE TABLE Frame AS (
	SELECT f.fieldid as key1, f.zoom AS key2,
    			(to_jsonb(f.*) - ARRAY['fieldid', 'zoom']) AS value  
	FROM sdss_relational2.Frame f
);
ALTER TABLE Frame ADD PRIMARY KEY (key1, key2);
ANALYZE Frame;

DROP TABLE IF EXISTS GalSpecIndx;
CREATE TABLE GalSpecIndx AS (
	SELECT g.specObjID as key,
    		(to_jsonb(g.*) - 'specObjID') AS value 
	FROM sdss_relational2.GalSpecIndx g
);
ALTER TABLE GalSpecIndx ADD PRIMARY KEY (key);
ANALYZE GalSpecIndx;

--*********************************************************** Queries *************************************************************************
-- (10.66%)	SELECT p.objId, p.run, p.rerun, p.camcol, p.field, p.obj, p.type, p.ra, p.dec, p.u, p.g, p.r, p.i, p.z, p.Err_u, p.Err_g, p.Err_r, p.Err_i, p.Err_z FROM db_2013.PhotoPrimary p WHERE p.objID in ({objidlist}) LIMIT 1;
EXPLAIN (ANALYZE TRUE, COSTS FALSE, SUMMARY true)
SELECT p.key, p.value->>'run', p.value->>'rerun', p.value->>'camcol', p.value->>'field', p.value->>'obj', p.value->>'type', p.value->>'ra', p.value->>'dec', p.value->>'u', p.value->>'g', p.value->>'r', p.value->>'i', p.value->>'z', p.value->>'err_u', p.value->>'err_g', p.value->>'err_r', p.value->>'err_i', p.value->>'err_z' 
FROM PhotoObjAll p 
WHERE (p.value->>'mode')::int8=1
	AND p.key IN (1237645941824356443) --({objidlist})
LIMIT 1;

-- (1.33%)	SELECT p.objid, p.run, p.rerun, p.camcol, p.field, p.obj, p.type, p.ra, p.dec, p.u, p.g, p.r, p.i, p.z, p.Err_u, p.Err_g, p.Err_r, p.Err_i, p.Err_z FROM db_2013.photoprimary p WHERE p.objID in ({objidlist}) limit 50000
EXPLAIN (ANALYZE TRUE, COSTS FALSE, SUMMARY true)
SELECT p.key, p.value->>'run', p.value->>'rerun', p.value->>'camcol', p.value->>'field', p.value->>'obj', p.value->>'type', p.value->>'ra', p.value->>'dec', p.value->>'u', p.value->>'g', p.value->>'r', p.value->>'i', p.value->>'z', p.value->>'err_u', p.value->>'err_g', p.value->>'err_r', p.value->>'err_i', p.value->>'err_z' 
FROM PhotoObjAll p 
WHERE (p.value->>'mode')::int8=1
	AND p.key IN (1237645941824356443) --({objidlist})
LIMIT 50000;

-- (14.13%)	select g.objid, pz.z, pz.zerr, pzr.z, pzr.zerr, poa.u, poa.err_u, poa.g, poa.err_g, poa.r, poa.err_r, poa.i, poa.err_i, poa.z, poa.err_z from db_2013.galaxy as g join db_2013.photoz as pz on g.objid = pz.objid join db_2013.photozrf as pzr on g.objid = pzr.objid join db_2013.photoobjall as poa on g.objid = poa.objid where g.objid in ({objidlist}) and (g.flags & 262144) = 0
EXPLAIN (ANALYZE TRUE, COSTS FALSE, SUMMARY true)
SELECT g.key,
				p.value->>'z', p.value->>'zerr', 
				pzr.value->>'z', pzr.value->>'zerr', 
				g.value->>'u', g.value->>'g', g.value->>'r', g.value->>'i', g.value->>'z',
				g.value->>'err_u', g.value->>'err_g', g.value->>'err_r', g.value->>'err_i', g.value->>'err_z' 
FROM PhotoObjAll as g 
	JOIN PhotozRF pzr ON pzr.key=g.KEY
	JOIN Photoz as p ON g.key=p.key
WHERE (g.value->>'type')::int8=3 --class='GALAXY' (see https://skyserver.sdss.org/dr1/en/help/browser/browser.asp)
	AND ((g.value->>'flags')::int8 & 262144) = 0
  AND g.key IN (1237648703525224703) --({objidlist})
;

-- (5.47%)	select * from db_2013.specobjall where specobjid = {specobjid}
EXPLAIN (ANALYZE TRUE, COSTS FALSE, SUMMARY true)
SELECT *
FROM SpecObjAll s
WHERE s.key = 308567250191804420; -- {specobjid}

-- (4.68%)	select * from db_2013.photoz where objid={objid}
EXPLAIN (ANALYZE TRUE, COSTS FALSE, SUMMARY true)
SELECT p.key, p.value 
FROM Photoz p
WHERE p.key = 1237645941824356443; -- {objid}

-- (10.78%)	select * from db_2013.photoobjall where objid= {objid}
EXPLAIN (ANALYZE TRUE, COSTS FALSE, SUMMARY true)
SELECT p.key, p.value 
FROM PhotoObjAll p
WHERE p.key = 1237656511207048216 -- {objid}
;

-- (3.49%)	select * from db_2013.frame where fieldid={fieldid}
EXPLAIN (ANALYZE TRUE, COSTS FALSE, SUMMARY true)
SELECT *
FROM Frame
WHERE key1 = 1237651250943492096; -- fieldid={fieldid}

-- (2.63%)	select * from db_2013.field where fieldid={fieldid}
EXPLAIN (ANALYZE TRUE, COSTS FALSE, SUMMARY true)
SELECT *
FROM Field
WHERE key = 1237651250943492096; -- fieldid={fieldid}

-- (2.73%)	select * from db_2013.galspecindx where specobjid={specobjid}
EXPLAIN (ANALYZE TRUE, COSTS FALSE, SUMMARY true)
SELECT *
FROM GalSpecIndx
WHERE key = 930106061497591808; -- specobjid={specobjid}
