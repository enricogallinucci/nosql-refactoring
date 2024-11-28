--*********************************************************** Tables *************************************************************************
-- This table contains primary objects
DROP TABLE IF EXISTS PhotoObjAll_Primary;
CREATE TABLE PhotoObjAll_Primary AS (
	SELECT KEY, jsonb_build_object('run', p.value->>'run', 'rerun', p.value->>'rerun', 'camcol', p.value->>'camcol', 'field', p.value->>'field', 'obj', p.value->>'obj', 'type', p.value->>'type', 'ra', p.value->>'ra', 'dec', p.value->>'dec', 'u', p.value->>'u', 'g', p.value->>'g', 'r', p.value->>'r', 'i', p.value->>'i', 'z', p.value->>'z', 'err_u', p.value->>'err_u', 'err_g', p.value->>'err_g', 'err_r', p.value->>'err_r', 'err_i', p.value->>'err_i', 'err_z', p.value->>'err_z',
																 'psfmagerr_u', p.value->>'psfmagerr_u', 'psfmagerr_g', p.value->>'psfmagerr_g', 'psfmagerr_r', p.value->>'psfmagerr_r', 'psfmagerr_i', p.value->>'psfmagerr_i', 'psfmagerr_z', p.value->>'psfmagerr_z' 
																) AS value 
	
	FROM aa_SDSS2003.PhotoObjAll p 
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
	FROM aa_SDSS2003.PhotoObjAll p 
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
	FROM aa_SDSS2003.PhotoObjAll as g 
		LEFT OUTER JOIN aa_SDSS2003.SpecObjAll s ON g.key=(s.value->>'bestobjid')::int8
		JOIN aa_SDSS2003.Photoz as p ON g.key=p.key
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
	FROM aa_SDSS2003.PhotoObjAll as g 
	WHERE (g.value->>'type')::int8=3 --class='GALAXY' (see https://skyserver.sdss.org/dr1/en/help/browser/browser.asp) 
		AND (g.value->>'mode')::int8<>1
		AND EXISTS (SELECT 'Found' FROM aa_SDSS2003.Photoz as p WHERE g.key=p.key)
);
ALTER TABLE PhotoObjAll_GalaxyComplementary ADD PRIMARY KEY (key);
ANALYZE PhotoObjAll_GalaxyComplementary;

-- This table contains those PhotoObject not in primary and not in galaxy
DROP TABLE IF EXISTS PhotoObjAll_Other;
CREATE TABLE PhotoObjAll_Other AS (
  SELECT *
  FROM aa_SDSS2003.PhotoObjAll p 
	WHERE (p.value->>'mode')::int8<>1
	  AND ((p.value->>'type')::int8<>3 --class<>'GALAXY' (see https://skyserver.sdss.org/dr1/en/help/browser/browser.asp)
	    OR ((p.value->>'type')::int8=3 --class='GALAXY' (see https://skyserver.sdss.org/dr1/en/help/browser/browser.asp) 
				AND NOT EXISTS (SELECT 'Found' FROM aa_SDSS2003.Photoz as pz WHERE pz.key=p.key)))
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
	FROM aa_SDSS2003.Photoz p
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
	FROM aa_SDSS2003.Photoz p
	WHERE EXISTS (SELECT 'Found' FROM PhotoObjAll_Galaxy g WHERE g.key=p.key)
);
ALTER TABLE Photoz_Complementary ADD PRIMARY KEY (key);
ANALYZE Photoz_Complementary;

-- This table contains SpecObjAll that are not embeded in PhotoObjAll_Galaxy
DROP TABLE IF EXISTS SpecObjAll;
CREATE TABLE SpecObjAll AS (
	SELECT *
	FROM aa_SDSS2003.SpecObjAll s
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
	FROM aa_SDSS2003.SpecObjAll s
	WHERE EXISTS (SELECT 'Found' FROM PhotoObjAll_Galaxy g WHERE g.key=(s.value->>'bestobjid')::int8)
);
ALTER TABLE SpecObjAll_Complementary ADD PRIMARY KEY (key);
ANALYZE SpecObjAll_Complementary;