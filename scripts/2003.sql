--========================================================= 2023 Original ===============================================================================
DROP SCHEMA IF EXISTS SDSS2003_aa CASCADE;
CREATE SCHEMA SDSS2003_aa;
SET search_path TO SDSS2003_aa, public;
SET search_path TO SDSS2003, public;

SHOW search_path;

DROP TABLE IF EXISTS PhotoObjAll;
CREATE TABLE PhotoObjAll 
--(	key int8 PRIMARY KEY, value jsonb NOT NULL)
AS (SELECT * FROM sdss2003.PhotoObjAll)
;
	
-- Photoz should have a FK to PhotoObjAll correspondin to a 0..1-1 relationship
DROP TABLE IF EXISTS Photoz;
CREATE TABLE Photoz 
--(key int8 PRIMARY KEY, value jsonb NOT NULL)
AS (SELECT * FROM sdss2003.Photoz)
;

-- SpecObjAll should have a FK to PhotoObjAll correspondin to a *-1 relationship
DROP TABLE IF EXISTS SpecObjAll;
CREATE TABLE SpecObjAll 
--(key int8 PRIMARY KEY, value jsonb NOT NULL)
AS (SELECT * FROM sdss2003.SpecObjAll)
;

DROP INDEX IF EXISTS SpecObjAll_bestobjid;
CREATE INDEX SpecObjAll_bestobjid ON SpecObjAll(((value->>'bestobjid')::int8));

-- (60.30%) select p.objid, p.run, p.rerun, p.camcol, p.field, p.obj, p.type, p.ra, p.dec, p.u,p.g,p.r,p.i,p.z, p.err_u, p.err_g, p.err_r,p.err_i,p.err_z from db_2003.photoprimary p where p.objid in ({objidlist}) limit 1
EXPLAIN (ANALYZE TRUE, COSTS FALSE, SUMMARY true)
SELECT p.key, p.value->>'run', p.value->>'rerun', p.value->>'camcol', p.value->>'field', p.value->>'obj', p.value->>'type', p.value->>'ra', p.value->>'dec', p.value->>'u', p.value->>'g', p.value->>'r', p.value->>'i', p.value->>'z', p.value->>'err_u', p.value->>'err_g', p.value->>'err_r', p.value->>'err_i', p.value->>'err_z' 
FROM PhotoObjAll p 
WHERE (p.value->>'mode')::int=1 AND p.key IN (1237645941824356443) --({objidlist})
LIMIT 1;

-- (22.46%) select p.run,p.type,p.ra,p.dec,p.g,p.r,p.err_g,p.err_r from db_2003.photoprimary p where p.objid in ({objidlist})
EXPLAIN (ANALYZE TRUE, COSTS FALSE, SUMMARY true)
SELECT p.value->>'run', p.value->>'type', p.value->>'ra', p.value->>'dec', p.value->>'g', p.value->>'r', p.value->>'err_g', p.value->>'err_r' 
FROM PhotoObjAll p 
WHERE (p.value->>'mode')::int=1 AND p.key IN (1237645941824356443); --({objidlist})

-- (04.75%) select g.objid,g.ra,g.dec, g.u,g.g,g.r,g.i,g.z, g.psfmagerr_u as u_err, g.psfmagerr_g as g_err, g.psfmagerr_r as r_err, g.psfmagerr_i as i_err, g.psfmagerr_z as z_err, p.pid,p.version,p.z,p.zerr,p.t,p.terr,p.quality, s.specobjid,s.ra,s.dec,s.z from db_2003.galaxy as g left outer join db_2003.specobjall s on g.objid=s.bestobjid, db_2003.photoz as p where g.objid in ({objidlist}) and g.objid=p.objid and g.i between 15 and 21 and p.z > {z1}
EXPLAIN (ANALYZE TRUE, COSTS FALSE, SUMMARY true)
SELECT g.key, g.value->>'ra', g.value->>'dec', g.value->>'u', g.value->>'g', g.value->>'r', g.value->>'i', g.value->>'z', g.value->>'psfmagerr_u' as u_err, g.value->>'psfmagerr_g' as g_err, g.value->>'psfmagerr_r' as r_err, g.value->>'psfmagerr_i' as i_err, g.value->>'psfmagerr_z' as z_err, 
				p.value->>'pid', p.value->>'version', p.value->>'z', p.value->>'zerr', p.value->>'t', p.value->>'terr', p.value->>'quality', 
				s.value->>'specobjid', s.value->>'ra', s.value->>'dec', s.value->>'z' 
FROM PhotoObjAll as g 
	LEFT OUTER JOIN SpecObjAll s ON g.key=(s.value->>'bestobjid')::int8
	JOIN Photoz as p ON g.key=p.key
WHERE g.key IN (1237645941824356443) --({objidlist})
	AND (g.value->>'type')::int4=3 --class='GALAXY' (see https://skyserver.sdss.org/dr1/en/help/browser/browser.asp)
	AND (g.value->>'i')::float4 BETWEEN 14.0 AND 21.0 -- Should be BETWEEN 15 AND 21
	AND (p.value->>'z')::float4 > 0; --{z1}	

-- (11.40%) select g.objid,g.ra,g.dec, g.u,g.g,g.r,g.i,g.z, g.psfmagerr_u as u_err, g.psfmagerr_g as g_err, g.psfmagerr_r as r_err, g.psfmagerr_i as i_err, g.psfmagerr_z as z_err, p.pid,p.version,p.z,p.zerr,p.t,p.terr,p.quality, s.specobjid,s.ra,s.dec,s.z from db_2003.galaxy as g left outer join db_2003.specobjall s on g.objid=s.bestobjid, db_2003.photoz as p where g.objid in ({objidlist}) and g.objid=p.objid and g.i between 15 and 21 and p.z between {z1} and {z2}
EXPLAIN (ANALYZE TRUE, COSTS FALSE, SUMMARY true)
SELECT g.key, g.value->>'ra', g.value->>'dec', g.value->>'u', g.value->>'g', g.value->>'r', g.value->>'i', g.value->>'z', g.value->>'psfmagerr_u' as u_err, g.value->>'psfmagerr_g' as g_err, g.value->>'psfmagerr_r' as r_err, g.value->>'psfmagerr_i' as i_err, g.value->>'psfmagerr_z' as z_err, 
				p.value->>'pid', p.value->>'version', p.value->>'z', p.value->>'zerr', p.value->>'t', p.value->>'terr', p.value->>'quality', 
				s.value->>'specobjid', s.value->>'ra', s.value->>'dec', s.value->>'z'
FROM PhotoObjAll as g  
	LEFT OUTER JOIN SpecObjAll s ON g.key=(s.value->>'bestobjid')::int8
	JOIN Photoz as p ON g.key=p.key 
WHERE g.key IN (1237648702985142480) --({objidlist}) 
	AND (g.value->>'type')::int4=3 --class='GALAXY' (see https://skyserver.sdss.org/dr1/en/help/browser/browser.asp)
	AND (g.value->>'i')::float4 BETWEEN 14.0 AND 21.0 -- Should be BETWEEN 15 AND 21
	AND (p.value->>'z')::float4 BETWEEN 0 AND 1.0; --{z1} and {z2}

-- (01.09%) select * from db_2003.specobjall where specobjid = {specobjid}
EXPLAIN (ANALYZE TRUE, COSTS FALSE, SUMMARY true)
SELECT s.value 
FROM SpecObjAll s 
WHERE s.key = 77628570523926528; --{specobjid}