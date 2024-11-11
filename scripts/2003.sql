--========================================================= 2023 Original ===============================================================================
DROP SCHEMA IF EXISTS SDSS2003 CASCADE;
CREATE SCHEMA SDSS2003;
SHOW search_path;
SET search_path TO SDSS2003, public;

DROP TABLE IF EXISTS PhotoObjAll;
CREATE TABLE PhotoObjAll (
	key char(19) PRIMARY KEY, 
	value jsonb NOT NULL);
	
-- Photoz should have a FK to PhotoObjAll correspondin to a 0..1-1 relationship
DROP TABLE IF EXISTS Photoz;
CREATE TABLE Photoz (
	key char(19) PRIMARY KEY, 
	value jsonb NOT NULL);

-- SpecObjAll should have a FK to PhotoObjAll correspondin to a *-1 relationship
DROP TABLE IF EXISTS SpecObjAll;
CREATE TABLE SpecObjAll (
	key char(18) PRIMARY KEY, 
	value jsonb NOT NULL);

-- (60.30%) select p.objid, p.run, p.rerun, p.camcol, p.field, p.obj, p.type, p.ra, p.dec, p.u,p.g,p.r,p.i,p.z, p.err_u, p.err_g, p.err_r,p.err_i,p.err_z from db_2003.photoprimary p where p.objid in ({objidlist}) limit 1
EXPLAIN (ANALYZE TRUE, COSTS FALSE, SUMMARY true)
SELECT p.key, p.value->>'run', p.value->>'rerun', p.value->>'camcol', p.value->>'field', p.value->>'obj', p.value->>'type', p.value->>'ra', p.value->>'dec', p.value->>'u', p.value->>'g', p.value->>'r', p.value->>'i', p.value->>'z', p.value->>'err_u', p.value->>'err_g', p.value->>'err_r', p.value->>'err_i', p.value->>'err_z' 
FROM PhotoObjAll p 
WHERE (p.value->>'mode')::int=1 AND p.key IN ('1237645879551066262') --({objidlist})
LIMIT 1;

-- (22.46%) select p.run,p.type,p.ra,p.dec,p.g,p.r,p.err_g,p.err_r from db_2003.photoprimary p where p.objid in ({objidlist})
EXPLAIN (ANALYZE TRUE, COSTS FALSE, SUMMARY true)
SELECT p.value->>'run', p.value->>'type', p.value->>'ra', p.value->>'dec', p.value->>'g', p.value->>'r', p.value->>'err_g', p.value->>'err_r' 
FROM PhotoObjAll p 
WHERE (p.value->>'mode')::int=1 AND p.key IN ('1237645879551066262'); --({objidlist})

-- (04.75%) select g.objid,g.ra,g.dec, g.u,g.g,g.r,g.i,g.z, g.psfmagerr_u as u_err, g.psfmagerr_g as g_err, g.psfmagerr_r as r_err, g.psfmagerr_i as i_err, g.psfmagerr_z as z_err, p.pid,p.version,p.z,p.zerr,p.t,p.terr,p.quality, s.specobjid,s.ra,s.dec,s.z from db_2003.galaxy as g left outer join db_2003.specobjall s on g.objid=s.bestobjid, db_2003.photoz as p where g.objid in ({objidlist}) and g.objid=p.objid and g.i between 15 and 21 and p.z > {z1}
EXPLAIN (ANALYZE TRUE, COSTS FALSE, SUMMARY true)
SELECT g.key, g.value->>'ra', g.value->>'dec', g.value->>'u', g.value->>'g', g.value->>'r', g.value->>'i', g.value->>'z', g.value->>'psfmagerr_u' as u_err, g.value->>'psfmagerr_g' as g_err, g.value->>'psfmagerr_r' as r_err, g.value->>'psfmagerr_i' as i_err, g.value->>'psfmagerr_z' as z_err, 
				p.value->>'pid', p.value->>'version', p.value->>'z', p.value->>'zerr', p.value->>'t', p.value->>'terr', p.value->>'quality', 
				s.value->>'specobjid', s.value->>'ra', s.value->>'dec', s.value->>'z' 
