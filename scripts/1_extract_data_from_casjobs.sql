-- 2023

-- top 10 cast(rand(ra)*1000000 as int) % 100

select distinct top 284555 p.objid, p.nMgyPerCount_z, cast(rand(p.nMgyPerCount_z)*100000000 as int) % 100000 as rnd 
into mydb.objids
from photoobjall p
join SpecObjAll s on s.bestobjid = p.objid
join platex pl on pl.plateid = s.plateid
join zoospec z on z.objid = p.objid
join galSpecIndx gsi on gsi.specobjid = s.specobjid
join galSpecExtra gse on gse.specobjid = s.specobjid
join DR8.photozrf zr on zr.objid = p.objid
join photoz pz on pz.objid = p.objid
order by cast(rand(p.nMgyPerCount_z)*100000000 as int) % 100000

SELECT db.objid, ROW_NUMBER() OVER (ORDER BY db.objid) AS RowNum into mydb.objid
FROM mydb.objids db

select p.* 
into mydb.PhotoObjAll 
from PhotoObjAll p
join mydb.objid db on db.objid = p.objid
WHERE db.RowNum > (100000*0) AND db.RowNum <= (100000*1)

select s.*
into mydb.SpecObjAll
from SpecObjAll s
join mydb.objid db on db.objid = s.bestobjid
WHERE db.RowNum > (10000*0) AND db.RowNum <= (10000*1)

select distinct pz.* 
into mydb.PhotoZ 
from PhotoZ pz
join mydb.objid db on db.objid = pz.objid

select distinct zr.* 
into mydb.PhotozRF 
from DR8.PhotozRF zr
join mydb.objid db on db.objid = zr.objid

select distinct z.* 
into mydb.ZooSpec 
from ZooSpec z
join mydb.objid db on db.objid = z.objid

select distinct pl.* 
into mydb.platex 
from platex pl
join SpecObjAll s on pl.plateid = s.plateid
join mydb.objid db on db.objid = s.bestobjid

select distinct gsi.* 
into mydb.GalSpecIndx 
from galSpecExtra gse 
join galSpecIndx gsi on gsi.specobjid = gse.specobjid
join SpecObjAll s on gsi.specobjid = s.specobjid
join mydb.objid db on db.objid = s.bestobjid

select distinct gse.* 
into mydb.GalSpecExtra 
from galSpecExtra gse 
join galSpecIndx gsi on gsi.specobjid = gse.specobjid
join SpecObjAll s on gsi.specobjid = s.specobjid
join mydb.objid db on db.objid = s.bestobjid

select distinct f.* 
into mydb.Field
from PhotoObjAll p
  join mydb.objid db on db.objid = p.objid
  join field f on f.fieldid = p.fieldid

select fieldID,zoom,run,rerun,camcol,field,stripe,strip,a,b,c,d,e,f,node,incl,raMin,raMax,decMin,decMax,mu,nu,ra,dec,cx,cy,cz into mydb.Frame
from (
  select distinct fr.* 
  from PhotoObjAll p
    join mydb.objid db on db.objid = p.objid
    join field f on f.fieldid = p.fieldid
    join frame fr on f.fieldid = fr.fieldid
) as x

select top 10 fr.img into mydb.fullframe from frame fr