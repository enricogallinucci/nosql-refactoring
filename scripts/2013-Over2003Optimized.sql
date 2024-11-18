--========================================================= 2023 Optimized ===============================================================================
SET search_path TO aa_SDSS2003_optimized, public;
SHOW search_path;

--********************************************************* New tables *********************************************************************
DROP TABLE IF EXISTS PhotozRF;
CREATE TABLE PhotozRF AS (
	SELECT p.objid as key,
    			(to_jsonb(p.*) - 'objid') AS value 
	FROM sdss_relational2.PhotozRF p
);
ALTER TABLE PhotozRF ADD PRIMARY KEY (key);

DROP TABLE IF EXISTS Field;
CREATE TABLE Field AS (
	SELECT f.fieldid as key,
    			(to_jsonb(f.*) - 'fieldid') AS value 
	FROM sdss_relational2.Field f
);
ALTER TABLE Field ADD PRIMARY KEY (key);

DROP TABLE IF EXISTS Frame;
CREATE TABLE Frame AS (
	SELECT f.fieldid as key1, f.zoom AS key2,
    			(to_jsonb(f.*) - ARRAY['fieldid', 'zoom']) AS value  
	FROM sdss_relational2.Frame f
);
ALTER TABLE Frame ADD PRIMARY KEY (key1, key2);

DROP TABLE IF EXISTS GalSpecIndx;
CREATE TABLE GalSpecIndx AS (
	SELECT g.specObjID as key,
    		(to_jsonb(g.*) - 'specObjID') AS value 
	FROM sdss_relational2.GalSpecIndx g
);
ALTER TABLE GalSpecIndx ADD PRIMARY KEY (key);

--*********************************************************** Queries *************************************************************************
-- (10.66%)	SELECT p.objId, p.run, p.rerun, p.camcol, p.field, p.obj, p.type, p.ra, p.dec, p.u, p.g, p.r, p.i, p.z, p.Err_u, p.Err_g, p.Err_r, p.Err_i, p.Err_z FROM db_2013.PhotoPrimary p WHERE p.objID in ({objidlist}) LIMIT 1;
EXPLAIN (ANALYZE TRUE, COSTS FALSE, SUMMARY true)
SELECT p.key, p.value->>'run', p.value->>'rerun', p.value->>'camcol', p.value->>'field', p.value->>'obj', p.value->>'type', p.value->>'ra', p.value->>'dec', p.value->>'u', p.value->>'g', p.value->>'r', p.value->>'i', p.value->>'z', p.value->>'err_u', p.value->>'err_g', p.value->>'err_r', p.value->>'err_i', p.value->>'err_z' 
FROM PhotoObjAll_Primary p 
WHERE p.key IN (1237645941824356443) --({objidlist})
LIMIT 1;

-- (1.33%)	SELECT p.objid, p.run, p.rerun, p.camcol, p.field, p.obj, p.type, p.ra, p.dec, p.u, p.g, p.r, p.i, p.z, p.Err_u, p.Err_g, p.Err_r, p.Err_i, p.Err_z FROM db_2013.photoprimary p WHERE p.objID in ({objidlist}) limit 50000
EXPLAIN (ANALYZE TRUE, COSTS FALSE, SUMMARY true)
SELECT p.key, p.value->>'run', p.value->>'rerun', p.value->>'camcol', p.value->>'field', p.value->>'obj', p.value->>'type', p.value->>'ra', p.value->>'dec', p.value->>'u', p.value->>'g', p.value->>'r', p.value->>'i', p.value->>'z', p.value->>'err_u', p.value->>'err_g', p.value->>'err_r', p.value->>'err_i', p.value->>'err_z' 
FROM PhotoObjAll_Primary p 
WHERE p.key IN (1237645941824356443) --({objidlist})
LIMIT 50000;

-- (14.13%)	select g.objid, pz.z, pz.zerr, pzr.z, pzr.zerr, poa.u, poa.err_u, poa.g, poa.err_g, poa.r, poa.err_r, poa.i, poa.err_i, poa.z, poa.err_z from db_2013.galaxy as g join db_2013.photoz as pz on g.objid = pz.objid join db_2013.photozrf as pzr on g.objid = pzr.objid join db_2013.photoobjall as poa on g.objid = poa.objid where g.objid in ({objidlist}) and (g.flags & 262144) = 0
EXPLAIN (ANALYZE TRUE, COSTS FALSE, SUMMARY true)
-- Galaxies that are NOT primary objects
SELECT g.key,
				g.value->'Photoz'->>'z', g.value->'Photoz'->>'zerr', 
				pzr.value->>'z', pzr.value->>'zerr', 
				g.value->>'u', g.value->>'g', g.value->>'r', g.value->>'i', g.value->>'z',
				gc.value->>'err_u', gc.value->>'err_g', gc.value->>'err_r', gc.value->>'err_i', gc.value->>'err_z' 
