alter table sdss_relational.frame add column img bytea;

update sdss_relational.frame set img = (select img from db_2023.frame limit 1);

alter table sdss_relational2.platex add column plateidnew double precision;

update sdss_relational2.platex set plateidnew = cast(plateid as double precision);

alter table sdss_relational2.platex drop column plateid;

alter table sdss_relational2.platex rename column plateidnew to plateid;