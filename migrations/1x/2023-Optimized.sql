-- This table contains all galaxies
-- Galaxies that are NOT primary objects in 2013 optimized
DROP TABLE IF EXISTS PhotoObjAll_Galaxy;
CREATE TABLE PhotoObjAll_Galaxy AS (
	SELECT p.KEY, jsonb_build_object('clean', p.value->>'clean', 'mode', p.value->>'mode', 'dered_r', p.value->>'dered_r', 'run', p.value->>'run', 'rerun', p.value->>'rerun', 'camcol', p.value->>'camcol', 'field', p.value->>'field', 'obj', p.value->>'obj', 'type', p.value->>'type', 'ra', p.value->>'ra', 'dec', p.value->>'dec', 'u', p.value->>'u', 'g', p.value->>'g', 'r', p.value->>'r', 'i', p.value->>'i', 'z', p.value->>'z', 'err_u', p.value->>'err_u', 'err_g', p.value->>'err_g', 'err_r',p.value->>'err_r', 'err_i', p.value->>'err_i', 'err_z', p.value->>'err_z') AS value
	FROM (
		SELECT g.KEY, g.value||gc.value AS value		
		FROM aa_SDSS2013_optimized.PhotoObjAll_Galaxy as g 
		  JOIN aa_SDSS2013_optimized.PhotoObjAll_GalaxyComplementary gc ON g.key=gc.KEY
		UNION ALL
		-- Galaxies that are primary objects
		SELECT *
		FROM (
					SELECT pp.KEY, pp.value||pc.value AS value
					FROM aa_SDSS2013_optimized.PhotoObjAll_Primary pp  
						JOIN aa_SDSS2013_optimized.PhotoObjAll_PrimaryComplementary pc ON pp.KEY=pc.KEY --({objidlist})
					WHERE (pp.value->>'type')::int8=3 --AND (pc.value->>'type')::int8=3 --class='GALAXY' (see https://skyserver.sdss.org/dr1/en/help/browser/browser.asp)
					) _
		UNION ALL
		SELECT *
		FROM aa_SDSS2013_optimized.PhotoObjAll_Other
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
		FROM aa_SDSS2013_optimized.PhotoObjAll_Galaxy as g 
		  JOIN aa_SDSS2013_optimized.PhotoObjAll_GalaxyComplementary gc ON g.key=gc.KEY
		UNION ALL
		-- Galaxies that are primary objects
		SELECT *
		FROM (
					SELECT pp.KEY, pp.value||pc.value AS value
					FROM aa_SDSS2013_optimized.PhotoObjAll_Primary pp  
						JOIN aa_SDSS2013_optimized.PhotoObjAll_PrimaryComplementary pc ON pp.KEY=pc.KEY --({objidlist})
					WHERE (pp.value->>'type')::int8=3 --AND (pc.value->>'type')::int8=3 --class='GALAXY' (see https://skyserver.sdss.org/dr1/en/help/browser/browser.asp)
					) _
		UNION ALL
		SELECT *
		FROM aa_SDSS2013_optimized.PhotoObjAll_Other
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
			FROM aa_SDSS2013_optimized.PhotoObjAll_Primary pp  
				JOIN aa_SDSS2013_optimized.PhotoObjAll_PrimaryComplementary pc ON pp.KEY=pc.KEY --({objidlist})
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
			FROM aa_SDSS2013_optimized.PhotoObjAll_Primary pp  
				JOIN aa_SDSS2013_optimized.PhotoObjAll_PrimaryComplementary pc ON pp.KEY=pc.KEY --({objidlist})
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
	FROM aa_SDSS2013_optimized.PhotoObjAll_Other p
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
	FROM aa_SDSS2013_optimized.SpecObjAll s
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
	FROM aa_SDSS2013_optimized.SpecObjAll s
);
ALTER TABLE SpecObjAllComplementary ADD PRIMARY KEY (key);
ANALYZE SpecObjAllComplementary;

-- This table contains Photoz
DROP TABLE IF EXISTS Photoz;
CREATE TABLE Photoz AS (
	SELECT p.KEY, jsonb_build_object('z', p.value->>'z') AS value
	FROM aa_SDSS2013_optimized.Photoz p
);
ALTER TABLE Photoz ADD PRIMARY KEY (key);
ANALYZE Photoz;

-- This table contains All other attributes of Photoz
DROP TABLE IF EXISTS PhotozComplementary;
CREATE TABLE PhotozComplementary AS (
	SELECT p.KEY, p.value-ARRAY['z'] AS value
	FROM aa_SDSS2013_optimized.Photoz p
);
ALTER TABLE PhotozComplementary ADD PRIMARY KEY (key);
ANALYZE PhotozComplementary;

-- MISSING OLD PHOTOZ_COMPLEMENTARY

DROP TABLE IF EXISTS Frame_0;
CREATE TABLE Frame_0 AS (
SELECT fr.key1, fr.key2, fr.value||jsonb_build_object('Field', fi.value) AS value
FROM aa_SDSS2013_optimized.Frame fr 
  JOIN aa_SDSS2013_optimized.Field fi ON fi.key=fr.key1
WHERE fr.key2=0);
ALTER TABLE Frame_0 ADD PRIMARY KEY (key1, key2);
ANALYZE Frame_0;

DROP TABLE IF EXISTS Frame_Other;
CREATE TABLE Frame_Other AS (
	SELECT *  
	FROM aa_SDSS2013_optimized.Frame f
WHERE f.key2<>0
);
ALTER TABLE Frame_Other ADD PRIMARY KEY (key1, key2);
ANALYZE Frame_Other;

-- DROP TABLE IF EXISTS Platex;
-- CREATE TABLE Platex AS (
-- 	SELECT key, value 
-- 	FROM aa_SDSS2013_optimized.Platex p
-- );
-- ALTER TABLE Platex ADD PRIMARY KEY (key);
-- ANALYZE Platex;

DROP TABLE IF EXISTS Field_Other;
CREATE TABLE Field_Other AS (
	SELECT * 
	FROM aa_SDSS2013_optimized.Field fi
	WHERE NOT EXISTS (SELECT 'Found' FROM aa_SDSS2013_optimized.Frame fr WHERE fi.key=fr.key1)
);
ALTER TABLE Field_Other ADD PRIMARY KEY (key);
ANALYZE Field_Other;

-- DROP TABLE IF EXISTS GalSpecExtra;
-- CREATE TABLE GalSpecExtra AS (
-- 	SELECT * 
-- 	FROM aa_SDSS2013_optimized.GalSpecExtra g
-- );
-- ALTER TABLE GalSpecExtra ADD PRIMARY KEY (key);
-- ANALYZE GalSpecExtra;

-- DROP TABLE IF EXISTS GalSpecIndx;
-- CREATE TABLE GalSpecIndx AS (
-- 	SELECT * 
-- 	FROM aa_SDSS2013_optimized.GalSpecIndx g
-- );
-- ALTER TABLE GalSpecIndx ADD PRIMARY KEY (key);
-- ANALYZE GalSpecIndx;