FROM PhotoObjAll as g 
	LEFT OUTER JOIN SpecObjAll s ON g.key=s.value->>'bestobjid'
	JOIN Photoz as p ON g.key=p.key
WHERE g.key IN ('1237645879551066262') --({objidlist})
	AND g.value->>'class'='GALAXY'
	AND (g.value->>'i')::int BETWEEN 15 AND 21 
	AND (p.value->>'z')::float > 15.0; --{z1}

-- (11.40%) select g.objid,g.ra,g.dec, g.u,g.g,g.r,g.i,g.z, g.psfmagerr_u as u_err, g.psfmagerr_g as g_err, g.psfmagerr_r as r_err, g.psfmagerr_i as i_err, g.psfmagerr_z as z_err, p.pid,p.version,p.z,p.zerr,p.t,p.terr,p.quality, s.specobjid,s.ra,s.dec,s.z from db_2003.galaxy as g left outer join db_2003.specobjall s on g.objid=s.bestobjid, db_2003.photoz as p where g.objid in ({objidlist}) and g.objid=p.objid and g.i between 15 and 21 and p.z between {z1} and {z2}
EXPLAIN (ANALYZE TRUE, COSTS FALSE, SUMMARY true)
SELECT g.key, g.value->>'ra', g.value->>'dec', g.value->>'u', g.value->>'g', g.value->>'r', g.value->>'i', g.value->>'z', g.value->>'psfmagerr_u' as u_err, g.value->>'psfmagerr_g' as g_err, g.value->>'psfmagerr_r' as r_err, g.value->>'psfmagerr_i' as i_err, g.value->>'psfmagerr_z' as z_err, 
				p.value->>'pid', p.value->>'version', p.value->>'z', p.value->>'zerr', p.value->>'t', p.value->>'terr', p.value->>'quality', 
				s.value->>'specobjid', s.value->>'ra', s.value->>'dec', s.value->>'z' 
FROM PhotoObjAll as g  
	LEFT OUTER JOIN SpecObjAll s ON g.key=s.value->>'bestobjid'
	JOIN Photoz as p ON g.key=p.key 
WHERE g.key IN ('1237645879551066262') --({objidlist}) 
	AND g.value->>'class'='GALAXY'
	AND (g.value->>'i')::int BETWEEN 15 AND 21 
	AND (p.value->>'z')::float BETWEEN 15.0 AND 16.0; --{z1} and {z2}

-- (01.09%) select * from db_2003.specobjall where specobjid = {specobjid}
EXPLAIN (ANALYZE TRUE, COSTS FALSE, SUMMARY true)
SELECT s.value 
FROM SpecObjAll s 
WHERE s.key = ('430194949951088640'); --{specobjid}

--========================================================= 2023 Optimized ===============================================================================
DROP SCHEMA IF EXISTS sdss2003_optimized CASCADE;
CREATE SCHEMA sdss2003_optimized;
SHOW search_path;
SET search_path TO sdss2003_optimized, public;

-- This table contains those object not primary and not galaxy
DROP TABLE IF EXISTS sdss2003_optimized.PhotoObjAll;
CREATE TABLE sdss2003_optimized.PhotoObjAll AS (
	SELECT * 
	FROM SDSS2003.PhotoObjAll p 
	WHERE (p.value->>'mode')::int<>1 AND p.value->>'class'<>'GALAXY'
);
ALTER TABLE sdss2003_optimized.PhotoObjAll ADD PRIMARY KEY (key);

-- This table contains primary objects
DROP TABLE IF EXISTS sdss2003_optimized.PhotoObjAll_Primary;
CREATE TABLE sdss2003_optimized.PhotoObjAll_Primary AS (
	SELECT KEY, to_jsonb(ROW(p.value->>'run', p.value->>'rerun', p.value->>'camcol', p.value->>'field', p.value->>'obj', p.value->>'type', p.value->>'ra', p.value->>'dec', p.value->>'u', p.value->>'g', p.value->>'r', p.value->>'i', p.value->>'z', p.value->>'err_u', p.value->>'err_g', p.value->>'err_r', p.value->>'err_i', p.value->>'err_z')) AS value 
	FROM SDSS2003.PhotoObjAll p 
	WHERE (p.value->>'mode')::int=1
);
ALTER TABLE sdss2003_optimized.PhotoObjAll_Primary ADD PRIMARY KEY (key);

