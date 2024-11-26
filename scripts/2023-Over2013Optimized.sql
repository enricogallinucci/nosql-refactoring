--========================================================= 2023 over 2013 Optimized ===============================================================================
SET search_path TO aa_SDSS2013_optimized, public;
SHOW search_path;

--********************************************************* New tables *********************************************************************
DROP TABLE IF EXISTS Platex;
CREATE TABLE Platex AS (
	SELECT p.plateid as key, -- This IS weird, because it IS float, NOT integer
    			(to_jsonb(p.*) - 'plateid') AS value 
	FROM sdss_relational2.Platex p
);
ALTER TABLE Platex ADD PRIMARY KEY (key);
ANALYZE Platex;

DROP TABLE IF EXISTS GalSpecExtra;
CREATE TABLE GalSpecExtra AS (
	SELECT g.specobjid as key,
    			(to_jsonb(g.*) - 'specobjid') AS value 
	FROM sdss_relational2.GalSpecExtra g
);
ALTER TABLE GalSpecExtra ADD PRIMARY KEY (key);
ANALYZE GalSpecExtra;

DROP TABLE IF EXISTS GalSpecIndx;
CREATE TABLE GalSpecIndx AS (
	SELECT g.specobjid as key,
    			(to_jsonb(g.*) - 'specobjid') AS value 
	FROM sdss_relational2.GalSpecIndx g
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


--*********************************************************** Queries *************************************************************************
-- (0.0793)	select p.objid, p.run, p.rerun, p.camcol, p.field, p.obj, p.type, p.ra, p.dec, p.u, p.g, p.r, p.i, p.z, p.err_u, p.err_g, p.err_r, p.err_i, p.err_z from db_2023.PhotoPrimary p where p.objid in ({objidlist})
EXPLAIN (ANALYZE TRUE, COSTS FALSE, SUMMARY true)
SELECT p.key, p.value->>'run', p.value->>'rerun', p.value->>'camcol', p.value->>'field', p.value->>'obj', p.value->>'type', p.value->>'ra', p.value->>'dec', p.value->>'u', p.value->>'g', p.value->>'r', p.value->>'i', p.value->>'z', p.value->>'err_u', p.value->>'err_g', p.value->>'err_r', p.value->>'err_i', p.value->>'err_z' 
FROM PhotoObjAll_Primary p 
WHERE p.key IN (1237645941824356443) --({objidlist})
UNION ALL
SELECT g.key, g.value->>'run', g.value->>'rerun', g.value->>'camcol', g.value->>'field', g.value->>'obj', g.value->>'type', g.value->>'ra', g.value->>'dec', g.value->>'u', g.value->>'g', g.value->>'r', g.value->>'i', g.value->>'z', g.value->>'err_u', g.value->>'err_g', g.value->>'err_r', g.value->>'err_i', g.value->>'err_z' 
FROM PhotoObjAll_Galaxy g 
	JOIN PhotoObjAll_GalaxyComplementary gc ON g.key=gc.key
WHERE (gc.value->>'mode')::int8=1
  AND g.key IN (1237645941824356443); --({objidlist})

-- (0.0616)	SELECT '<a target=info href=../../../en/tools/explore/obj.aspx?id=' || CAST(p.objid AS VARCHAR(20)) || '>' || CAST(p.objid AS VARCHAR(20)) || '</a>' AS objid, p.run, p.rerun, p.camcol, p.field, p.obj, p.type, p.ra, p.dec, p.u, p.g, p.r, p.i, p.z, p.err_u, p.err_g, p.err_r, p.err_i, p.err_z FROM db_2023.PhotoPrimary p WHERE p.objid IN ({objidlist}) LIMIT 1
EXPLAIN (ANALYZE TRUE, COSTS FALSE, SUMMARY true)
SELECT p.key, p.value->>'run', p.value->>'rerun', p.value->>'camcol', p.value->>'field', p.value->>'obj', p.value->>'type', p.value->>'ra', p.value->>'dec', p.value->>'u', p.value->>'g', p.value->>'r', p.value->>'i', p.value->>'z', p.value->>'err_u', p.value->>'err_g', p.value->>'err_r', p.value->>'err_i', p.value->>'err_z' 
FROM PhotoObjAll_Primary p 
WHERE p.key IN (1237645941824356443) --({objidlist})
UNION ALL
SELECT g.key, g.value->>'run', g.value->>'rerun', g.value->>'camcol', g.value->>'field', g.value->>'obj', g.value->>'type', g.value->>'ra', g.value->>'dec', g.value->>'u', g.value->>'g', g.value->>'r', g.value->>'i', g.value->>'z', g.value->>'err_u', g.value->>'err_g', g.value->>'err_r', g.value->>'err_i', g.value->>'err_z' 
FROM PhotoObjAll_Galaxy g 
	JOIN PhotoObjAll_GalaxyComplementary gc ON g.key=gc.key
WHERE (gc.value->>'mode')::int8=1
  AND g.key IN (1237645941824356443) --({objidlist})
LIMIT 1;

-- (0.0903)	SELECT TO_CHAR(p.ra, 'FM999999990.00000000') AS ra, TO_CHAR(p.dec, 'FM999999990.00000000') AS dec, p.dered_r, COALESCE(TO_CHAR(s.z, 'FM9990.0000'), '-9999') AS z, COALESCE(TO_CHAR(pz1.z, 'FM9990.0000'), '-9999') AS pzz1 FROM db_2023.galaxy AS p LEFT OUTER JOIN db_2023.specobj AS s ON s.bestobjid = p.objid LEFT OUTER JOIN db_2023.photoz AS pz1 ON pz1.objid = p.objid WHERE p.dered_r < {dered_r2} AND p.dered_r > {dered_r1} AND pz1.z < {z2} AND pz1.z > {z1} AND p.objid IN ({objidlist})
EXPLAIN (ANALYZE TRUE, COSTS FALSE, SUMMARY true)
SELECT ra, dec, dered_r, sz, pz
FROM (
	SELECT g.value->>'ra' AS ra, g.value->>'dec' AS dec, (gc.value->>'dered_r')::float8 AS dered_r, (s.value->>'z')::float8 AS sz, (g.value->'Photoz'->>'z')::float8 AS pz
	FROM PhotoObjAll_Galaxy as g 
	  JOIN PhotoObjAll_GalaxyComplementary gc ON g.key=gc.KEY
	  LEFT OUTER JOIN SpecObjAll AS s ON (s.value->>'bestobjid')::int8 = g.key
	WHERE g.key IN (1237645941824356443) --({objidlist})
	UNION ALL
	-- Galaxies that are primary objects
	SELECT g.value->>'ra' AS ra, g.value->>'dec' AS dec, (g.value->>'dered_r')::float8 AS dered_r, (s.value->>'z')::float8 AS sz, (p.value->>'z')::float8 AS pz
	FROM (
				SELECT  pp.KEY, pp.value||pc.value AS value
				FROM (SELECT * FROM PhotoObjAll_Primary WHERE key IN (1237645941824356443)) pp  --({objidlist})
					JOIN (SELECT * FROM PhotoObjAll_PrimaryComplementary WHERE key IN (1237645941824356443)) pc ON pp.KEY=pc.KEY --({objidlist})
				WHERE (pp.value->>'type')::int8=3 --AND (pc.value->>'type')::int8=3 --class='GALAXY' (see https://skyserver.sdss.org/dr1/en/help/browser/browser.asp)
					AND pp.key IN (1237645941824356443) --({objidlist})
				) as g 
		LEFT OUTER JOIN SpecObjAll s ON g.KEY=(s.value->>'bestobjid')::int8
		LEFT OUTER JOIN Photoz as p ON g.key=p.KEY
	) _
WHERE pz > 0 AND pz < 1 -- pz1.z < {z2} AND pz1.z > {z1}
	AND dered_r > 0 AND dered_r < 100 -- p.dered_r < {dered_r2} AND p.dered_r > {dered_r1}
;

-- (0.0767)	select s.specobjid, s.ra, s.dec from db_2023.specobj as s where s.ra between {ra1} and {ra2} and s.dec between {dec1} and {dec2}
EXPLAIN (ANALYZE TRUE, COSTS FALSE, SUMMARY true)
SELECT key, value->>'ra', value->>'dec' 
FROM SpecObjAll s
WHERE (value->>'ra')::float8 BETWEEN 100 AND 200 --{ra1} and {ra2} 
	AND (value->>'dec')::float8 BETWEEN -1 AND 1; -- {dec1} and {dec2}

-- (0.0142)	select * from db_2023.photoz where objid = {objid}
EXPLAIN (ANALYZE TRUE, COSTS FALSE, SUMMARY true)
SELECT key, value 
FROM (
	SELECT pc.key, pc.value||(g.value->'Photoz')::jsonb AS value
	FROM Photoz_Complementary pc 
	  JOIN PhotoObjAll_Galaxy g ON g.key=pc.key
	UNION ALL
	SELECT p.KEY, p.value
	FROM Photoz p
	) _
WHERE key=1237661064950973129; -- {objid}
	
-- (0.2185)	select * from db_2023.photoobjall where objid = {objid}
-- (0.1616)	select u, g, r, i, z, objID, type from db_2023.photoobjall where objid = {objid}
EXPLAIN (ANALYZE TRUE, COSTS FALSE, SUMMARY true)
SELECT key, value->>'u', value->>'g', value->>'r', value->>'i', value->>'z', value->>'type'
FROM (
	SELECT *
	FROM PhotoObjAll_Other
	UNION ALL
	SELECT p.key, p.value
	FROM PhotoObjAll_Primary p
	UNION ALL
	SELECT g.key, (g.value-ARRAY['Photoz','PhotozRF'])::jsonb||gc.value AS value
	FROM PhotoObjAll_Galaxy g
	  JOIN PhotoObjAll_GalaxyComplementary gc ON g.key=gc.key
	) _
WHERE key=1237648705671266616; --{objid}

-- (0.0453)	select p.ra, p.dec, p.clean, p.u, p.g, p.r, p.i, p.z from db_2023.photoobjall p where ((p.ra between {ra1} and {ra2}) and (p.dec between {dec1} and {dec2}))
EXPLAIN (ANALYZE TRUE, COSTS FALSE, SUMMARY true)
SELECT value->>'u', value->>'g', value->>'r', value->>'i', value->>'z', value->>'ra', value->>'dec', value->>'clean'
FROM (
	SELECT *
	FROM PhotoObjAll_Other
	UNION ALL
	SELECT p.KEY, p.value||pc.value
	FROM PhotoObjAll_Primary p
		JOIN PhotoObjAll_PrimaryComplementary pc ON p.KEY=pc.key
	UNION ALL
	SELECT g.KEY, (g.value-ARRAY['Photoz','PhotozRF'])::jsonb||gc.value AS value
	FROM PhotoObjAll_Galaxy g
	  JOIN PhotoObjAll_GalaxyComplementary gc ON g.KEY=gc.KEY
	) _
WHERE ((value->>'ra')::float8 BETWEEN 15 AND 20) --((p.ra between {ra1} and {ra2}) and
  AND ((value->>'dec')::float8 BETWEEN 15 AND 20);  -- (p.dec between {dec1} and {dec2}))

-- Next corresponds to two queries with very similar pattern
-- (0.076)	select p.objid, p.ra, p.dec, p.run, p.rerun, p.camcol, p.field, p.flags, p.psffwhm_z, p.psffwhm_i, p.psffwhm_r, p.psffwhm_g, p.psffwhm_u, p.expab_z, p.expab_i, p.expab_r, p.expab_g, p.expab_u, p.expphi_z, p.expphi_i, p.expphi_r, p.expphi_g, p.expphi_u, p.exprad_z, p.exprad_i, p.exprad_r, p.exprad_g, p.exprad_u, p.expflux_z, p.expflux_i, p.expflux_r, p.expflux_g, p.expflux_u, p.expmag_z, p.expmag_i, p.expmag_r, p.expmag_g, p.expmag_u, p.petrorad_z, p.petrorad_i, p.petrorad_r, p.petrorad_g, p.petrorad_u, p.petroflux_z, p.petroflux_i, p.petroflux_r, p.petroflux_g, p.petroflux_u, p.petromag_z, p.petromag_i, p.petromag_r, p.petromag_g, p.petromag_u, p.petromagerr_z, p.petromagerr_i, p.petromagerr_r, p.petromagerr_g, p.petromagerr_u, p.petror50_z, p.petror50_i, p.petror50_r, p.petror50_g, p.petror50_u, p.petror90_z, p.petror90_i, p.petror90_r, p.petror90_g, p.petror90_u, p.rowc_z, p.rowc_i, p.rowc_r, p.rowc_g, p.rowc_u, p.colc_z, p.colc_i, p.colc_r, p.colc_g, p.colc_u, p.rowcerr_z, p.rowcerr_i, p.rowcerr_r, p.rowcerr_g, p.rowcerr_u, p.colcerr_z, p.colcerr_i, p.colcerr_r, p.colcerr_g, p.colcerr_u, p.flags_z, p.flags_i, p.flags_r, p.flags_g, p.flags_u  from db_2023.photoobj as p where p.objid in ({objid})
-- (0.006)	select specobjid,ra,dec,u,g,r,i,z,type,devab_u,devab_g,devab_r,devab_i,devab_z,expab_u,expab_g,expab_r,expab_i,expab_z, lnlstar_u,lnlstar_g,lnlstar_r,lnlstar_i,lnlstar_z,lnldev_u,lnldev_g,lnldev_r,lnldev_i,lnldev_z,lnlexp_u,lnlexp_g,lnlexp_r, lnlexp_i,lnlexp_z,me2_u,me2_g,me2_r,me2_i,me2_z,me1_u,me1_g,me1_r,me1_i,me1_z,mrrcc_u,mrrcc_g,mrrcc_r,mrrcc_i,mrrcc_z,mcr4_u, mcr4_g,mcr4_r,mcr4_i,mcr4_z,fibermag_u,fibermag_g,fibermag_r,fibermag_i,fibermag_z,modelmag_u,modelmag_g,modelmag_r,modelmag_i, modelmag_z,petromag_u,petromag_g,petromag_r,petromag_i,petromag_z,petror50_u,petror50_g,petror50_r,petror50_i,petror50_z,petror90_u, petror90_g,petror90_r,petror90_i,petror90_z from db_2023.photoobj where objid = {objid}
EXPLAIN (ANALYZE TRUE, COSTS FALSE, SUMMARY true)
SELECT key, value
FROM (
	SELECT *
	FROM PhotoObjAll_Other
	UNION ALL
	SELECT p.KEY, p.value||pc.value
	FROM PhotoObjAll_Primary p
		JOIN PhotoObjAll_PrimaryComplementary pc ON p.KEY=pc.key
	UNION ALL
	SELECT g.KEY, (g.value-ARRAY['Photoz','PhotozRF'])::jsonb||gc.value AS value
	FROM PhotoObjAll_Galaxy g
	  JOIN PhotoObjAll_GalaxyComplementary gc ON g.KEY=gc.KEY
	) _
WHERE (value->>'mode')::int8 IN (1,2) -- primary and secondary objects (i.e., those in PhotoObj view, according to catalog)
	AND key IN (1237648705671266616);  -- p.objid in ({objid})
 

-- (0.0061)	select distinct p.ra, p.dec, p.objid, p.run, p.rerun, p.camcol, p.field, s.z, s.plate, s.mjd, s.fiberid, s.specobjid, s.run2d from db_2023.photoobjall as p join db_2023.specobjall s on p.objid = s.bestobjid where ((p.ra between {ra1} and {ra2}) and (p.dec between {dec1} and {dec2}))
EXPLAIN (ANALYZE TRUE, COSTS FALSE, SUMMARY true)
SELECT DISTINCT p.value->>'ra', p.value->>'dec', p.key, p.value->>'run', p.value->>'rerun', p.value->>'camcol', p.value->>'field', s.value->>'z', s.value->>'plate', s.value->>'mjd', s.value->>'fiberid', s.key, s.value->>'run2d'
FROM (
	SELECT *
	FROM PhotoObjAll_Other
	UNION ALL
	SELECT p.KEY, p.value
	FROM PhotoObjAll_Primary p
	UNION ALL
	SELECT g.KEY, (g.value-ARRAY['Photoz','PhotozRF'])::jsonb||gc.value AS value
	FROM PhotoObjAll_Galaxy g
	  JOIN PhotoObjAll_GalaxyComplementary gc ON g.KEY=gc.KEY
	) p
	JOIN SpecObjAll s ON p.key=(s.value->>'bestobjid')::int8
WHERE ((p.value->>'ra')::float8 BETWEEN 15 AND 20) --((p.ra between {ra1} and {ra2}) and
  AND ((p.value->>'dec')::float8 BETWEEN 15 AND 20);  -- (p.dec between {dec1} and {dec2}))
  
-- (0.0055)	select distinct s.run2d, s.plate, s.mjd, s.fiberid from db_2023.photoobjall as p join db_2023.specobjall s on p.objid = s.bestobjid where ((p.ra between {ra1} and {ra2}) and (p.dec between {dec1} and {dec2}))
EXPLAIN (ANALYZE TRUE, COSTS FALSE, SUMMARY true)
SELECT DISTINCT s.value->>'run2d', s.value->>'plate', s.value->>'mjd', s.value->>'fiberid'
FROM (
	SELECT *
	FROM PhotoObjAll_Other
	UNION ALL
	SELECT p.KEY, p.value
	FROM PhotoObjAll_Primary p
	UNION ALL
	SELECT g.KEY, (g.value-ARRAY['Photoz','PhotozRF'])::jsonb||gc.value AS value
	FROM PhotoObjAll_Galaxy g
	  JOIN PhotoObjAll_GalaxyComplementary gc ON g.KEY=gc.KEY
	) p
	JOIN SpecObjAll s ON p.key=(s.value->>'bestobjid')::int8
WHERE ((p.value->>'ra')::float8 BETWEEN 15 AND 20) --((p.ra between {ra1} and {ra2}) and
  AND ((p.value->>'dec')::float8 BETWEEN 15 AND 20);  -- (p.dec between {dec1} and {dec2}))

-- (0.0097)	select distinct s.run2d, s.plate, s.mjd, s.fiberid from db_2023.photoobjall as p join db_2023.specobjall s on p.objid = s.bestobjid where (s.plate={plate} and s.mjd={mjd} and s.fiberid={fiberid})
EXPLAIN (ANALYZE TRUE, COSTS FALSE, SUMMARY true)
SELECT DISTINCT s.value->>'run2d', s.value->>'plate', s.value->>'mjd', s.value->>'fiberid'
FROM (
	SELECT *
	FROM PhotoObjAll_Other
	UNION ALL
	SELECT p.KEY, p.value
	FROM PhotoObjAll_Primary p
	UNION ALL
	SELECT g.KEY, (g.value-ARRAY['Photoz','PhotozRF'])::jsonb||gc.value AS value
	FROM PhotoObjAll_Galaxy g
	  JOIN PhotoObjAll_GalaxyComplementary gc ON g.KEY=gc.KEY
	) p
	JOIN SpecObjAll s ON p.key=(s.value->>'bestobjid')::int8
WHERE (s.value->>'plate')::int8=422 
	AND (s.value->>'mjd')::int8=51811 
	AND (s.value->>'fiberid')::int8=390;  -- (s.plate={plate} and s.mjd={mjd} and s.fiberid={fiberid})

-- (0.0062)	select count(s.bestobjid) as count_returned_spec_phot from db_2023.photoobjall as p join db_2023.specobjall as s on s.bestobjid = p.objid join db_2023.platex as px on px.plateid = s.plateid where s.scienceprimary = 1 and s.ra between {ra1} and {ra2} and s.dec between {dec1} and {dec2}
EXPLAIN (ANALYZE TRUE, COSTS FALSE, SUMMARY true)
SELECT count(s.value->>'bestobjid')
FROM (
	SELECT *
	FROM PhotoObjAll_Other p
	WHERE ((p.value->>'ra')::float8 BETWEEN -1000 AND 1000) --((p.ra between {ra1} and {ra2}) and
		AND ((p.value->>'dec')::float8 BETWEEN -1000 AND 1000)  -- (p.dec between {dec1} and {dec2}))
	UNION ALL
	SELECT p.KEY, p.value
	FROM PhotoObjAll_Primary p
	WHERE ((p.value->>'ra')::float8 BETWEEN -1000 AND 1000) --((p.ra between {ra1} and {ra2}) and
		AND ((p.value->>'dec')::float8 BETWEEN -1000 AND 1000)  -- (p.dec between {dec1} and {dec2}))
	UNION ALL
	SELECT g.KEY, (g.value-ARRAY['Photoz','PhotozRF'])::jsonb||gc.value AS value
	FROM (
		SELECT * 
		FROM PhotoObjAll_Galaxy p 
		WHERE ((p.value->>'ra')::float8 BETWEEN -1000 AND 1000) --((p.ra between {ra1} and {ra2}) and
			AND ((p.value->>'dec')::float8 BETWEEN -1000 AND 1000)  -- (p.dec between {dec1} and {dec2}))
		) g
	  JOIN PhotoObjAll_GalaxyComplementary gc ON g.KEY=gc.KEY
	) ph
	JOIN SpecObjAll s ON ph.key=(s.value->>'bestobjid')::int8
  JOIN Platex pl ON pl.key=(s.value->>'plateid')::float8
WHERE (s.value->>'scienceprimary')::int8=1;
  	
-- (0.0061)	select s.instrument, s.bossspecobjid, px.seeing50, p.psffwhm_r, p.field, p.run, p.camcol, p.rowc_r, p.colc_r, p.rowc, p.colc, p.fracdev_r, p.devab_r, p.devphi_r, s.specobjid, s.bestobjid, p.objid, s.plate, s.fiberid, p.insidemask, p.flags, p.sky_r, p.petroflux_r, p.petrofluxivar_r, p.fiber2flux_r, p.petrorad_r, p.petroraderr_r, p.petror50_r, p.petror50err_r, p.petror90_r, p.petror90err_r, p.devrad_r, p.devraderr_r, p.devflux_r, p.devfluxivar_r, p.airmass_r, p.cloudcam_r, p.calibstatus_r, s.z, s.zerr, s.zwarning, s.class, s.z_noqso, s.zerr_noqso, s.zwarning_noqso, s.veldisp, s.veldisperr, s.veldispz, s.veldispzerr, s.veldispchi2, s.veldispnpix, s.veldispdof, s.snmedian_r, s.snmedian, s.chi68p, s.fracnsigma_1, s.fracnsighi_1, s.fracnsiglo_1, s.spectroflux_r, s.spectrosynflux_r, s.spectrofluxivar_r, s.spectrosynfluxivar_r, p.expflux_r, p.expab_r, p.exprad_r, p.expphi_r, p.psfflux_r from db_2023.photoobjall as p join db_2023.specobjall as s on s.bestobjid = p.objid join db_2023.platex as px on px.plateid = s.plateid where s.scienceprimary = 1 and s.ra between {ra1} and {ra2} and s.dec between {dec1} and {dec2} limit 1
EXPLAIN (ANALYZE TRUE, COSTS FALSE, SUMMARY true)
SELECT s.value->>'instrument', s.value->>'bossspecobjid', pl.value->>'seeing50', p.value->>'psffwhm_r', p.value->>'field', p.value->>'run', p.value->>'camcol', p.value->>'rowc_r', p.value->>'colc_r', p.value->>'rowc', p.value->>'colc', p.value->>'fracdev_r', p.value->>'devab_r', p.value->>'devphi_r', s.value->>'specobjid', s.value->>'bestobjid', p.value->>'objid', s.value->>'plate', s.value->>'fiberid', p.value->>'insidemask', p.value->>'flags', p.value->>'sky_r', p.value->>'petroflux_r', p.value->>'petrofluxivar_r', p.value->>'fiber2flux_r', p.value->>'petrorad_r', p.value->>'petroraderr_r', p.value->>'petror50_r', p.value->>'petror50err_r', p.value->>'petror90_r', p.value->>'petror90err_r', p.value->>'devrad_r', p.value->>'devraderr_r', p.value->>'devflux_r', p.value->>'devfluxivar_r', p.value->>'airmass_r', p.value->>'cloudcam_r', p.value->>'calibstatus_r', s.value->>'z', s.value->>'zerr', s.value->>'zwarning', s.value->>'class', s.value->>'z_noqso', s.value->>'zerr_noqso', s.value->>'zwarning_noqso', s.value->>'veldisp', s.value->>'veldisperr', s.value->>'veldispz', s.value->>'veldispzerr', s.value->>'veldispchi2', s.value->>'veldispnpix', s.value->>'veldispdof', s.value->>'snmedian_r', s.value->>'snmedian', s.value->>'chi68p', s.value->>'fracnsigma_1', s.value->>'fracnsighi_1', s.value->>'fracnsiglo_1', s.value->>'spectroflux_r', s.value->>'spectrosynflux_r', s.value->>'spectrofluxivar_r', s.value->>'spectrosynfluxivar_r', p.value->>'expflux_r', p.value->>'expab_r', p.value->>'exprad_r', p.value->>'expphi_r', p.value->>'psfflux_r'
FROM (
	SELECT *
	FROM PhotoObjAll_Other p
	WHERE ((p.value->>'ra')::float8 BETWEEN 15 AND 20) --((p.ra between {ra1} and {ra2}) and
		AND ((p.value->>'dec')::float8 BETWEEN 15 AND 20) -- (p.dec between {dec1} and {dec2}))
	UNION ALL
	SELECT p.KEY, p.value||pc.value AS value
	FROM (
		SELECT * 
		FROM PhotoObjAll_Primary p 
		WHERE ((p.value->>'ra')::float8 BETWEEN 15 AND 20) --((p.ra between {ra1} and {ra2}) and
			AND ((p.value->>'dec')::float8 BETWEEN 15 AND 20) ) p -- (p.dec between {dec1} and {dec2}))
		JOIN PhotoObjAll_PrimaryComplementary pc ON p.KEY=pc.key
	UNION ALL
	SELECT g.KEY, (g.value-ARRAY['Photoz','PhotozRF'])::jsonb||gc.value AS value
	FROM (
		SELECT * 
		FROM PhotoObjAll_Galaxy p 
		WHERE ((p.value->>'ra')::float8 BETWEEN 15 AND 20) --((p.ra between {ra1} and {ra2}) and
			AND ((p.value->>'dec')::float8 BETWEEN 15 AND 20)) g -- (p.dec between {dec1} and {dec2}))
	  JOIN PhotoObjAll_GalaxyComplementary gc ON g.KEY=gc.KEY
	) p
	JOIN SpecObjAll s ON p.key=(s.value->>'bestobjid')::int8
  JOIN Platex pl ON pl.key=(s.value->>'plateid')::float8
WHERE (s.value->>'scienceprimary')::int8=1
LIMIT 1;

-- (0.0162)	select r.run, r.rerun, r.camcol, r.field, f.fieldid, r.stripe, r.strip, r.ra, r.dec, r.ramin, r.ramax, r.decmin, r.decmax, r.mu, r.nu, r.incl, r.node, r.a, r.b, r.c, r.d, r.e, r.f, f.quality, f.a_u, f.b_u, f.c_u, f.d_u, f.e_u, f.f_u, f.a_g, f.b_g, f.c_g, f.d_g, f.e_g, f.f_g, f.a_r, f.b_r, f.c_r, f.d_r, f.e_r, f.f_r, f.a_i, f.b_i, f.c_i, f.d_i, f.e_i, f.f_i, f.a_z, f.b_z, f.c_z, f.d_z, f.e_z, f.f_z, f.fieldid from db_2023.frame r, db_2023.field f where f.fieldid=r.fieldid and r.fieldid in ({fieldidlist}) and r.zoom=0
EXPLAIN (ANALYZE TRUE, COSTS FALSE, SUMMARY true)
SELECT fr.key1, fr.key2, fr.value||fi.value
FROM Field fi
  JOIN Frame fr ON fi.key=fr.key1
WHERE fr.key1 IN (1237645878493773824) --({fieldidlist}) 
  and fr.key2=0;

-- (0.0769)	select s.specobjid, s.z, gsi.tauv_cont, gse.lgm_tot_p16, gse.lgm_tot_p50, gse.lgm_tot_p84, gse.specsfr_tot_p16, gse.specsfr_tot_p50, gse.specsfr_tot_p84 from db_2023.specobjall as s join db_2023.galspecindx as gsi on s.specobjid=gsi.specobjid join db_2023.galspecextra as gse on s.specobjid=gse.specobjid where s.specobjid in ({specobjid})
EXPLAIN (ANALYZE TRUE, COSTS FALSE, SUMMARY true)
SELECT s.key, s.value->>'z', gsi.value->>'tauv_cont', gse.value->>'lgm_tot_p16', gse.value->>'lgm_tot_p50', gse.value->>'lgm_tot_p84', gse.value->>'specsfr_tot_p16', gse.value->>'specsfr_tot_p50', gse.value->>'specsfr_tot_p84'
FROM SpecObjAll s
	JOIN galspecindx gsi ON s.key=gsi.key 
	JOIN galspecextra gse ON s.key=gse.key 
WHERE s.key IN (299494075021682688); -- ({specobjid}) 

-- NOT NEEDED
-- (0.0187)	SELECT p.specobjid, p.ra, p.dec, p.u, p.g, p.r, p.i, p.z, p.type, p.devab_u, p.devab_g, p.devab_r, p.devab_i, p.devab_z, p.expab_u, p.expab_g, p.expab_r, p.expab_i, p.expab_z, p.lnlstar_u, p.lnlstar_g, p.lnlstar_r, p.lnlstar_i, p.lnlstar_z, p.lnldev_u, p.lnldev_g, p.lnldev_r, p.lnldev_i, p.lnldev_z, p.lnlexp_u, p.lnlexp_g, p.lnlexp_r, p.lnlexp_i, p.lnlexp_z, p.me2_u, p.me2_g, p.me2_r, p.me2_i, p.me2_z, p.me1_u, p.me1_g, p.me1_r, p.me1_i, p.me1_z, p.mrrcc_u, p.mrrcc_g, p.mrrcc_r, p.mrrcc_i, p.mrrcc_z, p.mcr4_u, p.mcr4_g, p.mcr4_r, p.mcr4_i, p.mcr4_z, p.fibermag_u, p.fibermag_g, p.fibermag_r, p.fibermag_i, p.fibermag_z, p.modelmag_u, p.modelmag_g, p.modelmag_r, p.modelmag_i, p.modelmag_z, p.petromag_u, p.petromag_g, p.petromag_r, p.petromag_i, p.petromag_z, p.petror50_u, p.petror50_g, p.petror50_r, p.petror50_i, p.petror50_z, p.petror90_u, p.petror90_g, p.petror90_r, p.petror90_i, p.petror90_z, zs.nvote, zs.p_el as elliptical, zs.p_cw as spiralclock, zs.p_acw as spiralanticlock, zs.p_edge as edgeon, zs.p_mg as merger FROM db_2023_ns.PhotoObjAll AS p JOIN db_2023_ns.zoospec AS zs ON p.objID = zs.objid WHERE p.objID = {objid};