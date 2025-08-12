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
-- Name: aa_sdss2013_optimized; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA aa_sdss2013_optimized;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: field; Type: TABLE; Schema: aa_sdss2013_optimized; Owner: -
--

CREATE TABLE aa_sdss2013_optimized.field (
    key bigint NOT NULL,
    value jsonb
);


--
-- Name: frame; Type: TABLE; Schema: aa_sdss2013_optimized; Owner: -
--

CREATE TABLE aa_sdss2013_optimized.frame (
    key1 bigint NOT NULL,
    key2 bigint NOT NULL,
    value jsonb
);


--
-- Name: galspecextra; Type: TABLE; Schema: aa_sdss2013_optimized; Owner: -
--

CREATE TABLE aa_sdss2013_optimized.galspecextra (
    key bigint NOT NULL,
    value jsonb
);


--
-- Name: galspecindx; Type: TABLE; Schema: aa_sdss2013_optimized; Owner: -
--

CREATE TABLE aa_sdss2013_optimized.galspecindx (
    key bigint NOT NULL,
    value jsonb
);


--
-- Name: photoobjall_galaxy; Type: TABLE; Schema: aa_sdss2013_optimized; Owner: -
--

CREATE TABLE aa_sdss2013_optimized.photoobjall_galaxy (
    key bigint NOT NULL,
    value jsonb
);


--
-- Name: photoobjall_galaxycomplementary; Type: TABLE; Schema: aa_sdss2013_optimized; Owner: -
--

CREATE TABLE aa_sdss2013_optimized.photoobjall_galaxycomplementary (
    key bigint NOT NULL,
    value jsonb
);


--
-- Name: photoobjall_other; Type: TABLE; Schema: aa_sdss2013_optimized; Owner: -
--

CREATE TABLE aa_sdss2013_optimized.photoobjall_other (
    key bigint NOT NULL,
    value jsonb
);


--
-- Name: photoobjall_primary; Type: TABLE; Schema: aa_sdss2013_optimized; Owner: -
--

CREATE TABLE aa_sdss2013_optimized.photoobjall_primary (
    key bigint NOT NULL,
    value jsonb
);


--
-- Name: photoobjall_primarycomplementary; Type: TABLE; Schema: aa_sdss2013_optimized; Owner: -
--

CREATE TABLE aa_sdss2013_optimized.photoobjall_primarycomplementary (
    key bigint NOT NULL,
    value jsonb
);


--
-- Name: photoz; Type: TABLE; Schema: aa_sdss2013_optimized; Owner: -
--

CREATE TABLE aa_sdss2013_optimized.photoz (
    key bigint NOT NULL,
    value jsonb
);


--
-- Name: photoz_complementary; Type: TABLE; Schema: aa_sdss2013_optimized; Owner: -
--

CREATE TABLE aa_sdss2013_optimized.photoz_complementary (
    key bigint NOT NULL,
    value jsonb
);


--
-- Name: photozrf; Type: TABLE; Schema: aa_sdss2013_optimized; Owner: -
--

CREATE TABLE aa_sdss2013_optimized.photozrf (
    key bigint NOT NULL,
    value jsonb
);


--
-- Name: photozrf_complementary; Type: TABLE; Schema: aa_sdss2013_optimized; Owner: -
--

CREATE TABLE aa_sdss2013_optimized.photozrf_complementary (
    key bigint NOT NULL,
    value jsonb
);


--
-- Name: platex; Type: TABLE; Schema: aa_sdss2013_optimized; Owner: -
--

CREATE TABLE aa_sdss2013_optimized.platex (
    key double precision NOT NULL,
    value jsonb
);


--
-- Name: specobjall; Type: TABLE; Schema: aa_sdss2013_optimized; Owner: -
--

CREATE TABLE aa_sdss2013_optimized.specobjall (
    key double precision NOT NULL,
    value jsonb
);


--
-- Name: field field_pkey; Type: CONSTRAINT; Schema: aa_sdss2013_optimized; Owner: -
--

ALTER TABLE ONLY aa_sdss2013_optimized.field
    ADD CONSTRAINT field_pkey PRIMARY KEY (key);


--
-- Name: frame frame_pkey; Type: CONSTRAINT; Schema: aa_sdss2013_optimized; Owner: -
--

ALTER TABLE ONLY aa_sdss2013_optimized.frame
    ADD CONSTRAINT frame_pkey PRIMARY KEY (key1, key2);


--
-- Name: galspecextra galspecextra_pkey; Type: CONSTRAINT; Schema: aa_sdss2013_optimized; Owner: -
--

ALTER TABLE ONLY aa_sdss2013_optimized.galspecextra
    ADD CONSTRAINT galspecextra_pkey PRIMARY KEY (key);


--
-- Name: galspecindx galspecindx_pkey; Type: CONSTRAINT; Schema: aa_sdss2013_optimized; Owner: -
--

ALTER TABLE ONLY aa_sdss2013_optimized.galspecindx
    ADD CONSTRAINT galspecindx_pkey PRIMARY KEY (key);


--
-- Name: photoobjall_galaxy photoobjall_galaxy_pkey; Type: CONSTRAINT; Schema: aa_sdss2013_optimized; Owner: -
--

ALTER TABLE ONLY aa_sdss2013_optimized.photoobjall_galaxy
    ADD CONSTRAINT photoobjall_galaxy_pkey PRIMARY KEY (key);


--
-- Name: photoobjall_galaxycomplementary photoobjall_galaxycomplementary_pkey; Type: CONSTRAINT; Schema: aa_sdss2013_optimized; Owner: -
--