FROM PhotoObjAll_Galaxy as g 
	JOIN PhotozRF pzr ON pzr.key=g.KEY
	JOIN PhotoObjAll_GalaxyComplementary gc ON gc.key=g.key
WHERE g.key IN (1237674649922306099) --({objidlist})
	AND ((g.value->>'flags')::int8 & 262144) = 0
UNION ALL
-- Galaxies that are primary objects
SELECT g.key,
				p.value->>'z', p.value->>'zerr', 
				pzr.value->>'z', pzr.value->>'zerr', 
				g.value->>'u', g.value->>'g', g.value->>'r', g.value->>'i', g.value->>'z',
				g.value->>'err_u', g.value->>'err_g', g.value->>'err_r', g.value->>'err_i', g.value->>'err_z' 
FROM (
			SELECT  pp.KEY, pp.value||pc.value AS value
			FROM (SELECT * FROM PhotoObjAll_Primary WHERE key IN (1237674649922306099)) pp  --({objidlist})
				JOIN (SELECT * FROM PhotoObjAll_PrimaryComplementary WHERE key IN (1237674649922306099)) pc ON pp.KEY=pc.KEY  --({objidlist})
			WHERE (pp.value->>'type')::int4=3 --AND (pc.value->>'type')::int4=3 --class='GALAXY' (see https://skyserver.sdss.org/dr1/en/help/browser/browser.asp)
			) as g 
	JOIN Photoz as p ON g.key=p.key
	JOIN PhotozRF pzr ON pzr.key=g.KEY
WHERE ((g.value->>'flags')::int8 & 262144) = 0
;

-- (5.47%)	select * from db_2013.specobjall where specobjid = {specobjid}
EXPLAIN (ANALYZE TRUE, COSTS FALSE, SUMMARY true)
SELECT *
FROM SpecObjAll s1
WHERE s1.key = 308567250191804420 -- {specobjid}
UNION ALL
SELECT s2.key, s2.value||jsonb_build_object('specobjid',g.value->'SpecObj'->>'specobjid', 'ra', g.value->'SpecObj'->>'ra', 'dec', g.value->'SpecObj'->>'dec', 'z', g.value->'SpecObj'->>'z')
FROM SpecObjAll_Complementary s2
  JOIN PhotoObjAll_Galaxy g ON g.key=s2.KEY
WHERE s2.key = 308567250191804420; -- {specobjid}

-- (4.68%)	select * from db_2013.photoz where objid={objid}
EXPLAIN (ANALYZE TRUE, COSTS FALSE, SUMMARY true)
SELECT p.key, p.value 
FROM Photoz p
WHERE p.key = 1237645941824356443 -- {objid}
UNION ALL
SELECT g.key, (g.value->'Photoz')::jsonb||c.value
FROM PhotoObjAll_Galaxy g
  JOIN Photoz_Complementary c ON g.key=c.key
WHERE g.key = 1237645941824356443; -- {objid}

-- (10.78%)	select * from db_2013.photoobjall where objid= {objid}
EXPLAIN (ANALYZE TRUE, COSTS FALSE, SUMMARY true)
SELECT p.key, p.value 
FROM PhotoObjAll p
WHERE p.key = 1237656511207048216 -- {objid}
UNION ALL
SELECT p.key, p.value||c.value 
FROM PhotoObjAll_Primary p
  JOIN PhotoObjAll_PrimaryComplementary c ON p.key=c.key
WHERE p.key = 1237656511207048216 -- {objid}
UNION ALL
SELECT g.key, (g.value-ARRAY['Photoz','SpecObj'])||c.value
FROM PhotoObjAll_Galaxy g
  JOIN PhotoObjAll_GalaxyComplementary c ON g.key=c.key
WHERE g.key = 1237656511207048216 -- {objid}
;

-- (3.49%)	select * from db_2013.frame where fieldid={fieldid}
EXPLAIN (ANALYZE TRUE, COSTS FALSE, SUMMARY true)
SELECT *
FROM Frame
WHERE key1 = 1237651250943492096 AND key2 = 25; -- frameid={frameid}

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