-- This table contains primary objects with unused attributes
DROP TABLE IF EXISTS sdss2003_optimized.PhotoObjAll_PrimaryComplementary;
CREATE TABLE sdss2003_optimized.PhotoObjAll_PrimaryComplementary AS (
	SELECT key, p.value-'run'-'rerun'-'camcol'-'field'-'obj'-'type'-'ra'-'dec'-'u'-'g'-'r'-'i'-'z'-'err_u'-'err_g'-'err_r'-'err_i'-'err_z' AS value 
	FROM SDSS2003.PhotoObjAll p 
	WHERE (p.value->>'mode')::int=1
);
ALTER TABLE sdss2003_optimized.PhotoObjAll_PrimaryComplementary ADD PRIMARY KEY (key);

-- This table contains galaxies that are not primary objects
DROP TABLE IF EXISTS sdss2003_optimized.PhotoObjAll_Galaxy;
CREATE TABLE sdss2003_optimized.PhotoObjAll_Galaxy AS (
	SELECT g.key, to_jsonb(ROW(g.value->>'ra', g.value->>'dec', g.value->>'u', g.value->>'g', g.value->>'r', g.value->>'i', g.value->>'z', 
					g.value->>'psfmagerr_u', g.value->>'psfmagerr_g', g.value->>'psfmagerr_r', g.value->>'psfmagerr_i', g.value->>'psfmagerr_z', 
					p.value->>'pid', p.value->>'version', p.value->>'z', p.value->>'zerr', p.value->>'t', p.value->>'terr', p.value->>'quality', 
					s.value->>'specobjid', s.value->>'ra', s.value->>'dec', s.value->>'z')) AS value
	FROM SDSS2003.PhotoObjAll as g 
		LEFT OUTER JOIN SDSS2003.SpecObjAll s ON g.key=(s.value->>'bestobjid')::bigint
		JOIN SDSS2003.Photoz as p ON g.key=p.key
	WHERE g.value->>'class'='GALAXY' AND (p.value->>'mode')::int<>1
);
ALTER TABLE sdss2003_optimized.PhotoObjAll_Galaxy ADD PRIMARY KEY (key);

-- This table contains the missing attributes of galaxies
DROP TABLE IF EXISTS sdss2003_optimized.PhotoObjAll_GalaxyComplementary;
CREATE TABLE sdss2003_optimized.PhotoObjAll_GalaxyComplementary AS (
	SELECT g.key, g.value-'ra'-'dec'-'u'-'g'-'r'-'i'-'z'-'psfmagerr_u'-'psfmagerr_g'-'psfmagerr_r'-'psfmagerr_i'-'psfmagerr_z' AS value
	FROM SDSS2003.PhotoObjAll as g 
	WHERE g.value->>'class'='GALAXY' AND (g.value->>'mode')::int<>1
		AND EXISTS (SELECT 'Found' FROM SDSS2003.Photoz as p WHERE g.key=p.key)
);
ALTER TABLE sdss2003_optimized.PhotoObjAll_GalaxyComplementary ADD PRIMARY KEY (key);

-- This table contains photoobjects of class galaxy that are not in Photoz
DROP TABLE IF EXISTS sdss2003_optimized.PhotoObjAll_Other;
CREATE TABLE sdss2003_optimized.PhotoObjAll_Other AS (
  SELECT *
  FROM SDSS2003.PhotoObjAll g 
	WHERE g.value->>'class'='GALAXY' AND (g.value->>'mode')::int<>1
		AND NOT EXISTS (SELECT 'Found' FROM SDSS2003.Photoz as p WHERE g.key=p.key)
);
ALTER TABLE sdss2003_optimized.PhotoObjAll_Other ADD PRIMARY KEY (key);