ALTER TABLE ONLY aa_sdss2013_optimized.photoobjall_galaxycomplementary
    ADD CONSTRAINT photoobjall_galaxycomplementary_pkey PRIMARY KEY (key);


--
-- Name: photoobjall_other photoobjall_other_pkey; Type: CONSTRAINT; Schema: aa_sdss2013_optimized; Owner: -
--

ALTER TABLE ONLY aa_sdss2013_optimized.photoobjall_other
    ADD CONSTRAINT photoobjall_other_pkey PRIMARY KEY (key);


--
-- Name: photoobjall_primary photoobjall_primary_pkey; Type: CONSTRAINT; Schema: aa_sdss2013_optimized; Owner: -
--

ALTER TABLE ONLY aa_sdss2013_optimized.photoobjall_primary
    ADD CONSTRAINT photoobjall_primary_pkey PRIMARY KEY (key);


--
-- Name: photoobjall_primarycomplementary photoobjall_primarycomplementary_pkey; Type: CONSTRAINT; Schema: aa_sdss2013_optimized; Owner: -
--

ALTER TABLE ONLY aa_sdss2013_optimized.photoobjall_primarycomplementary
    ADD CONSTRAINT photoobjall_primarycomplementary_pkey PRIMARY KEY (key);


--
-- Name: photoz_complementary photoz_complementary_pkey; Type: CONSTRAINT; Schema: aa_sdss2013_optimized; Owner: -
--

ALTER TABLE ONLY aa_sdss2013_optimized.photoz_complementary
    ADD CONSTRAINT photoz_complementary_pkey PRIMARY KEY (key);


--
-- Name: photoz photoz_pkey; Type: CONSTRAINT; Schema: aa_sdss2013_optimized; Owner: -
--

ALTER TABLE ONLY aa_sdss2013_optimized.photoz
    ADD CONSTRAINT photoz_pkey PRIMARY KEY (key);


--
-- Name: photozrf_complementary photozrf_complementary_pkey; Type: CONSTRAINT; Schema: aa_sdss2013_optimized; Owner: -
--

ALTER TABLE ONLY aa_sdss2013_optimized.photozrf_complementary
    ADD CONSTRAINT photozrf_complementary_pkey PRIMARY KEY (key);


--
-- Name: photozrf photozrf_pkey; Type: CONSTRAINT; Schema: aa_sdss2013_optimized; Owner: -
--

ALTER TABLE ONLY aa_sdss2013_optimized.photozrf
    ADD CONSTRAINT photozrf_pkey PRIMARY KEY (key);


--
-- Name: platex platex_pkey; Type: CONSTRAINT; Schema: aa_sdss2013_optimized; Owner: -
--

ALTER TABLE ONLY aa_sdss2013_optimized.platex
    ADD CONSTRAINT platex_pkey PRIMARY KEY (key);


--
-- Name: specobjall specobjall_pkey; Type: CONSTRAINT; Schema: aa_sdss2013_optimized; Owner: -
--

ALTER TABLE ONLY aa_sdss2013_optimized.specobjall
    ADD CONSTRAINT specobjall_pkey PRIMARY KEY (key);


--
-- Name: idx_photoobjall_galaxy_ra_dec; Type: INDEX; Schema: aa_sdss2013_optimized; Owner: -
--

CREATE INDEX idx_photoobjall_galaxy_ra_dec ON aa_sdss2013_optimized.photoobjall_galaxy USING btree ((((value ->> 'ra'::text))::double precision), (((value ->> 'dec'::text))::double precision));


--
-- Name: idx_photoobjall_galaxycomplementary_deredr; Type: INDEX; Schema: aa_sdss2013_optimized; Owner: -
--

CREATE INDEX idx_photoobjall_galaxycomplementary_deredr ON aa_sdss2013_optimized.photoobjall_galaxycomplementary USING btree ((((value ->> 'dered_r'::text))::double precision));


--
-- Name: idx_photoobjall_primary_ra_dec; Type: INDEX; Schema: aa_sdss2013_optimized; Owner: -
--

CREATE INDEX idx_photoobjall_primary_ra_dec ON aa_sdss2013_optimized.photoobjall_primary USING btree ((((value ->> 'ra'::text))::double precision), (((value ->> 'dec'::text))::double precision));


--
-- Name: idx_photoobjall_primarycomplementary_deredr; Type: INDEX; Schema: aa_sdss2013_optimized; Owner: -
--

CREATE INDEX idx_photoobjall_primarycomplementary_deredr ON aa_sdss2013_optimized.photoobjall_primarycomplementary USING btree ((((value ->> 'dered_r'::text))::double precision));


--
-- Name: idx_photoz_z; Type: INDEX; Schema: aa_sdss2013_optimized; Owner: -
--

CREATE INDEX idx_photoz_z ON aa_sdss2013_optimized.photoz USING btree ((((value ->> 'z'::text))::double precision));


--
-- Name: idx_specobjall_bestobjid; Type: INDEX; Schema: aa_sdss2013_optimized; Owner: -
--

CREATE INDEX idx_specobjall_bestobjid ON aa_sdss2013_optimized.specobjall USING btree ((((value ->> 'bestobjid'::text))::bigint));


--
-- Name: idx_specobjall_plate; Type: INDEX; Schema: aa_sdss2013_optimized; Owner: -
--

CREATE INDEX idx_specobjall_plate ON aa_sdss2013_optimized.specobjall USING btree ((((value ->> 'plateid'::text))::double precision));


--
-- PostgreSQL database dump complete
--

