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
-- Name: aa_sdss2023; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA aa_sdss2023;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: field; Type: TABLE; Schema: aa_sdss2023; Owner: -
--

CREATE TABLE aa_sdss2023.field (
    key bigint NOT NULL,
    value jsonb
);


--
-- Name: frame; Type: TABLE; Schema: aa_sdss2023; Owner: -
--

CREATE TABLE aa_sdss2023.frame (
    key1 bigint NOT NULL,
    key2 bigint NOT NULL,
    value jsonb
);


--
-- Name: galspecextra; Type: TABLE; Schema: aa_sdss2023; Owner: -
--

CREATE TABLE aa_sdss2023.galspecextra (
    key bigint NOT NULL,
    value jsonb
);


--
-- Name: galspecindx; Type: TABLE; Schema: aa_sdss2023; Owner: -
--

CREATE TABLE aa_sdss2023.galspecindx (
    key bigint NOT NULL,
    value jsonb
);


--
-- Name: photoobjall; Type: TABLE; Schema: aa_sdss2023; Owner: -
--

CREATE TABLE aa_sdss2023.photoobjall (
    key bigint NOT NULL,
    value jsonb
);


--
-- Name: photoz; Type: TABLE; Schema: aa_sdss2023; Owner: -
--

CREATE TABLE aa_sdss2023.photoz (
    key bigint NOT NULL,
    value jsonb
);


--
-- Name: photozrf; Type: TABLE; Schema: aa_sdss2023; Owner: -
--

CREATE TABLE aa_sdss2023.photozrf (
    key bigint NOT NULL,
    value jsonb
);


--
-- Name: platex; Type: TABLE; Schema: aa_sdss2023; Owner: -
--

CREATE TABLE aa_sdss2023.platex (
    key double precision NOT NULL,
    value jsonb
);


--
-- Name: specobjall; Type: TABLE; Schema: aa_sdss2023; Owner: -
--

CREATE TABLE aa_sdss2023.specobjall (
    key double precision NOT NULL,
    value jsonb
);


--
-- Name: field field_pkey; Type: CONSTRAINT; Schema: aa_sdss2023; Owner: -
--

ALTER TABLE ONLY aa_sdss2023.field
    ADD CONSTRAINT field_pkey PRIMARY KEY (key);


--
-- Name: frame frame_pkey; Type: CONSTRAINT; Schema: aa_sdss2023; Owner: -
--

ALTER TABLE ONLY aa_sdss2023.frame
    ADD CONSTRAINT frame_pkey PRIMARY KEY (key1, key2);


--
-- Name: galspecextra galspecextra_pkey; Type: CONSTRAINT; Schema: aa_sdss2023; Owner: -
--

ALTER TABLE ONLY aa_sdss2023.galspecextra
    ADD CONSTRAINT galspecextra_pkey PRIMARY KEY (key);


--
-- Name: galspecindx galspecindx_pkey; Type: CONSTRAINT; Schema: aa_sdss2023; Owner: -
--

ALTER TABLE ONLY aa_sdss2023.galspecindx
    ADD CONSTRAINT galspecindx_pkey PRIMARY KEY (key);


--
-- Name: photoobjall photoobjall_pkey; Type: CONSTRAINT; Schema: aa_sdss2023; Owner: -
--

ALTER TABLE ONLY aa_sdss2023.photoobjall
    ADD CONSTRAINT photoobjall_pkey PRIMARY KEY (key);


--
-- Name: photoz photoz_pkey; Type: CONSTRAINT; Schema: aa_sdss2023; Owner: -
--

ALTER TABLE ONLY aa_sdss2023.photoz
    ADD CONSTRAINT photoz_pkey PRIMARY KEY (key);


--
-- Name: photozrf photozrf_pkey; Type: CONSTRAINT; Schema: aa_sdss2023; Owner: -
--

ALTER TABLE ONLY aa_sdss2023.photozrf
    ADD CONSTRAINT photozrf_pkey PRIMARY KEY (key);


--
-- Name: platex platex_pkey; Type: CONSTRAINT; Schema: aa_sdss2023; Owner: -
--

ALTER TABLE ONLY aa_sdss2023.platex
    ADD CONSTRAINT platex_pkey PRIMARY KEY (key);


--
-- Name: specobjall specobjall_pkey; Type: CONSTRAINT; Schema: aa_sdss2023; Owner: -
--

ALTER TABLE ONLY aa_sdss2023.specobjall
    ADD CONSTRAINT specobjall_pkey PRIMARY KEY (key);


--
-- Name: idx_photoobjall_deredr; Type: INDEX; Schema: aa_sdss2023; Owner: -
--

CREATE INDEX idx_photoobjall_deredr ON aa_sdss2023.photoobjall USING btree ((((value ->> 'dered_r'::text))::double precision));


--
-- Name: idx_photoobjall_ra_dec; Type: INDEX; Schema: aa_sdss2023; Owner: -
--

CREATE INDEX idx_photoobjall_ra_dec ON aa_sdss2023.photoobjall USING btree ((((value ->> 'ra'::text))::double precision), (((value ->> 'dec'::text))::double precision));


--
-- Name: idx_photoz_z; Type: INDEX; Schema: aa_sdss2023; Owner: -
--

CREATE INDEX idx_photoz_z ON aa_sdss2023.photoz USING btree ((((value ->> 'z'::text))::double precision));


--
-- Name: idx_specobjall_bestobjid; Type: INDEX; Schema: aa_sdss2023; Owner: -
--

CREATE INDEX idx_specobjall_bestobjid ON aa_sdss2023.specobjall USING btree ((((value ->> 'bestobjid'::text))::bigint));


--
-- Name: idx_specobjall_plate; Type: INDEX; Schema: aa_sdss2023; Owner: -
--

CREATE INDEX idx_specobjall_plate ON aa_sdss2023.specobjall USING btree ((((value ->> 'plateid'::text))::double precision));


--
-- PostgreSQL database dump complete
--