-- This table contains Photoz that are not embeded in sdss2003_optimized.PhotoObjAll_Galaxy
DROP TABLE IF EXISTS sdss2003_optimized.Photoz;
CREATE TABLE sdss2003_optimized.Photoz AS (
	SELECT *
	FROM SDSS2003.Photoz p
	WHERE NOT EXISTS (SELECT 'Found' FROM sdss2003_optimized.PhotoObjAll_Galaxy g WHERE g.key=p.key )
);
ALTER TABLE sdss2003_optimized.Photoz ADD PRIMARY KEY (key);

-- This table contains the attributes of those Photoz embeded in sdss2003_optimized.PhotoObjAll_Galaxy but not projected there
DROP TABLE IF EXISTS sdss2003_optimized.Photoz_Complementary;
CREATE TABLE sdss2003_optimized.Photoz_Complementary AS (
	SELECT p.key, value-'pid'-'version'-'z'-'zerr'-'t'-'terr'-'quality' AS value
	FROM SDSS2003.Photoz p
	WHERE EXISTS (SELECT 'Found' FROM sdss2003_optimized.PhotoObjAll_Galaxy g WHERE g.key=p.key )
);
ALTER TABLE sdss2003_optimized.Photoz_Complementary ADD PRIMARY KEY (key);

-- This table contains SpecObjAll that are not embeded in sdss2003_optimized.PhotoObjAll_Galaxy
DROP TABLE IF EXISTS sdss2003_optimized.SpecObjAll;
CREATE TABLE sdss2003_optimized.SpecObjAll AS (
	SELECT *
	FROM SDSS2003.SpecObjAll s
	WHERE NOT EXISTS (SELECT 'Found' FROM sdss2003_optimized.PhotoObjAll_Galaxy g WHERE g.key=(s.value->>'bestobjid')::bigint)
);
ALTER TABLE sdss2003_optimized.SpecObjAll ADD PRIMARY KEY (key);

-- This table contains the attributes of those SpecObjAll embeded in sdss2003_optimized.PhotoObjAll_Galaxy but not projected there
DROP TABLE IF EXISTS sdss2003_optimized.SpecObjAll_Complementary;
CREATE TABLE sdss2003_optimized.SpecObjAll_Complementary AS (
	SELECT s.key, s.value-'specobjid'-'ra'-'dec'-'z' AS value
	FROM SDSS2003.SpecObjAll s
	WHERE EXISTS (SELECT 'Found' FROM sdss2003_optimized.PhotoObjAll_Galaxy g WHERE g.key=(s.value->>'bestobjid')::bigint)
);
ALTER TABLE sdss2003_optimized.SpecObjAll_Complementary ADD PRIMARY KEY (key);

-- (60.30%) select p.objid, p.run, p.rerun, p.camcol, p.field, p.obj, p.type, p.ra, p.dec, p.u,p.g,p.r,p.i,p.z, p.err_u, p.err_g, p.err_r,p.err_i,p.err_z from db_2003.photoprimary p where p.objid in ({objidlist}) limit 1
EXPLAIN (ANALYZE TRUE, COSTS FALSE, SUMMARY true)
SELECT p.key, p.value->>'run', p.value->>'rerun', p.value->>'camcol', p.value->>'field', p.value->>'obj', p.value->>'type', p.value->>'ra', p.value->>'dec', p.value->>'u', p.value->>'g', p.value->>'r', p.value->>'i', p.value->>'z', p.value->>'err_u', p.value->>'err_g', p.value->>'err_r', p.value->>'err_i', p.value->>'err_z' 
FROM PhotoObjAll_Primary p 
WHERE (p.value->>'mode')::int=1 AND p.key IN ('1237645879551066262') --({objidlist})
LIMIT 1;

-- (22.46%) select p.run,p.type,p.ra,p.dec,p.g,p.r,p.err_g,p.err_r from db_2003.photoprimary p where p.objid in ({objidlist})
EXPLAIN (ANALYZE TRUE, COSTS FALSE, SUMMARY true)
SELECT p.value->>'run', p.value->>'type', p.value->>'ra', p.value->>'dec', p.value->>'g', p.value->>'r', p.value->>'err_g', p.value->>'err_r' 
FROM PhotoObjAll_Primary p 
WHERE (p.value->>'mode')::int=1 AND p.key IN ('1237645879551066262'); --({objidlist})

