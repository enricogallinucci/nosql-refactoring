--========================================================= 2023 Optimized ===============================================================================
DROP SCHEMA IF EXISTS SDSS2013_over2003_aa CASCADE;
CREATE SCHEMA SDSS2013_over2003_aa;
SET search_path TO SDSS2013_over2003_aa, public;
SHOW search_path;

--*********************************************************** Tables *************************************************************************
-- This table contains those object not primary and not galaxy
DROP TABLE IF EXISTS PhotoObjAll;
CREATE TABLE PhotoObjAll AS (
	SELECT * 
	FROM SDSS2003.PhotoObjAll p 
	WHERE (p.value->>'mode')::int<>1 
		AND (p.value->>'type')::int4<>3 --class<>'GALAXY' (see https://skyserver.sdss.org/dr1/en/help/browser/browser.asp)
);
ALTER TABLE PhotoObjAll ADD PRIMARY KEY (key);

-- This table contains primary objects
DROP TABLE IF EXISTS PhotoObjAll_Primary;
CREATE TABLE PhotoObjAll_Primary AS (
	SELECT KEY, jsonb_build_object('run', p.value->>'run', 'rerun', p.value->>'rerun', 'camcol', p.value->>'camcol', 'field', p.value->>'field', 'obj', p.value->>'obj', 'type', p.value->>'type', 'ra', p.value->>'ra', 'dec', p.value->>'dec', 'u', p.value->>'u', 'g', p.value->>'g', 'r', p.value->>'r', 'i', p.value->>'i', 'z', p.value->>'z', 'psfmagerr_u', p.value->>'psfmagerr_u', 'psfmagerr_g', p.value->>'psfmagerr_g', 'psfmagerr_r', p.value->>'psfmagerr_r', 'psfmagerr_i', p.value->>'psfmagerr_i', 'psfmagerr_z', p.value->>'psfmagerr_z') AS value 
	FROM SDSS2003.PhotoObjAll p 
	WHERE (p.value->>'mode')::int4=1
);
ALTER TABLE PhotoObjAll_Primary ADD PRIMARY KEY (key);

-- This table contains primary objects with unused attributes
DROP TABLE IF EXISTS PhotoObjAll_PrimaryComplementary;
CREATE TABLE PhotoObjAll_PrimaryComplementary AS (
	SELECT key, p.value-ARRAY['run','rerun','camcol','field','obj','ra','dec','u','g','r','i','z','err_u','err_g','err_r','err_i','err_z'] AS value --'type' attribute is in both
	FROM SDSS2003.PhotoObjAll p 
	WHERE (p.value->>'mode')::int4=1
);
ALTER TABLE PhotoObjAll_PrimaryComplementary ADD PRIMARY KEY (key);

-- This table contains galaxies that are not primary objects
DROP TABLE IF EXISTS PhotoObjAll_Galaxy;
CREATE TABLE PhotoObjAll_Galaxy AS (
	SELECT g.key, jsonb_build_object(g.value->>'ra', g.value->>'dec', g.value->>'u', g.value->>'g', g.value->>'r', g.value->>'i', g.value->>'z', g.value->>'psfmagerr_u', g.value->>'psfmagerr_g', g.value->>'psfmagerr_r', g.value->>'psfmagerr_i', g.value->>'psfmagerr_z', 
					'Photoz', jsonb_build_object('pid', p.value->>'pid', 'version', p.value->>'version', 'z', p.value->>'z', 'zerr', p.value->>'zerr', 't', p.value->>'t', 'terr', p.value->>'terr', 'quality', p.value->>'quality'), 
					'SpecObj', jsonb_build_object('specobjid', s.value->>'specobjid', 'ra', s.value->>'ra', 'dec', s.value->>'dec', 'z', s.value->>'z')) AS value
	FROM SDSS2003.PhotoObjAll as g 
		LEFT OUTER JOIN SDSS2003.SpecObjAll s ON g.key=(s.value->>'bestobjid')::int8
		JOIN SDSS2003.Photoz as p ON g.key=p.key
	WHERE (g.value->>'type')::int4=3 --class='GALAXY' (see https://skyserver.sdss.org/dr1/en/help/browser/browser.asp)
	  AND (p.value->>'mode')::int4<>1
);
ALTER TABLE PhotoObjAll_Galaxy ADD PRIMARY KEY (key);

-- This table contains the missing attributes of galaxies
DROP TABLE IF EXISTS PhotoObjAll_GalaxyComplementary;
CREATE TABLE PhotoObjAll_GalaxyComplementary AS (
	SELECT g.key, g.value-ARRAY['ra','dec','u','g','r','i','z','psfmagerr_u','psfmagerr_g','psfmagerr_r','psfmagerr_i','psfmagerr_z'] AS value
	FROM SDSS2003.PhotoObjAll as g 
	WHERE (g.value->>'type')::int4=3 --class='GALAXY' (see https://skyserver.sdss.org/dr1/en/help/browser/browser.asp) 
		AND (g.value->>'mode')::int4<>1
		AND EXISTS (SELECT 'Found' FROM SDSS2003.Photoz as p WHERE g.key=p.key)
);
ALTER TABLE PhotoObjAll_GalaxyComplementary ADD PRIMARY KEY (key);

-- This table contains photoobjects of class galaxy that are not in Photoz
DROP TABLE IF EXISTS PhotoObjAll_Other;
CREATE TABLE PhotoObjAll_Other AS (
  SELECT *
  FROM SDSS2003.PhotoObjAll g 
	WHERE (g.value->>'type')::int4=3 --class='GALAXY' (see https://skyserver.sdss.org/dr1/en/help/browser/browser.asp) 
		AND (g.value->>'mode')::int4<>1
		AND NOT EXISTS (SELECT 'Found' FROM SDSS2003.Photoz as p WHERE g.key=p.key)
);
ALTER TABLE PhotoObjAll_Other ADD PRIMARY KEY (key);

-- This table contains Photoz that are not embeded in PhotoObjAll_Galaxy
DROP TABLE IF EXISTS Photoz;
CREATE TABLE Photoz AS (
	SELECT *
	FROM SDSS2003.Photoz p
	WHERE NOT EXISTS (SELECT 'Found' FROM PhotoObjAll_Galaxy g WHERE g.key=p.key )
);
ALTER TABLE Photoz ADD PRIMARY KEY (key);

-- This table contains the attributes of those Photoz embeded in PhotoObjAll_Galaxy but not projected there
DROP TABLE IF EXISTS Photoz_Complementary;
CREATE TABLE Photoz_Complementary AS (
	SELECT p.key, value-'pid'-'version'-'z'-'zerr'-'t'-'terr'-'quality' AS value
	FROM SDSS2003.Photoz p
	WHERE EXISTS (SELECT 'Found' FROM PhotoObjAll_Galaxy g WHERE g.key=p.key)
);
ALTER TABLE Photoz_Complementary ADD PRIMARY KEY (key);

-- This table contains SpecObjAll that are not embeded in PhotoObjAll_Galaxy
DROP TABLE IF EXISTS SpecObjAll;
CREATE TABLE SpecObjAll AS (
	SELECT *
	FROM SDSS2003.SpecObjAll s
	WHERE NOT EXISTS (SELECT 'Found' FROM PhotoObjAll_Galaxy g WHERE g.key=(s.value->>'bestobjid')::int8)
);
ALTER TABLE SpecObjAll ADD PRIMARY KEY (key);

DROP INDEX IF EXISTS SpecObjAll_bestobjid;
CREATE INDEX SpecObjAll_bestobjid ON SpecObjAll(((value->>'bestobjid')::int8));

-- This table contains the attributes of those SpecObjAll embeded in PhotoObjAll_Galaxy but not projected there
DROP TABLE IF EXISTS SpecObjAll_Complementary;
CREATE TABLE SpecObjAll_Complementary AS (
	SELECT s.key, s.value-ARRAY['specobjid','ra','dec','z'] AS value
	FROM SDSS2003.SpecObjAll s
	WHERE EXISTS (SELECT 'Found' FROM PhotoObjAll_Galaxy g WHERE g.key=(s.value->>'bestobjid')::int8)
);
ALTER TABLE SpecObjAll_Complementary ADD PRIMARY KEY (key);

--********************************************************* New tables *********************************************************************
DROP TABLE IF EXISTS PhotozRF;
CREATE TABLE PhotozRF AS (
	SELECT * 
	FROM SDSS2003.PhotozRF
);
ALTER TABLE PhotozRF ADD PRIMARY KEY (key);

DROP TABLE IF EXISTS Frame;
CREATE TABLE Frame AS (
	SELECT * 
	FROM SDSS2003.Frame
);
ALTER TABLE Frame ADD PRIMARY KEY (key);

DROP TABLE IF EXISTS Field;
CREATE TABLE Field AS (
	SELECT * 
	FROM SDSS2003.Field
);
ALTER TABLE Field ADD PRIMARY KEY (key);

DROP TABLE IF EXISTS GalSpecIndx;
CREATE TABLE GalSpecIndx AS (
	SELECT * 
	FROM SDSS2003.GalSpecIndx
);
ALTER TABLE GalSpecIndx ADD PRIMARY KEY (key);

--*********************************************************** Queries *************************************************************************
-- (10.66%)	SELECT '<a target=INFO href=http://skyserver.sdss3.org/dr9/en/tools/explore/obj.asp?id=' || CAST(p.objId AS VARCHAR(20)) || '>' || CAST(p.objId AS VARCHAR(20)) || '</a>' AS objID, p.run, p.rerun, p.camcol, p.field, p.obj, p.type, p.ra, p.dec, p.u, p.g, p.r, p.i, p.z, p.Err_u, p.Err_g, p.Err_r, p.Err_i, p.Err_z FROM db_2013.PhotoPrimary p WHERE p.objID in ({objidlist}) LIMIT 1;
-- (1.33%)	SELECT p.objid, p.run, p.rerun, p.camcol, p.field, p.obj, p.type, p.ra, p.dec, p.u,p.g,p.r,p.i,p.z, p.Err_u, p.Err_g, p.Err_r,p.Err_i,p.Err_z FROM db_2013.photoprimary p WHERE p.objID in ({objidlist}) limit 50000
-- (14.13%)	select g.objid, pz.z, pz.zerr, pzr.z, pzr.zerr, poa.u, poa.err_u, poa.g, poa.err_g, poa.r, poa.err_r, poa.i, poa.err_i, poa.z, poa.err_z from db_2013.galaxy as g join db_2013.photoz as pz on g.objid = pz.objid join db_2013.photozrf as pzr on g.objid = pzr.objid join db_2013.photoobjall as poa on g.objid = poa.objid where g.objid in ({objidlist}) and (g.flags & 262144) = 0
-- (5.47%)	select * from db_2013.specobjall where specobjid = {specobjid}
-- (4.68%)	select * from db_2013.photoz where objid={objid}
-- (10.78%)	select * from db_2013.photoobjall where objid= {objid}
-- (3.49%)	select * from db_2013.frame where fieldid={fieldid}
-- (3.07%)	select * from db_2013.speclineindex where specobjid={specobjid}
-- (2.63%)	select * from db_2013.field where fieldid={fieldid}
-- (2.73%)	select * from db_2013.galspecindx where specobjid={specobjid}

-- (60.30%) select p.objid, p.run, p.rerun, p.camcol, p.field, p.obj, p.type, p.ra, p.dec, p.u,p.g,p.r,p.i,p.z, p.err_u, p.err_g, p.err_r,p.err_i,p.err_z from db_2003.photoprimary p where p.objid in ({objidlist}) limit 1
EXPLAIN (ANALYZE TRUE, COSTS FALSE, SUMMARY true)
SELECT p.key, p.value->>'run', p.value->>'rerun', p.value->>'camcol', p.value->>'field', p.value->>'obj', p.value->>'type', p.value->>'ra', p.value->>'dec', p.value->>'u', p.value->>'g', p.value->>'r', p.value->>'i', p.value->>'z', p.value->>'err_u', p.value->>'err_g', p.value->>'err_r', p.value->>'err_i', p.value->>'err_z' 
FROM PhotoObjAll_Primary p 
WHERE p.key IN (1237645941824356443) --({objidlist})
LIMIT 1;

-- (22.46%) select p.run,p.type,p.ra,p.dec,p.g,p.r,p.err_g,p.err_r from db_2003.photoprimary p where p.objid in ({objidlist})
EXPLAIN (ANALYZE TRUE, COSTS FALSE, SUMMARY true)
SELECT p.value->>'run', p.value->>'type', p.value->>'ra', p.value->>'dec', p.value->>'g', p.value->>'r', p.value->>'err_g', p.value->>'err_r' 
FROM PhotoObjAll_Primary p 
WHERE p.key IN (1237645941824356443); --({objidlist})

-- (04.75%) select g.objid,g.ra,g.dec, g.u,g.g,g.r,g.i,g.z, g.psfmagerr_u as u_err, g.psfmagerr_g as g_err, g.psfmagerr_r as r_err, g.psfmagerr_i as i_err, g.psfmagerr_z as z_err, p.pid,p.version,p.z,p.zerr,p.t,p.terr,p.quality, s.specobjid,s.ra,s.dec,s.z from db_2003.galaxy as g left outer join db_2003.specobjall s on g.objid=s.bestobjid, db_2003.photoz as p where g.objid in ({objidlist}) and g.objid=p.objid and g.i between 15 and 21 and p.z > {z1}
EXPLAIN (ANALYZE TRUE, COSTS FALSE, SUMMARY true)
-- Galaxies that are NOT primary objects
SELECT g.key, g.value->>'ra', g.value->>'dec', g.value->>'u', g.value->>'g', g.value->>'r', g.value->>'i', g.value->>'z', g.value->>'psfmagerr_u' as u_err, g.value->>'psfmagerr_g' as g_err, g.value->>'psfmagerr_r' as r_err, g.value->>'psfmagerr_i' as i_err, g.value->>'psfmagerr_z' as z_err, 
				g.value->'Photoz'->>'pid', g.value->'Photoz'->>'version', g.value->'Photoz'->>'z', g.value->'Photoz'->>'zerr', g.value->'Photoz'->>'t', g.value->'Photoz'->>'terr', g.value->'Photoz'->>'quality', 
				g.value->'SpecObj'->>'specobjid', g.value->'SpecObj'->>'ra', g.value->'SpecObj'->>'dec', g.value->'SpecObj'->>'z' 
FROM PhotoObjAll_Galaxy as g 
WHERE g.key IN (1237645941824356443) --({objidlist})
	AND (g.value->>'i')::float4 BETWEEN 14.0 AND 21.0 -- Should be BETWEEN 15 AND 21
	AND (g.value->>'z')::float4 > 0 --{z1}
UNION ALL
-- Galaxies that are primary objects
SELECT g.key, g.value->>'ra', g.value->>'dec', g.value->>'u', g.value->>'g', g.value->>'r', g.value->>'i', g.value->>'z', g.value->>'psfmagerr_u' as u_err, g.value->>'psfmagerr_g' as g_err, g.value->>'psfmagerr_r' as r_err, g.value->>'psfmagerr_i' as i_err, g.value->>'psfmagerr_z' as z_err, 
					p.value->>'pid', p.value->>'version', p.value->>'z', p.value->>'zerr', p.value->>'t', p.value->>'terr', p.value->>'quality', 
					s.value->>'specobjid', s.value->>'ra', s.value->>'dec', s.value->>'z'
FROM (
			SELECT  pp.KEY, pp.value||pc.value AS value
			FROM (SELECT * FROM PhotoObjAll_Primary WHERE key IN (1237645941824356443)) pp 
				JOIN (SELECT * FROM PhotoObjAll_PrimaryComplementary WHERE key IN (1237645941824356443)) pc ON pp.KEY=pc.KEY
			WHERE (pp.value->>'type')::int4=3 --AND (pc.value->>'type')::int4=3 --class='GALAXY' (see https://skyserver.sdss.org/dr1/en/help/browser/browser.asp)
			  AND (pp.value->>'i')::float4 BETWEEN 14.0 AND 21.0 -- Should be BETWEEN 15 AND 21
			) as g 
	LEFT OUTER JOIN SpecObjAll s ON g.KEY=(s.value->>'bestobjid')::int8
	JOIN Photoz as p ON g.key=p.key
WHERE (p.value->>'z')::float4 > 0 --{z1}
;
	
-- (11.40%) select g.objid,g.ra,g.dec, g.u,g.g,g.r,g.i,g.z, g.psfmagerr_u as u_err, g.psfmagerr_g as g_err, g.psfmagerr_r as r_err, g.psfmagerr_i as i_err, g.psfmagerr_z as z_err, p.pid,p.version,p.z,p.zerr,p.t,p.terr,p.quality, s.specobjid,s.ra,s.dec,s.z from db_2003.galaxy as g left outer join db_2003.specobjall s on g.objid=s.bestobjid, db_2003.photoz as p where g.objid in ({objidlist}) and g.objid=p.objid and g.i between 15 and 21 and p.z between {z1} and {z2}
EXPLAIN (ANALYZE TRUE, COSTS FALSE, SUMMARY true)
-- Galaxies that are NOT primary objects
SELECT g.key, g.value->>'ra', g.value->>'dec', g.value->>'u', g.value->>'g', g.value->>'r', g.value->>'i', g.value->>'z', g.value->>'psfmagerr_u' as u_err, g.value->>'psfmagerr_g' as g_err, g.value->>'psfmagerr_r' as r_err, g.value->>'psfmagerr_i' as i_err, g.value->>'psfmagerr_z' as z_err, 
				g.value->'Photoz'->>'pid', g.value->'Photoz'->>'version', g.value->'Photoz'->>'z', g.value->'Photoz'->>'zerr', g.value->'Photoz'->>'t', g.value->'Photoz'->>'terr', g.value->'Photoz'->>'quality', 
				g.value->'SpecObj'->>'specobjid', g.value->'SpecObj'->>'ra', g.value->'SpecObj'->>'dec', g.value->'SpecObj'->>'z' 
FROM PhotoObjAll_Galaxy as g 
WHERE g.key IN (1237648702985142480) --({objidlist})
	AND (g.value->>'i')::float4 BETWEEN 14.0 AND 21.0 -- Should be BETWEEN 15 AND 21
	AND (g.value->>'z')::float4 BETWEEN 0 AND 1.0 --{z1}
UNION ALL
-- Galaxies that are primary objects
SELECT g.key, g.value->>'ra', g.value->>'dec', g.value->>'u', g.value->>'g', g.value->>'r', g.value->>'i', g.value->>'z', g.value->>'psfmagerr_u' as u_err, g.value->>'psfmagerr_g' as g_err, g.value->>'psfmagerr_r' as r_err, g.value->>'psfmagerr_i' as i_err, g.value->>'psfmagerr_z' as z_err, 
					p.value->>'pid', p.value->>'version', p.value->>'z', p.value->>'zerr', p.value->>'t', p.value->>'terr', p.value->>'quality', 
					s.value->>'specobjid', s.value->>'ra', s.value->>'dec', s.value->>'z'
FROM (
			SELECT  pp.KEY, pp.value||pc.value AS value
			FROM (SELECT * FROM PhotoObjAll_Primary WHERE key IN (1237648702985142480)) pp 
				JOIN (SELECT * FROM PhotoObjAll_PrimaryComplementary WHERE key IN (1237648702985142480)) pc ON pp.KEY=pc.KEY
			WHERE (pp.value->>'type')::int4=3 --AND (pc.value->>'type')::int4=3 --class='GALAXY' (see https://skyserver.sdss.org/dr1/en/help/browser/browser.asp)
			  AND (pp.value->>'i')::float4 BETWEEN 14.0 AND 21.0 -- Should be BETWEEN 15 AND 21
			) as g 
	LEFT OUTER JOIN SpecObjAll s ON g.KEY=(s.value->>'bestobjid')::int8
	JOIN Photoz as p ON g.key=p.key
WHERE (p.value->>'z')::float4 BETWEEN 0 AND 1.0 --{z1}
;

-- THIS IS THE SIMPLIFIED VERSION OF THE PREVIOUS TWO QUERIES IF WE ALLOW PhotoObjects that are Primary and Galaxies to be replicated in two different tables
-- The problem is not to do this, but how to justify it and at the same time advocate for not using MVs
/*
SELECT g.key, g.value->>'ra', g.value->>'dec', g.value->>'u', g.value->>'g', g.value->>'r', g.value->>'i', g.value->>'z', g.value->>'psfmagerr_u' as u_err, g.value->>'psfmagerr_g' as g_err, g.value->>'psfmagerr_r' as r_err, g.value->>'psfmagerr_i' as i_err, g.value->>'psfmagerr_z' as z_err, 
				g.value->'Photoz'->>'pid', g.value->'Photoz'->>'version', g.value->'Photoz'->>'z', g.value->'Photoz'->>'zerr', g.value->'Photoz'->>'t', g.value->'Photoz'->>'terr', g.value->'Photoz'->>'quality', 
				g.value->'SpecObj'->>'specobjid', g.value->'SpecObj'->>'ra', g.value->'SpecObj'->>'dec', g.value->'SpecObj'->>'z' 
FROM PhotoObjAll_Galaxy as g 
WHERE g.key IN (1237645941824356443) --({objidlist})
	AND (g.value->>'i')::float4 BETWEEN 14.0 AND 21.0 -- Should be BETWEEN 15 AND 21
	AND (g.value->>'z')::float4 BETWEEN 0 AND 1.0; --{z1} and {z2}
*/
	
-- (01.09%) select * from db_2003.specobjall where specobjid = {specobjid}
EXPLAIN (ANALYZE TRUE, COSTS FALSE, SUMMARY true)
SELECT *
FROM SpecObjAll s1
WHERE s1.key = 77628570523926528
UNION ALL
SELECT s2.key, s2.value||jsonb_build_object('specobjid',g.value->'SpecObj'->>'specobjid', 'ra', g.value->'SpecObj'->>'ra', 'dec', g.value->'SpecObj'->>'dec', 'z', g.value->'SpecObj'->>'z')
FROM SpecObjAll_Complementary s2
  JOIN PhotoObjAll_Galaxy g ON g.key=s2.KEY
WHERE s2.key = 77628570523926528;



