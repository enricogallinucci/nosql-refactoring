alter table sdss_relational.frame add column img bytea;

update sdss_relational.frame set img = (select img from db_2023.frame limit 1);