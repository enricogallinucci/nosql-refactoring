-- This table contains all galaxies
-- Galaxies that are NOT primary objects in 2003 optimized
DROP TABLE IF EXISTS PhotoObjAll_Galaxy;
CREATE TABLE PhotoObjAll_Galaxy AS (
SELECT g.key, jsonb_build_object(
				'Photoz', jsonb_build_object('z', g.value->'Photoz'->>'z', 'zerr', g.value->'Photoz'->>'zerr'), 
				'PhotozRF', jsonb_build_object('z', pzr.value->>'z', 'zerr', pzr.value->>'zerr'), 
				'u', g.value->>'u', 'g', g.value->>'g', 'r', g.value->>'r', 'i', g.value->>'i', 'z', g.value->>'z', 'ra', g.value->>'ra', 'dec', g.value->>'dec',
				'err_u', gc.value->>'err_u', 'err_g', gc.value->>'err_g', 'err_r', gc.value->>'err_r', 'err_i', gc.value->>'err_i', 'err_z', gc.value->>'err_z') AS value 
FROM aa_SDSS2003_5x_optimized.PhotoObjAll_Galaxy as g 
	JOIN aa_SDSS2003_5x_optimized.PhotozRF pzr ON pzr.key=g.KEY
	JOIN aa_SDSS2003_5x_optimized.PhotoObjAll_GalaxyComplementary gc ON gc.key=g.key
WHERE ((g.value->>'flags')::int8 & 262144) = 0
UNION ALL
-- Galaxies that are primary objects in 2003 optimized
SELECT g.key, jsonb_build_object(
				'Photoz', jsonb_build_object('z', p.value->'Photoz'->>'z', 'zerr', p.value->'Photoz'->>'zerr'), 
				'PhotozRF', jsonb_build_object('z', pzr.value->>'z', 'zerr', pzr.value->>'zerr'), 
				'u', g.value->>'u', 'g', g.value->>'g', 'r', g.value->>'r', 'i', g.value->>'i', 'z', g.value->>'z', 'ra', g.value->>'ra', 'dec', g.value->>'dec',
				'err_u', g.value->>'err_u', 'err_g', g.value->>'err_g', 'err_r', g.value->>'err_r', 'err_i', g.value->>'err_i', 'err_z', g.value->>'err_z') AS value
FROM (
			SELECT  pp.KEY, pp.value||pc.value AS value
			FROM (SELECT * FROM aa_SDSS2003_5x_optimized.PhotoObjAll_Primary) pp 
				JOIN (SELECT * FROM aa_SDSS2003_5x_optimized.PhotoObjAll_PrimaryComplementary) pc ON pp.KEY=pc.KEY
			WHERE (pp.value->>'type')::int8=3 --AND (pc.value->>'type')::int4=3 --class='GALAXY' (see https://skyserver.sdss.org/dr1/en/help/browser/browser.asp)
			) as g 
	JOIN aa_SDSS2003_5x_optimized.Photoz as p ON g.key=p.key
	JOIN aa_SDSS2003_5x_optimized.PhotozRF pzr ON pzr.key=g.KEY
WHERE ((g.value->>'flags')::int8 & 262144) = 0
);
ALTER TABLE PhotoObjAll_Galaxy ADD PRIMARY KEY (key);
ANALYZE PhotoObjAll_Galaxy;

-- This table contains all complementary attributes of galaxies
-- Galaxies that are NOT primary objects in 2003 optimized
DROP TABLE IF EXISTS PhotoObjAll_GalaxyComplementary;
CREATE TABLE PhotoObjAll_GalaxyComplementary AS (
SELECT g.key, g.value-ARRAY['u', 'g', 'r', 'i', 'z', 'ra', 'dec', 'err_u', 'err_g', 'err_r', 'err_i', 'err_z'] AS value
FROM aa_SDSS2003_5x_optimized.PhotoObjAll_Galaxy as g 
WHERE ((g.value->>'flags')::int8 & 262144) = 0
	AND EXISTS (SELECT 'Found' FROM aa_SDSS2003_5x_optimized.Photoz as p WHERE g.key=p.key)
	AND EXISTS (SELECT 'Found' FROM aa_SDSS2003_5x_optimized.PhotozRF as pzr WHERE g.key=pzr.key)
UNION ALL
-- Galaxies that are primary objects in 2003 optimized
SELECT g.key, g.value-ARRAY['u', 'g', 'r', 'i', 'z', 'ra', 'dec', 'err_u', 'err_g', 'err_r', 'err_i', 'err_z']
FROM (
			SELECT  pp.KEY, pp.value||pc.value AS value
			FROM (SELECT * FROM aa_SDSS2003_5x_optimized.PhotoObjAll_Primary) pp 
				JOIN (SELECT * FROM aa_SDSS2003_5x_optimized.PhotoObjAll_PrimaryComplementary) pc ON pp.KEY=pc.KEY
			WHERE (pp.value->>'type')::int8=3 --AND (pc.value->>'type')::int4=3 --class='GALAXY' (see https://skyserver.sdss.org/dr1/en/help/browser/browser.asp)
			) as g 
WHERE ((g.value->>'flags')::int8 & 262144) = 0
	AND EXISTS (SELECT 'Found' FROM aa_SDSS2003_5x_optimized.Photoz as p WHERE g.key=p.key)
	AND EXISTS (SELECT 'Found' FROM aa_SDSS2003_5x_optimized.PhotozRF as pzr WHERE g.key=pzr.key)
);
ALTER TABLE PhotoObjAll_GalaxyComplementary ADD PRIMARY KEY (key);
ANALYZE PhotoObjAll_GalaxyComplementary;

-- This table contains all photoobjects, except galaxies in PhotoObjAll_Galaxy
DROP TABLE IF EXISTS PhotoObjAll_Primary;
CREATE TABLE PhotoObjAll_Primary AS (
-- This takes all primary objects in 2003 optimized except those already included in PhotoObjAll_Galaxy
SELECT p.key, jsonb_build_object('run', p.value->>'run', 'rerun', p.value->>'rerun', 'camcol', p.value->>'camcol', 'field', p.value->>'field', 'obj', p.value->>'obj', 'type', p.value->>'type', 'ra', p.value->>'ra', 'dec', p.value->>'dec', 'u', p.value->>'u', 'g', p.value->>'g', 'r', p.value->>'r', 'i', p.value->>'i', 'z', p.value->>'z', 'err_u', p.value->>'err_u', 'err_g', p.value->>'err_g', 'err_r', p.value->>'err_r', 'err_i', p.value->>'err_i', 'err_z', p.value->>'err_z' 
) AS value 
FROM aa_SDSS2003_5x_optimized.PhotoObjAll_Primary p
  JOIN aa_SDSS2003_5x_optimized.PhotoObjAll_PrimaryComplementary pc ON p.key=pc.KEY
WHERE (p.value->>'type')::int8 <> 3 --OR (pc.value->>'type')::int4<>3 --class='GALAXY' (see https://skyserver.sdss.org/dr1/en/help/browser/browser.asp)
  OR ((pc.value->>'flags')::int8 & 262144) <> 0
	OR NOT EXISTS (SELECT 'Found' FROM aa_SDSS2003_5x_optimized.Photoz as pz WHERE p.key=pz.key)
	OR NOT EXISTS (SELECT 'Found' FROM aa_SDSS2003_5x_optimized.PhotozRF as pzr WHERE p.key=pzr.key)
);
ALTER TABLE PhotoObjAll_Primary ADD PRIMARY KEY (key);
ANALYZE PhotoObjAll_Primary;

-- This table contains all photoobjects, except galaxies in PhotoObjAll_Galaxy
DROP TABLE IF EXISTS PhotoObjAll_PrimaryComplementary;
CREATE TABLE PhotoObjAll_PrimaryComplementary AS (
-- This takes all primary objects in 2003 optimized except those already included in PhotoObjAll_Galaxy
SELECT pp.key, (pp.value-ARRAY['run', 'rerun', 'camcol', 'field', 'obj', 'type', 'ra', 'dec', 'u', 'g', 'r', 'i', 'z', 'err_u', 'err_g', 'err_r', 'err_i', 'err_z'])||pc.value AS value
FROM aa_SDSS2003_5x_optimized.PhotoObjAll_Primary pp
  JOIN aa_SDSS2003_5x_optimized.PhotoObjAll_PrimaryComplementary pc ON pp.key=pc.KEY
WHERE (pp.value->>'type')::int8 <> 3 --OR (pc.value->>'type')::int4<>3 --class='GALAXY' (see https://skyserver.sdss.org/dr1/en/help/browser/browser.asp)
  OR ((pc.value->>'flags')::int8 & 262144) <> 0
	OR NOT EXISTS (SELECT 'Found' FROM aa_SDSS2003_5x_optimized.Photoz as p WHERE pp.key=p.key)
	OR NOT EXISTS (SELECT 'Found' FROM aa_SDSS2003_5x_optimized.PhotozRF as pzr WHERE pp.key=pzr.key)
);
ALTER TABLE PhotoObjAll_PrimaryComplementary ADD PRIMARY KEY (key);
ANALYZE PhotoObjAll_PrimaryComplementary;

-- This table contains all photoobjects, except galaxies in PhotoObjAll_Galaxy
DROP TABLE IF EXISTS PhotoObjAll_Other;
CREATE TABLE PhotoObjAll_Other AS (
-- This takes all PhotoObjAll_Other in 2003 optimized
SELECT p.key, p.value 
FROM aa_SDSS2003_5x_optimized.PhotoObjAll_Other p
UNION ALL
-- This takes all galaxies in 2003 optimized except those already included in PhotoObjAll_Galaxy
SELECT g.key, (g.value-ARRAY['Photoz','SpecObj'])::jsonb||gc.value
FROM aa_SDSS2003_5x_optimized.PhotoObjAll_Galaxy g
  JOIN aa_SDSS2003_5x_optimized.PhotoObjAll_GalaxyComplementary gc ON g.key=gc.KEY
WHERE (((gc.value->>'flags')::int8 & 262144) <> 0
	OR NOT EXISTS (SELECT 'Found' FROM aa_SDSS2003_5x_optimized.Photoz as p WHERE g.key=p.key)
	OR NOT EXISTS (SELECT 'Found' FROM aa_SDSS2003_5x_optimized.PhotozRF as pzr WHERE g.key=pzr.key))
);
ALTER TABLE PhotoObjAll_Other ADD PRIMARY KEY (key);
ANALYZE PhotoObjAll_Other;

-- This table contains all SpecObjAll
DROP TABLE IF EXISTS SpecObjAll;
CREATE TABLE SpecObjAll AS (
	SELECT *
	FROM aa_SDSS2003_5x_optimized.SpecObjAll s
	UNION ALL
	SELECT c.KEY, c.value||(g.value->'SpecObj')::jsonb
	FROM aa_SDSS2003_5x_optimized.SpecObjAll_Complementary c
	  JOIN aa_SDSS2003_5x_optimized.PhotoObjAll_Galaxy g ON g.key=(c.value->>'bestobjid')::int8
);
ALTER TABLE SpecObjAll ADD PRIMARY KEY (key);
ANALYZE SpecObjAll;

-- This table contains Photoz that are not embeded in PhotoObjAll_Galaxy
DROP TABLE IF EXISTS Photoz;
CREATE TABLE Photoz AS (
	SELECT *
	FROM (
	  SELECT *
	  FROM aa_SDSS2003_5x_optimized.Photoz p
	  UNION ALL
		SELECT c.key, c.value||(g.value->'Photoz')::jsonb AS value
		FROM aa_SDSS2003_5x_optimized.Photoz_Complementary c
			JOIN aa_SDSS2003_5x_optimized.PhotoObjAll_Galaxy g ON g.key=c.key
		) p
	WHERE NOT EXISTS (SELECT 'Found' FROM PhotoObjAll_Galaxy g WHERE g.key=p.key )
);
ALTER TABLE Photoz ADD PRIMARY KEY (key);
ANALYZE Photoz;

-- This table contains the attributes of those Photoz embeded in PhotoObjAll_Galaxy but not projected there
DROP TABLE IF EXISTS Photoz_Complementary;
CREATE TABLE Photoz_Complementary AS (
	SELECT p.key, value-ARRAY['z','zerr'] AS value
	FROM (
	  SELECT *
	  FROM aa_SDSS2003_5x_optimized.Photoz p
	  UNION ALL
		SELECT c.key, c.value||(g.value->'Photoz')::jsonb AS value
		FROM aa_SDSS2003_5x_optimized.Photoz_Complementary c
			JOIN aa_SDSS2003_5x_optimized.PhotoObjAll_Galaxy g ON g.key=c.key
		) p
	WHERE EXISTS (SELECT 'Found' FROM PhotoObjAll_Galaxy g WHERE g.key=p.key)
);
ALTER TABLE Photoz_Complementary ADD PRIMARY KEY (key);
ANALYZE Photoz_Complementary;

--********************************************************* New tables *********************************************************************
-- This table contains PhotozRF that are not embeded in PhotoObjAll_Galaxy
DROP TABLE IF EXISTS PhotozRF;
CREATE TABLE PhotozRF AS (
	SELECT *
	FROM aa_SDSS2003_5x_optimized.PhotozRF p
	WHERE NOT EXISTS (SELECT 'Found' FROM PhotoObjAll_Galaxy g WHERE g.key=p.key )
);
ALTER TABLE PhotozRF ADD PRIMARY KEY (key);
ANALYZE PhotozRF;

-- This table contains the attributes of those PhotozRF embeded in PhotoObjAll_Galaxy but not projected there
DROP TABLE IF EXISTS PhotozRF_Complementary;
CREATE TABLE PhotozRF_Complementary AS (
	SELECT p.key, value-ARRAY['z','zerr'] AS value
	FROM aa_SDSS2003_5x_optimized.PhotozRF p
	WHERE EXISTS (SELECT 'Found' FROM PhotoObjAll_Galaxy g WHERE g.key=p.key)
);
ALTER TABLE PhotozRF_Complementary ADD PRIMARY KEY (key);
ANALYZE PhotozRF_Complementary;

-- COMMENTED BECAUSE NO MIGRATION IS NECESSARY

-- DROP TABLE IF EXISTS Field;
-- CREATE TABLE Field AS (
-- 	SELECT * 
-- 	FROM aa_SDSS2003_5x_optimized.Field f
-- );
-- ALTER TABLE Field ADD PRIMARY KEY (key);
-- ANALYZE Field;

-- DROP TABLE IF EXISTS Frame;
-- CREATE TABLE Frame AS (
-- 	SELECT *  
-- 	FROM aa_SDSS2003_5x_optimized.Frame f
-- );
-- ALTER TABLE Frame ADD PRIMARY KEY (key1, key2);
-- ANALYZE Frame;

-- DROP TABLE IF EXISTS GalSpecIndx;
-- CREATE TABLE GalSpecIndx AS (
-- 	SELECT * 
-- 	FROM aa_SDSS2003_5x_optimized.GalSpecIndx g
-- );
-- ALTER TABLE GalSpecIndx ADD PRIMARY KEY (key);
-- ANALYZE GalSpecIndx;