/* REPLACE:
sdss_relational2 with sdss_relational_5x
aa_SDSS2003_5x with aa_SDSS2003_5x
aa_SDSS2013_5x with aa_SDSS2013_5x
aa_SDSS2023_5x with aa_SDSS2023_5x
(the three above include the optimized versions)
*/

--========================================================= 2003 Original ===============================================================================
DROP SCHEMA IF EXISTS aa_SDSS2003_5x CASCADE;
CREATE SCHEMA aa_SDSS2003_5x;
SET search_path TO aa_SDSS2003_5x, public;
SHOW search_path;

DROP TABLE IF EXISTS PhotoObjAll;
CREATE TABLE PhotoObjAll AS (
	SELECT	p.objid as key,
    			(to_jsonb(p.*) - 'objid') AS value 
  FROM sdss_relational_5x.PhotoObjAll AS p);
ALTER TABLE PhotoObjAll ADD PRIMARY KEY (key);

DROP INDEX IF EXISTS idx_PhotoObjAll_ra_dec;
CREATE INDEX idx_PhotoObjAll_ra_dec ON PhotoObjAll(
  CAST(value->>'ra' AS FLOAT),
  CAST(value->>'dec' AS FLOAT)
);
ANALYZE PhotoObjAll;

-- Photoz should have a FK to PhotoObjAll correspondin to a 0..1-1 relationship
DROP TABLE IF EXISTS Photoz;
CREATE TABLE Photoz AS (
	SELECT p.objid as key,
    		(to_jsonb(p.*) - 'objid') AS value
	FROM sdss_relational_5x.photoz p);
ALTER TABLE Photoz ADD PRIMARY KEY (key);

DROP INDEX IF EXISTS idx_Photoz_z;
CREATE INDEX idx_Photoz_z ON Photoz(
  CAST(value->>'z' AS float)
);
ANALYZE Photoz;

-- SpecObjAll should have a FK to PhotoObjAll correspondin to a *-1 relationship
DROP TABLE IF EXISTS SpecObjAll;
CREATE TABLE SpecObjAll AS (
	SELECT s.specObjID as key,
    		(to_jsonb(s.*) - 'specObjID') AS value
	FROM sdss_relational_5x.SpecObjAll AS s);
ALTER TABLE SpecObjAll ADD PRIMARY KEY (key);

DROP INDEX IF EXISTS SpecObjAll_bestobjid;
CREATE INDEX SpecObjAll_bestobjid ON SpecObjAll(
	CAST(value->>'bestobjid' AS int8));
DROP INDEX IF EXISTS idx_SpecObjAll_ra_dec;
CREATE INDEX idx_SpecObjAll_ra_dec ON SpecObjAll(
  CAST(value->>'ra' AS FLOAT),
  CAST(value->>'dec' AS FLOAT)
);
ANALYZE SpecObjAll;

--========================================================= 2003 Optimized ===============================================================================
DROP SCHEMA IF EXISTS aa_SDSS2003_5x_optimized CASCADE;
CREATE SCHEMA aa_SDSS2003_5x_optimized;
SET search_path TO aa_SDSS2003_5x_optimized, public;
SHOW search_path;

--*********************************************************** Tables *************************************************************************
-- This table contains primary objects
DROP TABLE IF EXISTS PhotoObjAll_Primary;
CREATE TABLE PhotoObjAll_Primary AS (
	SELECT KEY, jsonb_build_object('run', p.value->>'run', 'rerun', p.value->>'rerun', 'camcol', p.value->>'camcol', 'field', p.value->>'field', 'obj', p.value->>'obj', 'type', p.value->>'type', 'ra', p.value->>'ra', 'dec', p.value->>'dec', 'u', p.value->>'u', 'g', p.value->>'g', 'r', p.value->>'r', 'i', p.value->>'i', 'z', p.value->>'z', 'err_u', p.value->>'err_u', 'err_g', p.value->>'err_g', 'err_r', p.value->>'err_r', 'err_i', p.value->>'err_i', 'err_z', p.value->>'err_z',
																 'psfmagerr_u', p.value->>'psfmagerr_u', 'psfmagerr_g', p.value->>'psfmagerr_g', 'psfmagerr_r', p.value->>'psfmagerr_r', 'psfmagerr_i', p.value->>'psfmagerr_i', 'psfmagerr_z', p.value->>'psfmagerr_z' 
																) AS value 
	
	FROM aa_SDSS2003_5x.PhotoObjAll p 
	WHERE (p.value->>'mode')::int8=1
);
ALTER TABLE PhotoObjAll_Primary ADD PRIMARY KEY (key);

