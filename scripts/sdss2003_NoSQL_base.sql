
create schema sdss2003;

CREATE TABLE sdss2003.PhotoObjAll (
    key BIGINT PRIMARY KEY,
    value JSONB
);

INSERT INTO sdss2003.PhotoObjAll (key, value)
SELECT 
    p.objid as key,
    (to_jsonb(p) - 'objid')  AS value
FROM 
    sdss_relational.photoobjall AS p ;


CREATE INDEX idx_PhotoObjAll_ra_dec ON sdss2003.PhotoObjAll(
    CAST(value->'ra' AS FLOAT),
    CAST(value->'dec' AS FLOAT)
);


CREATE TABLE sdss2003.SpecObjAll (
    key DOUBLE PRECISION NOT NULL PRIMARY KEY,
    value JSONB
);

INSERT INTO sdss2003.SpecObjAll (key, value)
SELECT 
    s.specObjID as key,
    (to_jsonb(s) - 'specObjID')  AS value
FROM 
    sdss_relational.SpecObjAll AS s; 

CREATE INDEX idx_SpecObjAll_ra_dec ON sdss2003.SpecObjAll(
    CAST(value->'ra' AS FLOAT),
    CAST(value->'dec' AS FLOAT)
);

CREATE INDEX idx_SpecObjAll_bid ON sdss2003.SpecObjAll(
    CAST(value->'bestobjid' AS BIGINT)
);

CREATE TABLE sdss2003.Photoz as   
SELECT
    p.objid as key,
    (to_jsonb(p) - 'objid') AS value
FROM 
    sdss_relational.photoz p;

ALTER TABLE sdss2003.Photoz ADD CONSTRAINT pk_Photoz PRIMARY KEY (key);



CREATE INDEX idx_Photoz_z ON sdss2003.Photoz(
    CAST(value->'z' AS float)
);