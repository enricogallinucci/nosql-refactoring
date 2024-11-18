--========================================================= 2023 Optimized ===============================================================================
DROP SCHEMA IF EXISTS aa_SDSS2013_optimized CASCADE;
CREATE SCHEMA aa_SDSS2013_optimized;
SET search_path TO aa_SDSS2013_optimized, public;
SHOW search_path;

-- This table contains all galaxies
-- Galaxies that are NOT primary objects in 2003 optimized
DROP TABLE IF EXISTS PhotoObjAll_Galaxy;
CREATE TABLE PhotoObjAll_Galaxy AS (
SELECT g.key, jsonb_build_object(
				'Photoz', jsonb_build_object('z', g.value->'Photoz'->>'z', 'zerr', g.value->'Photoz'->>'zerr'), 
				'PhotozRF', jsonb_build_object('z', pzr.value->>'z', 'zerr', pzr.value->>'zerr'), 
				'u', g.value->>'u', 'g', g.value->>'g', 'r', g.value->>'r', 'i', g.value->>'i', 'z', g.value->>'z',
				'err_u', gc.value->>'err_u', 'err_g', gc.value->>'err_g', 'err_r', gc.value->>'err_r', 'err_i', gc.value->>'err_i', 'err_z', gc.value->>'err_z') AS value 
FROM aa_SDSS2003_optimized.PhotoObjAll_Galaxy as g 
	JOIN aa_SDSS2003_optimized.PhotozRF pzr ON pzr.key=g.KEY
	JOIN aa_SDSS2003_optimized.PhotoObjAll_GalaxyComplementary gc ON gc.key=g.key
WHERE ((g.value->>'flags')::int8 & 262144) = 0
UNION ALL
-- Galaxies that are primary objects in 2003 optimized
SELECT g.key, jsonb_build_object(
				'Photoz', jsonb_build_object('z', p.value->'Photoz'->>'z', 'zerr', p.value->'Photoz'->>'zerr'), 
				'PhotozRF', jsonb_build_object('z', pzr.value->>'z', 'zerr', pzr.value->>'zerr'), 
				'u', g.value->>'u', 'g', g.value->>'g', 'r', g.value->>'r', 'i', g.value->>'i', 'z', g.value->>'z',
				'err_u', g.value->>'err_u', 'err_g', g.value->>'err_g', 'err_r', g.value->>'err_r', 'err_i', g.value->>'err_i', 'err_z', g.value->>'err_z') AS value
FROM (
			SELECT  pp.KEY, pp.value||pc.value AS value
			FROM (SELECT * FROM aa_SDSS2003_optimized.PhotoObjAll_Primary) pp 
				JOIN (SELECT * FROM aa_SDSS2003_optimized.PhotoObjAll_PrimaryComplementary) pc ON pp.KEY=pc.KEY
			WHERE (pp.value->>'type')::int4=3 --AND (pc.value->>'type')::int4=3 --class='GALAXY' (see https://skyserver.sdss.org/dr1/en/help/browser/browser.asp)
			) as g 
	JOIN aa_SDSS2003_optimized.Photoz as p ON g.key=p.key
	JOIN aa_SDSS2003_optimized.PhotozRF pzr ON pzr.key=g.KEY
WHERE ((g.value->>'flags')::int8 & 262144) = 0
);
ALTER TABLE PhotoObjAll_Galaxy ADD PRIMARY KEY (key);

-- This table contains all complementary attributes of galaxies
-- Galaxies that are NOT primary objects in 2003 optimized
DROP TABLE IF EXISTS PhotoObjAll_GalaxyComplementary;
CREATE TABLE PhotoObjAll_GalaxyComplementary AS (
SELECT g.key, g.value-ARRAY['u', 'g', 'r', 'i', 'z', 'err_u', 'err_g', 'err_r', 'err_i', 'err_z'] AS value
FROM aa_SDSS2003_optimized.PhotoObjAll_Galaxy as g 
WHERE ((g.value->>'flags')::int8 & 262144) = 0
	AND EXISTS (SELECT 'Found' FROM aa_SDSS2003_optimized.Photoz as p WHERE g.key=p.key)
	AND EXISTS (SELECT 'Found' FROM aa_SDSS2003_optimized.PhotozRF as pzr WHERE g.key=pzr.key)
UNION ALL
-- Galaxies that are primary objects in 2003 optimized
SELECT g.key, g.value-ARRAY['u', 'g', 'r', 'i', 'z', 'err_u', 'err_g', 'err_r', 'err_i', 'err_z']
FROM (
			SELECT  pp.KEY, pp.value||pc.value AS value
			FROM (SELECT * FROM aa_SDSS2003_optimized.PhotoObjAll_Primary) pp 
				JOIN (SELECT * FROM aa_SDSS2003_optimized.PhotoObjAll_PrimaryComplementary) pc ON pp.KEY=pc.KEY
			WHERE (pp.value->>'type')::int4=3 --AND (pc.value->>'type')::int4=3 --class='GALAXY' (see https://skyserver.sdss.org/dr1/en/help/browser/browser.asp)
			) as g 
WHERE ((g.value->>'flags')::int8 & 262144) = 0
	AND EXISTS (SELECT 'Found' FROM aa_SDSS2003_optimized.Photoz as p WHERE g.key=p.key)
	AND EXISTS (SELECT 'Found' FROM aa_SDSS2003_optimized.PhotozRF as pzr WHERE g.key=pzr.key)
);
ALTER TABLE PhotoObjAll_GalaxyComplementary ADD PRIMARY KEY (key);

-- This table contains all photoobjects, except galaxies in PhotoObjAll_Galaxy
DROP TABLE IF EXISTS PhotoObjAll;
CREATE TABLE PhotoObjAll AS (
-- This takes all PhotoObjAll_Other in 2003 optimized
SELECT p.key, p.value 
FROM aa_SDSS2003_optimized.PhotoObjAll_Other p
UNION ALL
-- This takes all primary objects in 2003 optimized except those already included in PhotoObjAll_Galaxy
SELECT pp.key, pp.value||pc.value 
FROM aa_SDSS2003_optimized.PhotoObjAll_Primary pp
  JOIN aa_SDSS2003_optimized.PhotoObjAll_PrimaryComplementary pc ON pp.key=pc.KEY
WHERE (pp.value->>'type')::int4 <> 3 --OR (pc.value->>'type')::int4<>3 --class='GALAXY' (see https://skyserver.sdss.org/dr1/en/help/browser/browser.asp)
  OR ((pp.value->>'flags')::int8 & 262144) <> 0
	OR NOT EXISTS (SELECT 'Found' FROM aa_SDSS2003_optimized.Photoz as p WHERE pp.key=p.key)
	OR NOT EXISTS (SELECT 'Found' FROM aa_SDSS2003_optimized.PhotozRF as pzr WHERE pp.key=pzr.key)
UNION ALL
-- This takes all galaxies in 2003 optimized except those already included in PhotoObjAll_Galaxy
SELECT g.key, (g.value-ARRAY['Photoz','SpecObj'])::jsonb||c.value
FROM aa_SDSS2003_optimized.PhotoObjAll_Galaxy g
  JOIN aa_SDSS2003_optimized.PhotoObjAll_GalaxyComplementary c ON g.key=c.KEY
WHERE ((g.value->>'flags')::int8 & 262144) <> 0
	OR NOT EXISTS (SELECT 'Found' FROM aa_SDSS2003_optimized.Photoz as p WHERE g.key=p.key)
	OR NOT EXISTS (SELECT 'Found' FROM aa_SDSS2003_optimized.PhotozRF as pzr WHERE g.key=pzr.key)
);
ALTER TABLE PhotoObjAll ADD PRIMARY KEY (key);

-- This table contains SpecObjAll that are not embeded in PhotoObjAll_Galaxy
DROP TABLE IF EXISTS SpecObjAll;
CREATE TABLE SpecObjAll AS (
	SELECT *
	FROM aa_SDSS2003_optimized.SpecObjAll s
	UNION ALL
	SELECT c.KEY, c.value||(g.value->'SpecObj')::jsonb
	FROM aa_SDSS2003_optimized.SpecObjAll_Complementary c
	  JOIN aa_SDSS2003_optimized.PhotoObjAll_Galaxy g ON g.key=(c.value->>'bestobjid')::int8
);
ALTER TABLE SpecObjAll ADD PRIMARY KEY (key);

-- This table contains Photoz that are not embeded in PhotoObjAll_Galaxy
DROP TABLE IF EXISTS Photoz;
CREATE TABLE Photoz AS (
	SELECT *
	FROM (
	  SELECT *
	  FROM aa_SDSS2003_optimized.Photoz p
	  UNION ALL
		SELECT c.key, c.value||(g.value->'Photoz')::jsonb AS value
		FROM aa_SDSS2003_optimized.Photoz_Complementary c
			JOIN aa_SDSS2003_optimized.PhotoObjAll_Galaxy g ON g.key=c.key
		) p
	WHERE NOT EXISTS (SELECT 'Found' FROM PhotoObjAll_Galaxy g WHERE g.key=p.key )
);
ALTER TABLE Photoz ADD PRIMARY KEY (key);

-- This table contains the attributes of those Photoz embeded in PhotoObjAll_Galaxy but not projected there
DROP TABLE IF EXISTS Photoz_Complementary;
CREATE TABLE Photoz_Complementary AS (
	SELECT p.key, value-ARRAY['z','zerr'] AS value
	FROM (
	  SELECT *
	  FROM aa_SDSS2003_optimized.Photoz p
	  UNION ALL
		SELECT c.key, c.value||(g.value->'Photoz')::jsonb AS value
		FROM aa_SDSS2003_optimized.Photoz_Complementary c
			JOIN aa_SDSS2003_optimized.PhotoObjAll_Galaxy g ON g.key=c.key
		) p
	WHERE EXISTS (SELECT 'Found' FROM PhotoObjAll_Galaxy g WHERE g.key=p.key)
);
ALTER TABLE Photoz_Complementary ADD PRIMARY KEY (key);

--********************************************************* New tables *********************************************************************
-- This table contains PhotozRF that are not embeded in PhotoObjAll_Galaxy
DROP TABLE IF EXISTS PhotozRF;
CREATE TABLE PhotozRF AS (
	SELECT *
	FROM aa_SDSS2003_optimized.PhotozRF p
	WHERE NOT EXISTS (SELECT 'Found' FROM PhotoObjAll_Galaxy g WHERE g.key=p.key )
);
ALTER TABLE PhotozRF ADD PRIMARY KEY (key);

-- This table contains the attributes of those PhotozRF embeded in PhotoObjAll_Galaxy but not projected there
DROP TABLE IF EXISTS PhotozRF_Complementary;
CREATE TABLE PhotozRF_Complementary AS (
	SELECT p.key, value-ARRAY['z','zerr'] AS value
	FROM aa_SDSS2003_optimized.PhotozRF p
	WHERE EXISTS (SELECT 'Found' FROM PhotoObjAll_Galaxy g WHERE g.key=p.key)
);
ALTER TABLE PhotozRF_Complementary ADD PRIMARY KEY (key);

DROP TABLE IF EXISTS Field;
CREATE TABLE Field AS (
	SELECT * 
	FROM aa_SDSS2003_optimized.Field f
);
ALTER TABLE Field ADD PRIMARY KEY (key);

DROP TABLE IF EXISTS Frame;
CREATE TABLE Frame AS (
	SELECT *  
	FROM aa_SDSS2003_optimized.Frame f
);
ALTER TABLE Frame ADD PRIMARY KEY (key1, key2);

DROP TABLE IF EXISTS GalSpecIndx;
CREATE TABLE GalSpecIndx AS (
	SELECT * 
	FROM aa_SDSS2003_optimized.GalSpecIndx g
);
ALTER TABLE GalSpecIndx ADD PRIMARY KEY (key);


--*********************************************************** Queries *************************************************************************
-- (10.66%)	SELECT p.objId, p.run, p.rerun, p.camcol, p.field, p.obj, p.type, p.ra, p.dec, p.u, p.g, p.r, p.i, p.z, p.Err_u, p.Err_g, p.Err_r, p.Err_i, p.Err_z FROM db_2013.PhotoPrimary p WHERE p.objID in ({objidlist}) LIMIT 1;
EXPLAIN (ANALYZE TRUE, COSTS FALSE, SUMMARY true)
SELECT p.key, p.value->>'run', p.value->>'rerun', p.value->>'camcol', p.value->>'field', p.value->>'obj', p.value->>'type', p.value->>'ra', p.value->>'dec', p.value->>'u', p.value->>'g', p.value->>'r', p.value->>'i', p.value->>'z', p.value->>'err_u', p.value->>'err_g', p.value->>'err_r', p.value->>'err_i', p.value->>'err_z' 
FROM PhotoObjAll p
WHERE p.key IN (1237645941824356443) --({objidlist})
  AND (p.value->>'mode')::int4=1
UNION ALL
SELECT p.key, p.value->>'run', p.value->>'rerun', p.value->>'camcol', p.value->>'field', p.value->>'obj', p.value->>'type', p.value->>'ra', p.value->>'dec', p.value->>'u', p.value->>'g', p.value->>'r', p.value->>'i', p.value->>'z', p.value->>'err_u', p.value->>'err_g', p.value->>'err_r', p.value->>'err_i', p.value->>'err_z' 
FROM PhotoObjAll_Galaxy p
WHERE p.key IN (1237645941824356443) --({objidlist})
  AND (p.value->>'mode')::int4=1
LIMIT 1;

-- (1.33%)	SELECT p.objid, p.run, p.rerun, p.camcol, p.field, p.obj, p.type, p.ra, p.dec, p.u, p.g, p.r, p.i, p.z, p.Err_u, p.Err_g, p.Err_r, p.Err_i, p.Err_z FROM db_2013.photoprimary p WHERE p.objID in ({objidlist}) limit 50000
EXPLAIN (ANALYZE TRUE, COSTS FALSE, SUMMARY true)
SELECT p.key, p.value->>'run', p.value->>'rerun', p.value->>'camcol', p.value->>'field', p.value->>'obj', p.value->>'type', p.value->>'ra', p.value->>'dec', p.value->>'u', p.value->>'g', p.value->>'r', p.value->>'i', p.value->>'z', p.value->>'err_u', p.value->>'err_g', p.value->>'err_r', p.value->>'err_i', p.value->>'err_z' 
FROM PhotoObjAll p
WHERE p.key IN (1237645941824356443) --({objidlist})
  AND (p.value->>'mode')::int4=1
UNION ALL
SELECT p.key, p.value->>'run', p.value->>'rerun', p.value->>'camcol', p.value->>'field', p.value->>'obj', p.value->>'type', p.value->>'ra', p.value->>'dec', p.value->>'u', p.value->>'g', p.value->>'r', p.value->>'i', p.value->>'z', p.value->>'err_u', p.value->>'err_g', p.value->>'err_r', p.value->>'err_i', p.value->>'err_z' 
FROM PhotoObjAll_Galaxy p
WHERE p.key IN (1237645941824356443) --({objidlist})
  AND (p.value->>'mode')::int4=1
LIMIT 50000;

-- (14.13%)	select g.objid, pz.z, pz.zerr, pzr.z, pzr.zerr, poa.u, poa.err_u, poa.g, poa.err_g, poa.r, poa.err_r, poa.i, poa.err_i, poa.z, poa.err_z from db_2013.galaxy as g join db_2013.photoz as pz on g.objid = pz.objid join db_2013.photozrf as pzr on g.objid = pzr.objid join db_2013.photoobjall as poa on g.objid = poa.objid where g.objid in ({objidlist}) and (g.flags & 262144) = 0
EXPLAIN (ANALYZE TRUE, COSTS FALSE, SUMMARY true)
SELECT g.key, 
				g.value->'Photoz'->>'z', g.value->'Photoz'->>'zerr', 
				g.value->'PhotozRF'->>'z', g.value->'PhotozRF'->>'zerr', 
				g.value->>'u', g.value->>'g', g.value->>'r', g.value->>'i', g.value->>'z',
				g.value->>'err_u', g.value->>'err_g', g.value->>'err_r', g.value->>'err_i', g.value->>'err_z'
FROM PhotoObjAll_Galaxy g 
WHERE g.key IN (1237645941824356443); --({objidlist})

-- (5.47%)	select * from db_2013.specobjall where specobjid = {specobjid}
EXPLAIN (ANALYZE TRUE, COSTS FALSE, SUMMARY true)
SELECT *
FROM SpecObjAll s1
WHERE s1.key = 77628570523926528; -- {specobjid}

-- (4.68%)	select * from db_2013.photoz where objid={objid}
EXPLAIN (ANALYZE TRUE, COSTS FALSE, SUMMARY true)
SELECT p.key, p.value 
FROM Photoz p
UNION ALL
SELECT g.key, (g.value->'Photoz')::jsonb||c.value
FROM PhotoObjAll_Galaxy g
  JOIN Photoz_Complementary c ON g.key=c.key;

-- (10.78%)	select * from db_2013.photoobjall where objid= {objid}
EXPLAIN (ANALYZE TRUE, COSTS FALSE, SUMMARY true)
SELECT p.key, p.value 
FROM PhotoObjAll p
UNION ALL
SELECT g.key, (g.value-ARRAY['Photoz','PhotozRF'])::jsonb||c.value
FROM PhotoObjAll_Galaxy g
  JOIN PhotoObjAll_GalaxyComplementary c ON g.key=c.key;

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