--========================================================= 2023 Original ===============================================================================
DROP SCHEMA IF EXISTS aa_SDSS2003 CASCADE;
CREATE SCHEMA aa_SDSS2003;
SET search_path TO aa_SDSS2003, public;
SHOW search_path;

DROP TABLE IF EXISTS PhotoObjAll;
CREATE TABLE PhotoObjAll AS (
	SELECT	p.objid as key,
    			(to_jsonb(p.*) - 'objid') AS value 
  FROM sdss_relational2.PhotoObjAll AS p);
ALTER TABLE PhotoObjAll ADD PRIMARY KEY (key);

DROP INDEX IF EXISTS idx_PhotoObjAll_ra_dec;
CREATE INDEX idx_PhotoObjAll_ra_dec ON PhotoObjAll(
  CAST(value->>'ra' AS FLOAT),
  CAST(value->>'dec' AS FLOAT)
);

-- Photoz should have a FK to PhotoObjAll correspondin to a 0..1-1 relationship
DROP TABLE IF EXISTS Photoz;
CREATE TABLE Photoz AS (
	SELECT p.objid as key,
    		(to_jsonb(p.*) - 'objid') AS value
	FROM sdss_relational2.photoz p);
ALTER TABLE Photoz ADD PRIMARY KEY (key);

DROP INDEX IF EXISTS idx_Photoz_z;
CREATE INDEX idx_Photoz_z ON Photoz(
  CAST(value->>'z' AS float)
);

-- SpecObjAll should have a FK to PhotoObjAll correspondin to a *-1 relationship
DROP TABLE IF EXISTS SpecObjAll;
CREATE TABLE SpecObjAll AS (
	SELECT s.specObjID as key,
    		(to_jsonb(s.*) - 'specObjID') AS value
	FROM sdss_relational2.SpecObjAll AS s);
ALTER TABLE SpecObjAll ADD PRIMARY KEY (key);

DROP INDEX IF EXISTS SpecObjAll_bestobjid;
CREATE INDEX SpecObjAll_bestobjid ON SpecObjAll(
	CAST(value->>'bestobjid' AS int8));
DROP INDEX IF EXISTS idx_SpecObjAll_ra_dec;
CREATE INDEX idx_SpecObjAll_ra_dec ON SpecObjAll(
  CAST(value->>'ra' AS FLOAT),
  CAST(value->>'dec' AS FLOAT)
);

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
SELECT g.key, g.value->>'ra', g.value->>'dec', g.value->>'u', g.value->>'g', g.value->>'r', g.value->>'i' AS i, g.value->>'z', g.value->>'psfmagerr_u' as u_err, g.value->>'psfmagerr_g' as g_err, g.value->>'psfmagerr_r' as r_err, g.value->>'psfmagerr_i' as i_err, g.value->>'psfmagerr_z' as z_err, 
				p.value->>'pid', p.value->>'version', p.value->>'z' AS pz, p.value->>'zerr', p.value->>'t', p.value->>'terr', p.value->>'quality', 
				s.value->>'specobjid', s.value->>'ra', s.value->>'dec', s.value->>'z' AS sz
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
WHERE g.key IN (1237645941824356443) --({objidlist}) 
	AND (g.value->>'type')::int4=3 --class='GALAXY' (see https://skyserver.sdss.org/dr1/en/help/browser/browser.asp)
	AND (g.value->>'i')::float4 BETWEEN 14.0 AND 21.0 -- Should be BETWEEN 15 AND 21
	AND (p.value->>'z')::float4 BETWEEN 0 AND 1; --{z1} and {z2}

-- (01.09%) select * from db_2003.specobjall where specobjid = {specobjid}
EXPLAIN (ANALYZE TRUE, COSTS FALSE, SUMMARY true)
SELECT s.key, s.value 
FROM SpecObjAll s 
WHERE s.key = 308580719209244670; --{specobjid}