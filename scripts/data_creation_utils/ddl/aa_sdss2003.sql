--
-- PostgreSQL database dump
--

-- Dumped from database version 15.3 (Ubuntu 15.3-1.pgdg18.04+1)
-- Dumped by pg_dump version 15.3 (Ubuntu 15.3-1.pgdg18.04+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: aa_sdss2003; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA aa_sdss2003;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: photoobjall; Type: TABLE; Schema: aa_sdss2003; Owner: -
--

CREATE TABLE aa_sdss2003.photoobjall (
    key bigint NOT NULL,
    value jsonb
);


--
-- Name: photoz; Type: TABLE; Schema: aa_sdss2003; Owner: -
--

CREATE TABLE aa_sdss2003.photoz (
    key bigint NOT NULL,
    value jsonb
);


--
-- Name: specobjall; Type: TABLE; Schema: aa_sdss2003; Owner: -
--

CREATE TABLE aa_sdss2003.specobjall (
    key double precision NOT NULL,
    value jsonb
);


--
-- Name: photoobjall photoobjall_pkey; Type: CONSTRAINT; Schema: aa_sdss2003; Owner: -
--

ALTER TABLE ONLY aa_sdss2003.photoobjall
    ADD CONSTRAINT photoobjall_pkey PRIMARY KEY (key);


--
-- Name: photoz photoz_pkey; Type: CONSTRAINT; Schema: aa_sdss2003; Owner: -
--

ALTER TABLE ONLY aa_sdss2003.photoz
    ADD CONSTRAINT photoz_pkey PRIMARY KEY (key);


--
-- Name: specobjall specobjall_pkey; Type: CONSTRAINT; Schema: aa_sdss2003; Owner: -
--

ALTER TABLE ONLY aa_sdss2003.specobjall
    ADD CONSTRAINT specobjall_pkey PRIMARY KEY (key);


--
-- Name: idx_photoobjall_ra_dec; Type: INDEX; Schema: aa_sdss2003; Owner: -
--

CREATE INDEX idx_photoobjall_ra_dec ON aa_sdss2003.photoobjall USING btree ((((value ->> 'ra'::text))::double precision), (((value ->> 'dec'::text))::double precision));


--
-- Name: idx_photoz_z; Type: INDEX; Schema: aa_sdss2003; Owner: -
--

CREATE INDEX idx_photoz_z ON aa_sdss2003.photoz USING btree ((((value ->> 'z'::text))::double precision));


--
-- Name: idx_specobjall_ra_dec; Type: INDEX; Schema: aa_sdss2003; Owner: -
--

CREATE INDEX idx_specobjall_ra_dec ON aa_sdss2003.specobjall USING btree ((((value ->> 'ra'::text))::double precision), (((value ->> 'dec'::text))::double precision));


--
-- Name: specobjall_bestobjid; Type: INDEX; Schema: aa_sdss2003; Owner: -
--

CREATE INDEX specobjall_bestobjid ON aa_sdss2003.specobjall USING btree ((((value ->> 'bestobjid'::text))::bigint));


--
-- PostgreSQL database dump complete
--