-- (04.75%) select g.objid,g.ra,g.dec, g.u,g.g,g.r,g.i,g.z, g.psfmagerr_u as u_err, g.psfmagerr_g as g_err, g.psfmagerr_r as r_err, g.psfmagerr_i as i_err, g.psfmagerr_z as z_err, p.pid,p.version,p.z,p.zerr,p.t,p.terr,p.quality, s.specobjid,s.ra,s.dec,s.z from db_2003.galaxy as g left outer join db_2003.specobjall s on g.objid=s.bestobjid, db_2003.photoz as p where g.objid in ({objidlist}) and g.objid=p.objid and g.i between 15 and 21 and p.z > {z1}
EXPLAIN (ANALYZE TRUE, COSTS FALSE, SUMMARY true)
SELECT g.key, g.value->>'ra', g.value->>'dec', g.value->>'u', g.value->>'g', g.value->>'r', g.value->>'i', g.value->>'z', g.value->>'psfmagerr_u' as u_err, g.value->>'psfmagerr_g' as g_err, g.value->>'psfmagerr_r' as r_err, g.value->>'psfmagerr_i' as i_err, g.value->>'psfmagerr_z' as z_err, 
				g.value->>'pid', g.value->>'version', g.value->>'z', g.value->>'zerr', g.value->>'t', g.value->>'terr', g.value->>'quality', 
				g.value->>'specobjid', g.value->>'ra', g.value->>'dec', g.value->>'z' 
FROM sdss2003_optimized.PhotoObjAll_Galaxy as g 
WHERE g.key IN ('1237645879551066262') --({objidlist})
	AND (g.value->>'i')::int BETWEEN 15 AND 21 
	AND (g.value->>'z')::float > 15.0; --{z1}
	
-- (11.40%) select g.objid,g.ra,g.dec, g.u,g.g,g.r,g.i,g.z, g.psfmagerr_u as u_err, g.psfmagerr_g as g_err, g.psfmagerr_r as r_err, g.psfmagerr_i as i_err, g.psfmagerr_z as z_err, p.pid,p.version,p.z,p.zerr,p.t,p.terr,p.quality, s.specobjid,s.ra,s.dec,s.z from db_2003.galaxy as g left outer join db_2003.specobjall s on g.objid=s.bestobjid, db_2003.photoz as p where g.objid in ({objidlist}) and g.objid=p.objid and g.i between 15 and 21 and p.z between {z1} and {z2}
EXPLAIN (ANALYZE TRUE, COSTS FALSE, SUMMARY true)
SELECT g.key, g.value->>'ra', g.value->>'dec', g.value->>'u', g.value->>'g', g.value->>'r', g.value->>'i', g.value->>'z', g.value->>'psfmagerr_u' as u_err, g.value->>'psfmagerr_g' as g_err, g.value->>'psfmagerr_r' as r_err, g.value->>'psfmagerr_i' as i_err, g.value->>'psfmagerr_z' as z_err, 
				g.value->>'pid', g.value->>'version', g.value->>'z', g.value->>'zerr', g.value->>'t', g.value->>'terr', g.value->>'quality', 
				g.value->>'specobjid', g.value->>'ra', g.value->>'dec', g.value->>'z' 
FROM sdss2003_optimized.PhotoObjAll_Galaxy as g 
WHERE g.key IN ('1237645879551066262') --({objidlist})
	AND (g.value->>'i')::int BETWEEN 15 AND 21 
	AND (g.value->>'z')::float BETWEEN 15.0 AND 16.0; --{z1} and {z2}
	
-- (01.09%) select * from db_2003.specobjall where specobjid = {specobjid}
EXPLAIN (ANALYZE TRUE, COSTS FALSE, SUMMARY true)
SELECT *
FROM SpecObjAll s1
UNION
SELECT s2.key, jsonb_set(jsonb_set(jsonb_set(jsonb_set(s2.value,'{specobjid}',g.value->'specobjid'), '{ra}', g.value->'ra'), '{dec}', g.value->'dec'), '{z}', g.value->'z')
FROM SpecObjAll_Complementary s2
  JOIN sdss2003_optimized.PhotoObjAll_Galaxy g ON g.key=s2.key;
  					