DROP INDEX IF EXISTS idx_PhotoObjAll_Primary_ra_dec;
CREATE INDEX idx_PhotoObjAll_Primary_ra_dec ON PhotoObjAll_Primary(
  CAST(value->>'ra' AS FLOAT),
  CAST(value->>'dec' AS FLOAT)
);
ANALYZE PhotoObjAll_Primary;

-- This table contains primary objects with unused attributes
DROP TABLE IF EXISTS PhotoObjAll_PrimaryComplementary;
CREATE TABLE PhotoObjAll_PrimaryComplementary AS (
	SELECT key, p.value-ARRAY['run','rerun','camcol','field','obj','ra','dec','u','g','r','i','z','err_u','err_g','err_r','err_i','err_z', 'psfmagerr_u', 'psfmagerr_g', 'psfmagerr_r', 'psfmagerr_i', 'psfmagerr_z'] AS value --'type' attribute is in both
	FROM aa_SDSS2003_5x.PhotoObjAll p 
	WHERE (p.value->>'mode')::int8=1
);
ALTER TABLE PhotoObjAll_PrimaryComplementary ADD PRIMARY KEY (key);
ANALYZE PhotoObjAll_PrimaryComplementary;

-- This table contains galaxies that are not primary objects
DROP TABLE IF EXISTS PhotoObjAll_Galaxy;
CREATE TABLE PhotoObjAll_Galaxy AS (
	SELECT g.key, jsonb_build_object('ra', g.value->>'ra', 'dec', g.value->>'dec', 'u', g.value->>'u', 'g', g.value->>'g', 'r', g.value->>'r', 'i', g.value->>'i', 'z', g.value->>'z', 'psfmagerr_u', g.value->>'psfmagerr_u', 'psfmagerr_g', g.value->>'psfmagerr_g', 'psfmagerr_r', g.value->>'psfmagerr_r', 'psfmagerr_i', g.value->>'psfmagerr_i', 'psfmagerr_z', g.value->>'psfmagerr_z', 
					'Photoz', jsonb_build_object('pid', p.value->>'pid', 'version', p.value->>'version', 'z', p.value->>'z', 'zerr', p.value->>'zerr', 't', p.value->>'t', 'terr', p.value->>'terr', 'quality', p.value->>'quality'), 
					'SpecObj', jsonb_build_object('specobjid', s.value->>'specobjid', 'ra', s.value->>'ra', 'dec', s.value->>'dec', 'z', s.value->>'z')) AS value
	FROM aa_SDSS2003_5x.PhotoObjAll as g 
		LEFT OUTER JOIN aa_SDSS2003_5x.SpecObjAll s ON g.key=(s.value->>'bestobjid')::int8
		JOIN aa_SDSS2003_5x.Photoz as p ON g.key=p.key
	WHERE (g.value->>'type')::int8=3 --class='GALAXY' (see https://skyserver.sdss.org/dr1/en/help/browser/browser.asp)
	  AND (g.value->>'mode')::int8<>1
);
ALTER TABLE PhotoObjAll_Galaxy ADD PRIMARY KEY (key);

DROP INDEX IF EXISTS idx_PhotoObjAll_Galaxy_ra_dec;
CREATE INDEX idx_PhotoObjAll_Galaxy_ra_dec ON PhotoObjAll_Galaxy(
  CAST(value->>'ra' AS FLOAT),
  CAST(value->>'dec' AS FLOAT)
);
ANALYZE PhotoObjAll_Galaxy;

-- This table contains the missing attributes of galaxies
DROP TABLE IF EXISTS PhotoObjAll_GalaxyComplementary;
CREATE TABLE PhotoObjAll_GalaxyComplementary AS (
	SELECT g.key, g.value-ARRAY['ra','dec','u','g','r','i','z','psfmagerr_u','psfmagerr_g','psfmagerr_r','psfmagerr_i','psfmagerr_z'] AS value
	FROM aa_SDSS2003_5x.PhotoObjAll as g 
	WHERE (g.value->>'type')::int8=3 --class='GALAXY' (see https://skyserver.sdss.org/dr1/en/help/browser/browser.asp) 
		AND (g.value->>'mode')::int8<>1
		AND EXISTS (SELECT 'Found' FROM aa_SDSS2003_5x.Photoz as p WHERE g.key=p.key)
);
ALTER TABLE PhotoObjAll_GalaxyComplementary ADD PRIMARY KEY (key);
ANALYZE PhotoObjAll_GalaxyComplementary;

-- This table contains those PhotoObject not in primary and not in galaxy
DROP TABLE IF EXISTS PhotoObjAll_Other;
CREATE TABLE PhotoObjAll_Other AS (
  SELECT *
  FROM aa_SDSS2003_5x.PhotoObjAll p 
	WHERE (p.value->>'mode')::int8<>1
	  AND ((p.value->>'type')::int8<>3 --class<>'GALAXY' (see https://skyserver.sdss.org/dr1/en/help/browser/browser.asp)
	    OR ((p.value->>'type')::int8=3 --class='GALAXY' (see https://skyserver.sdss.org/dr1/en/help/browser/browser.asp) 
				AND NOT EXISTS (SELECT 'Found' FROM aa_SDSS2003_5x.Photoz as pz WHERE pz.key=p.key)))
);
ALTER TABLE PhotoObjAll_Other ADD PRIMARY KEY (key);

DROP INDEX IF EXISTS idx_PhotoObjAll_Other_ra_dec;
CREATE INDEX idx_PhotoObjAll_Other_ra_dec ON PhotoObjAll_Other(
  CAST(value->>'ra' AS FLOAT),
  CAST(value->>'dec' AS FLOAT)
);
ANALYZE PhotoObjAll_Other;

-- This table contains Photoz that are not embeded in PhotoObjAll_Galaxy
DROP TABLE IF EXISTS Photoz;
CREATE TABLE Photoz AS (
	SELECT *
	FROM aa_SDSS2003_5x.Photoz p
	WHERE NOT EXISTS (SELECT 'Found' FROM PhotoObjAll_Galaxy g WHERE g.key=p.key )
);
ALTER TABLE Photoz ADD PRIMARY KEY (key);

DROP INDEX IF EXISTS idx_Photoz_z;
CREATE INDEX idx_Photoz_z ON Photoz(
  CAST(value->>'z' AS float)
);
ANALYZE Photoz;

-- This table contains the attributes of those Photoz embeded in PhotoObjAll_Galaxy but not projected there
DROP TABLE IF EXISTS Photoz_Complementary;
CREATE TABLE Photoz_Complementary AS (
	SELECT p.key, value-ARRAY['pid','version','z','zerr','t','terr','quality'] AS value
	FROM aa_SDSS2003_5x.Photoz p
	WHERE EXISTS (SELECT 'Found' FROM PhotoObjAll_Galaxy g WHERE g.key=p.key)
);
ALTER TABLE Photoz_Complementary ADD PRIMARY KEY (key);
ANALYZE Photoz_Complementary;

-- This table contains SpecObjAll that are not embeded in PhotoObjAll_Galaxy
DROP TABLE IF EXISTS SpecObjAll;
CREATE TABLE SpecObjAll AS (
	SELECT *
	FROM aa_SDSS2003_5x.SpecObjAll s
	WHERE NOT EXISTS (SELECT 'Found' FROM PhotoObjAll_Galaxy g WHERE g.key=(s.value->>'bestobjid')::int8)
);
ALTER TABLE SpecObjAll ADD PRIMARY KEY (key);

DROP INDEX IF EXISTS SpecObjAll_bestobjid;
CREATE INDEX SpecObjAll_bestobjid ON SpecObjAll(
	CAST(value->>'bestobjid' AS int8));
DROP INDEX IF EXISTS idx_SpecObjAll_ra_dec;
CREATE INDEX idx_SpecObjAll_ra_dec ON SpecObjAll(
  CAST(value->'ra' AS FLOAT),
  CAST(value->'dec' AS FLOAT)
);
ANALYZE SpecObjAll;

-- This table contains the attributes of those SpecObjAll embeded in PhotoObjAll_Galaxy but not projected there
DROP TABLE IF EXISTS SpecObjAll_Complementary;
CREATE TABLE SpecObjAll_Complementary AS (
	SELECT s.key, s.value-ARRAY['specobjid','ra','dec','z'] AS value
	FROM aa_SDSS2003_5x.SpecObjAll s
	WHERE EXISTS (SELECT 'Found' FROM PhotoObjAll_Galaxy g WHERE g.key=(s.value->>'bestobjid')::int8)
);
ALTER TABLE SpecObjAll_Complementary ADD PRIMARY KEY (key);
ANALYZE SpecObjAll_Complementary;

--========================================================= 2013 over 2003 Optimized ===============================================================================
SET search_path TO aa_SDSS2003_5x_optimized, public;
SHOW search_path;

--********************************************************* New tables *********************************************************************
DROP TABLE IF EXISTS PhotozRF;
CREATE TABLE PhotozRF AS (
	SELECT p.objid as key,
    			(to_jsonb(p.*) - 'objid') AS value 
	FROM sdss_relational_5x.PhotozRF p
);
ALTER TABLE PhotozRF ADD PRIMARY KEY (key);
ANALYZE PhotozRF;

DROP TABLE IF EXISTS Field;
CREATE TABLE Field AS (
	SELECT f.fieldid as key,
    			(to_jsonb(f.*) - 'fieldid') AS value 
	FROM sdss_relational_5x.Field f
);
ALTER TABLE Field ADD PRIMARY KEY (key);
ANALYZE Field;

DROP TABLE IF EXISTS Frame;
CREATE TABLE Frame AS (
	SELECT f.fieldid as key1, f.zoom AS key2,
    			(to_jsonb(f.*) - ARRAY['fieldid', 'zoom']) AS value  
	FROM sdss_relational_5x.Frame f
);
ALTER TABLE Frame ADD PRIMARY KEY (key1, key2);
ANALYZE Frame;

DROP TABLE IF EXISTS GalSpecIndx;
CREATE TABLE GalSpecIndx AS (
	SELECT g.specObjID as key,
    		(to_jsonb(g.*) - 'specObjID') AS value 
	FROM sdss_relational_5x.GalSpecIndx g
);
ALTER TABLE GalSpecIndx ADD PRIMARY KEY (key);
ANALYZE GalSpecIndx;

--========================================================= 2023 over 2003 Optimized ===============================================================================
SET search_path TO aa_SDSS2003_5x_optimized, public;
SHOW search_path;

--********************************************************* New tables *********************************************************************
DROP TABLE IF EXISTS Platex;
CREATE TABLE Platex AS (
	SELECT p.plateid as key,
    			(to_jsonb(p.*) - 'plateid') AS value 
	FROM sdss_relational_5x.Platex p
);
ALTER TABLE Platex ADD PRIMARY KEY (key);
ANALYZE Platex;

DROP TABLE IF EXISTS GalSpecExtra;
CREATE TABLE GalSpecExtra AS (
	SELECT g.specobjid as key,
    			(to_jsonb(g.*) - 'specobjid') AS value 
	FROM sdss_relational_5x.GalSpecExtra g
);
ALTER TABLE GalSpecExtra ADD PRIMARY KEY (key);
ANALYZE GalSpecExtra;

DROP TABLE IF EXISTS GalSpecIndx;
CREATE TABLE GalSpecIndx AS (
	SELECT g.specobjid as key,
    			(to_jsonb(g.*) - 'specobjid') AS value 
	FROM sdss_relational_5x.GalSpecIndx g
);
ALTER TABLE GalSpecIndx ADD PRIMARY KEY (key);
ANALYZE GalSpecIndx;

DROP INDEX IF EXISTS idx_Photoz_z;
CREATE INDEX idx_Photoz_z ON Photoz(
  CAST(value->>'z' AS FLOAT)
);
ANALYZE Photoz;

DROP INDEX IF EXISTS idx_PhotoObjAll_PrimaryComplementary_deredr;
CREATE INDEX idx_PhotoObjAll_PrimaryComplementary_deredr ON PhotoObjAll_PrimaryComplementary(
  CAST(value->>'dered_r' AS FLOAT)
);
ANALYZE PhotoObjAll_PrimaryComplementary;

--========================================================= 2013 Optimized ===============================================================================
DROP SCHEMA IF EXISTS aa_SDSS2013_5x_optimized CASCADE;
CREATE SCHEMA aa_SDSS2013_5x_optimized;
SET search_path TO aa_SDSS2013_5x_optimized, public;
SHOW search_path;

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

DROP TABLE IF EXISTS Field;
CREATE TABLE Field AS (
	SELECT * 
	FROM aa_SDSS2003_5x_optimized.Field f
);
ALTER TABLE Field ADD PRIMARY KEY (key);
ANALYZE Field;

DROP TABLE IF EXISTS Frame;
CREATE TABLE Frame AS (
	SELECT *  
	FROM aa_SDSS2003_5x_optimized.Frame f
);
ALTER TABLE Frame ADD PRIMARY KEY (key1, key2);
ANALYZE Frame;

DROP TABLE IF EXISTS GalSpecIndx;
CREATE TABLE GalSpecIndx AS (
	SELECT * 
	FROM aa_SDSS2003_5x_optimized.GalSpecIndx g
);
ALTER TABLE GalSpecIndx ADD PRIMARY KEY (key);
ANALYZE GalSpecIndx;

--========================================================= 2023 over 2013 Optimized ===============================================================================
SET search_path TO aa_SDSS2013_5x_optimized, public;
SHOW search_path;

--********************************************************* New tables *********************************************************************
DROP TABLE IF EXISTS Platex;
CREATE TABLE Platex AS (
	SELECT p.plateid as key, -- This IS weird, because it IS float, NOT integer
    			(to_jsonb(p.*) - 'plateid') AS value 
	FROM sdss_relational_5x.Platex p
);
ALTER TABLE Platex ADD PRIMARY KEY (key);
ANALYZE Platex;

DROP TABLE IF EXISTS GalSpecExtra;
CREATE TABLE GalSpecExtra AS (
	SELECT g.specobjid as key,
    			(to_jsonb(g.*) - 'specobjid') AS value 
	FROM sdss_relational_5x.GalSpecExtra g
);
ALTER TABLE GalSpecExtra ADD PRIMARY KEY (key);
ANALYZE GalSpecExtra;

DROP TABLE IF EXISTS GalSpecIndx;
CREATE TABLE GalSpecIndx AS (
	SELECT g.specobjid as key,
    			(to_jsonb(g.*) - 'specobjid') AS value 
	FROM sdss_relational_5x.GalSpecIndx g
);
ALTER TABLE GalSpecIndx ADD PRIMARY KEY (key);
ANALYZE GalSpecIndx;

DROP INDEX IF EXISTS idx_Photoz_z;
CREATE INDEX idx_Photoz_z ON Photoz(
  CAST(value->>'z' AS FLOAT)
);
ANALYZE Photoz;

DROP INDEX IF EXISTS idx_PhotoObjAll_GalaxyComplementary_deredr;
CREATE INDEX idx_PhotoObjAll_GalaxyComplementary_deredr ON PhotoObjAll_GalaxyComplementary(
  CAST(value->>'dered_r' AS FLOAT8)
);
ANALYZE PhotoObjAll_GalaxyComplementary;

DROP INDEX IF EXISTS idx_PhotoObjAll_PrimaryComplementary_deredr;
CREATE INDEX idx_PhotoObjAll_PrimaryComplementary_deredr ON PhotoObjAll_PrimaryComplementary(
  CAST(value->>'dered_r' AS FLOAT8)
);
ANALYZE PhotoObjAll_PrimaryComplementary;

DROP INDEX IF EXISTS idx_PhotoObjAll_Galaxy_ra_dec;
CREATE INDEX idx_PhotoObjAll_Galaxy_ra_dec ON SpecObjAll(
  CAST(value->>'ra' AS FLOAT8),
  CAST(value->>'dec' AS FLOAT8)
);
ANALYZE PhotoObjAll_Galaxy;

DROP INDEX IF EXISTS idx_PhotoObjAll_Primary_ra_dec;
CREATE INDEX idx_PhotoObjAll_Primary_ra_dec ON SpecObjAll(
  CAST(value->>'ra' AS FLOAT8),
  CAST(value->>'dec' AS FLOAT8)
);
ANALYZE PhotoObjAll_Primary;

DROP INDEX IF EXISTS idx_SpecObjAll_bestobjid;
CREATE INDEX idx_SpecObjAll_bestobjid ON SpecObjAll(
  CAST(value->>'bestobjid' AS int8)
);

DROP INDEX IF EXISTS idx_SpecObjAll_plate;
CREATE INDEX idx_SpecObjAll_plate ON SpecObjAll(
  CAST(value->>'plateid' AS float8)
);

ANALYZE SpecObjAll;

--========================================================= 2023 Optimized ===============================================================================
DROP SCHEMA IF EXISTS aa_SDSS2023_5x_optimized CASCADE;
CREATE SCHEMA aa_SDSS2023_5x_optimized;
SET search_path TO aa_SDSS2023_5x_optimized, public;
SHOW search_path;

-- This table contains all galaxies
-- Galaxies that are NOT primary objects in 2013 optimized
DROP TABLE IF EXISTS PhotoObjAll_Galaxy;
CREATE TABLE PhotoObjAll_Galaxy AS (
	SELECT p.KEY, jsonb_build_object('clean', p.value->>'clean', 'mode', p.value->>'mode', 'dered_r', p.value->>'dered_r', 'run', p.value->>'run', 'rerun', p.value->>'rerun', 'camcol', p.value->>'camcol', 'field', p.value->>'field', 'obj', p.value->>'obj', 'type', p.value->>'type', 'ra', p.value->>'ra', 'dec', p.value->>'dec', 'u', p.value->>'u', 'g', p.value->>'g', 'r', p.value->>'r', 'i', p.value->>'i', 'z', p.value->>'z', 'err_u', p.value->>'err_u', 'err_g', p.value->>'err_g', 'err_r',p.value->>'err_r', 'err_i', p.value->>'err_i', 'err_z', p.value->>'err_z') AS value
	FROM (
		SELECT g.KEY, g.value||gc.value AS value		
		FROM aa_SDSS2013_5x_optimized.PhotoObjAll_Galaxy as g 
		  JOIN aa_SDSS2013_5x_optimized.PhotoObjAll_GalaxyComplementary gc ON g.key=gc.KEY
		UNION ALL
		-- Galaxies that are primary objects
		SELECT *
		FROM (
					SELECT pp.KEY, pp.value||pc.value AS value
					FROM aa_SDSS2013_5x_optimized.PhotoObjAll_Primary pp  
						JOIN aa_SDSS2013_5x_optimized.PhotoObjAll_PrimaryComplementary pc ON pp.KEY=pc.KEY --({objidlist})
					WHERE (pp.value->>'type')::int8=3 --AND (pc.value->>'type')::int8=3 --class='GALAXY' (see https://skyserver.sdss.org/dr1/en/help/browser/browser.asp)
					) _
		UNION ALL
		SELECT *
		FROM aa_SDSS2013_5x_optimized.PhotoObjAll_Other
		WHERE (value->>'type')::int8=3 --AND (pc.value->>'type')::int8=3 --class='GALAXY' (see https://skyserver.sdss.org/dr1/en/help/browser/browser.asp)
		) p
);
ALTER TABLE PhotoObjAll_Galaxy ADD PRIMARY KEY (key);
ANALYZE PhotoObjAll_Galaxy;

-- This table contains all unused attributes of galaxies
-- Galaxies that are NOT primary objects in 2013 optimized
DROP TABLE IF EXISTS PhotoObjAll_GalaxyComplementary;
CREATE TABLE PhotoObjAll_GalaxyComplementary AS (
	SELECT g.KEY, g.value-ARRAY['clean', 'mode', 'dered_r', 'run', 'rerun', 'camcol', 'field', 'obj', 'type', 'ra', 'dec', 'u', 'g', 'r', 'i', 'z', 'err_u', 'err_g', 'err_r', 'err_i', 'err_z'] AS value
	FROM (
		SELECT g.KEY, g.value||gc.value AS value		
		FROM aa_SDSS2013_5x_optimized.PhotoObjAll_Galaxy as g 
		  JOIN aa_SDSS2013_5x_optimized.PhotoObjAll_GalaxyComplementary gc ON g.key=gc.KEY
		UNION ALL
		-- Galaxies that are primary objects
		SELECT *
		FROM (
					SELECT pp.KEY, pp.value||pc.value AS value
					FROM aa_SDSS2013_5x_optimized.PhotoObjAll_Primary pp  
						JOIN aa_SDSS2013_5x_optimized.PhotoObjAll_PrimaryComplementary pc ON pp.KEY=pc.KEY --({objidlist})
					WHERE (pp.value->>'type')::int8=3 --AND (pc.value->>'type')::int8=3 --class='GALAXY' (see https://skyserver.sdss.org/dr1/en/help/browser/browser.asp)
					) _
		UNION ALL
		SELECT *
		FROM aa_SDSS2013_5x_optimized.PhotoObjAll_Other
		WHERE (value->>'type')::int8=3 --AND (pc.value->>'type')::int8=3 --class='GALAXY' (see https://skyserver.sdss.org/dr1/en/help/browser/browser.asp)
		) g
);
ALTER TABLE PhotoObjAll_GalaxyComplementary ADD PRIMARY KEY (key);
ANALYZE PhotoObjAll_GalaxyComplementary;

-- This table contains all primary photoobjects, except galaxies in PhotoObjAll_Galaxy
DROP TABLE IF EXISTS PhotoObjAll_Primary;
CREATE TABLE PhotoObjAll_Primary AS (
		SELECT p.KEY, jsonb_build_object('clean', p.value->>'clean', 'run', p.value->>'run', 'rerun', p.value->>'rerun', 'camcol', p.value->>'camcol', 'field', p.value->>'field', 'obj', p.value->>'obj', 'type', p.value->>'type', 'ra', p.value->>'ra', 'dec', p.value->>'dec', 'u', p.value->>'u', 'g', p.value->>'g', 'r', p.value->>'r', 'i', p.value->>'i', 'z', p.value->>'z', 'err_u', p.value->>'err_u', 'err_g', p.value->>'err_g', 'err_r',p.value->>'err_r', 'err_i', p.value->>'err_i', 'err_z', p.value->>'err_z') AS value
		FROM (
			SELECT pp.KEY, pp.value||pc.value AS value
			FROM aa_SDSS2013_5x_optimized.PhotoObjAll_Primary pp  
				JOIN aa_SDSS2013_5x_optimized.PhotoObjAll_PrimaryComplementary pc ON pp.KEY=pc.KEY --({objidlist})
			WHERE (pp.value->>'type')::int8<>3 --class='GALAXY' (see https://skyserver.sdss.org/dr1/en/help/browser/browser.asp)
		) p 
);
ALTER TABLE PhotoObjAll_Primary ADD PRIMARY KEY (key);
ANALYZE PhotoObjAll_Primary;


-- This table contains all primary photoobjects, except galaxies in PhotoObjAll_Galaxy
DROP TABLE IF EXISTS PhotoObjAll_PrimaryComplementary;
CREATE TABLE PhotoObjAll_PrimaryComplementary AS (
		SELECT p.KEY, p.value-ARRAY['clean, ''run', 'rerun', 'camcol', 'field', 'obj', 'type', 'ra', 'dec', 'u', 'g', 'r', 'i', 'z', 'err_u', 'err_g', 'err_r', 'err_i', 'err_z'] AS value
		FROM (
			SELECT pp.KEY, pp.value||pc.value AS value
			FROM aa_SDSS2013_5x_optimized.PhotoObjAll_Primary pp  
				JOIN aa_SDSS2013_5x_optimized.PhotoObjAll_PrimaryComplementary pc ON pp.KEY=pc.KEY --({objidlist})
			WHERE (pp.value->>'type')::int8<>3 --class='GALAXY' (see https://skyserver.sdss.org/dr1/en/help/browser/browser.asp)
		) p 
);
ALTER TABLE PhotoObjAll_PrimaryComplementary ADD PRIMARY KEY (key);
ANALYZE PhotoObjAll_PrimaryComplementary;

-- This table contains all photoobjects, except galaxies and primary
DROP TABLE IF EXISTS PhotoObjAll_Other;
CREATE TABLE PhotoObjAll_Other AS (
-- This takes all PhotoObjAll_Other in 2013 optimized
	SELECT p.key, p.value 
	FROM aa_SDSS2013_5x_optimized.PhotoObjAll_Other p
	WHERE (p.value->>'type')::int8<>3
);
ALTER TABLE PhotoObjAll_Other ADD PRIMARY KEY (key);

DROP INDEX IF EXISTS idx_PhotoObjAll_Other_ra_dec;
CREATE INDEX idx_PhotoObjAll_Other_ra_dec ON PhotoObjAll_Other(
  CAST(value->>'ra' AS FLOAT8),
  CAST(value->>'dec' AS FLOAT8)
);

ANALYZE PhotoObjAll_Other;

-- This table contains SpecObjAll
DROP TABLE IF EXISTS SpecObjAll;
CREATE TABLE SpecObjAll AS (
	SELECT s.KEY, jsonb_build_object('scienceprimary', s.value->>'scienceprimary', 'plateid', s.value->>'plateid', 'plate', s.value->>'plate', 'mjd', s.value->>'mjd', 'fiberid', s.value->>'fiberid', 'run2d', s.value->>'run2d', 'ra', s.value->>'ra', 'dec', s.value->>'dec', 'z', s.value->>'z', 'bestobjid', s.value->>'bestobjid') AS value
	FROM aa_SDSS2013_5x_optimized.SpecObjAll s
);
ALTER TABLE SpecObjAll ADD PRIMARY KEY (key);

DROP INDEX IF EXISTS idx_SpecObjAll_ra_dec;
CREATE INDEX idx_SpecObjAll_ra_dec ON SpecObjAll(
  CAST(value->>'ra' AS FLOAT8),
  CAST(value->>'dec' AS FLOAT8)
);
DROP INDEX IF EXISTS idx_SpecObjAll_bestobjid;
CREATE INDEX idx_SpecObjAll_bestobjid ON SpecObjAll(
  CAST(value->>'bestobjid' AS int8)
);
DROP INDEX IF EXISTS idx_SpecObjAll_plateid;
CREATE INDEX idx_SpecObjAll_plateid ON SpecObjAll(
  CAST(value->>'plateid' AS float8)
);
ANALYZE SpecObjAll;

-- This table contains all other attributes of SpecObjAll
DROP TABLE IF EXISTS SpecObjAllComplementary;
CREATE TABLE SpecObjAllComplementary AS (
	SELECT s.KEY, s.value-ARRAY['scienceprimary', 'plateid', 'plate', 'mjd', 'fiberid', 'run2d', 'ra', 'dec', 'z'] AS value
	FROM aa_SDSS2013_5x_optimized.SpecObjAll s
);
ALTER TABLE SpecObjAllComplementary ADD PRIMARY KEY (key);
ANALYZE SpecObjAllComplementary;

-- This table contains Photoz
DROP TABLE IF EXISTS Photoz;
CREATE TABLE Photoz AS (
	SELECT p.KEY, jsonb_build_object('z', p.value->>'z') AS value
	FROM aa_SDSS2013_5x_optimized.Photoz p
);
ALTER TABLE Photoz ADD PRIMARY KEY (key);
ANALYZE Photoz;

-- This table contains All other attributes of Photoz
DROP TABLE IF EXISTS PhotozComplementary;
CREATE TABLE PhotozComplementary AS (
	SELECT p.KEY, p.value-ARRAY['z'] AS value
	FROM aa_SDSS2013_5x_optimized.Photoz p
);
ALTER TABLE PhotozComplementary ADD PRIMARY KEY (key);
ANALYZE PhotozComplementary;

DROP TABLE IF EXISTS Frame_0;
CREATE TABLE Frame_0 AS (
SELECT fr.key1, fr.key2, fr.value||jsonb_build_object('Field', fi.value) AS value
FROM aa_SDSS2013_5x_optimized.Frame fr 
  JOIN aa_SDSS2013_5x_optimized.Field fi ON fi.key=fr.key1
WHERE fr.key2=0);
ALTER TABLE Frame_0 ADD PRIMARY KEY (key1, key2);
ANALYZE Frame_0;

DROP TABLE IF EXISTS Frame_Other;
CREATE TABLE Frame_Other AS (
	SELECT *  
	FROM aa_SDSS2013_5x_optimized.Frame f
WHERE f.key2<>0
);
ALTER TABLE Frame_Other ADD PRIMARY KEY (key1, key2);
ANALYZE Frame_Other;

DROP TABLE IF EXISTS Platex;
CREATE TABLE Platex AS (
	SELECT key, value 
	FROM aa_SDSS2013_5x_optimized.Platex p
);
ALTER TABLE Platex ADD PRIMARY KEY (key);
ANALYZE Platex;

DROP TABLE IF EXISTS Field_Other;
CREATE TABLE Field_Other AS (
	SELECT * 
	FROM aa_SDSS2013_5x_optimized.Field fi
	WHERE NOT EXISTS (SELECT 'Found' FROM aa_SDSS2013_5x_optimized.Frame fr WHERE fi.key=fr.key1)
);
ALTER TABLE Field_Other ADD PRIMARY KEY (key);
ANALYZE Field_Other;

DROP TABLE IF EXISTS GalSpecExtra;
CREATE TABLE GalSpecExtra AS (
	SELECT * 
	FROM aa_SDSS2013_5x_optimized.GalSpecExtra g
);
ALTER TABLE GalSpecExtra ADD PRIMARY KEY (key);
ANALYZE GalSpecExtra;

DROP TABLE IF EXISTS GalSpecIndx;
CREATE TABLE GalSpecIndx AS (
	SELECT * 
	FROM aa_SDSS2013_5x_optimized.GalSpecIndx g
);
ALTER TABLE GalSpecIndx ADD PRIMARY KEY (key);
ANALYZE GalSpecIndx;