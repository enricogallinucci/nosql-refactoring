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
-- Name: aa_sdss2023_optimized; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA aa_sdss2023_optimized;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: field_other; Type: TABLE; Schema: aa_sdss2023_optimized; Owner: -
--

CREATE TABLE aa_sdss2023_optimized.field_other (
    key bigint NOT NULL,
    value jsonb
);


--
-- Name: frame_0; Type: TABLE; Schema: aa_sdss2023_optimized; Owner: -
--

CREATE TABLE aa_sdss2023_optimized.frame_0 (
    key1 bigint NOT NULL,
    key2 bigint NOT NULL,
    value jsonb
);


--
-- Name: frame_other; Type: TABLE; Schema: aa_sdss2023_optimized; Owner: -
--

CREATE TABLE aa_sdss2023_optimized.frame_other (
    key1 bigint NOT NULL,
    key2 bigint NOT NULL,
    value jsonb
);


--
-- Name: galspecextra; Type: TABLE; Schema: aa_sdss2023_optimized; Owner: -
--

CREATE TABLE aa_sdss2023_optimized.galspecextra (
    key bigint NOT NULL,
    value jsonb
);


--
-- Name: galspecindx; Type: TABLE; Schema: aa_sdss2023_optimized; Owner: -
--

CREATE TABLE aa_sdss2023_optimized.galspecindx (
    key bigint NOT NULL,
    value jsonb
);


--
-- Name: photoobjall_galaxy; Type: TABLE; Schema: aa_sdss2023_optimized; Owner: -
--

CREATE TABLE aa_sdss2023_optimized.photoobjall_galaxy (
    key bigint NOT NULL,
    value jsonb
);


--
-- Name: photoobjall_galaxycomplementary; Type: TABLE; Schema: aa_sdss2023_optimized; Owner: -
--

CREATE TABLE aa_sdss2023_optimized.photoobjall_galaxycomplementary (
    key bigint NOT NULL,
    value jsonb
);


--
-- Name: photoobjall_other; Type: TABLE; Schema: aa_sdss2023_optimized; Owner: -
--

CREATE TABLE aa_sdss2023_optimized.photoobjall_other (
    key bigint NOT NULL,
    value jsonb
);


--
-- Name: photoobjall_primary; Type: TABLE; Schema: aa_sdss2023_optimized; Owner: -
--

CREATE TABLE aa_sdss2023_optimized.photoobjall_primary (
    key bigint NOT NULL,
    value jsonb
);


--
-- Name: photoobjall_primarycomplementary; Type: TABLE; Schema: aa_sdss2023_optimized; Owner: -
--

CREATE TABLE aa_sdss2023_optimized.photoobjall_primarycomplementary (
    key bigint NOT NULL,
    value jsonb
);


--
-- Name: photoz; Type: TABLE; Schema: aa_sdss2023_optimized; Owner: -
--

CREATE TABLE aa_sdss2023_optimized.photoz (
    key bigint NOT NULL,
    value jsonb
);


--
-- Name: photozcomplementary; Type: TABLE; Schema: aa_sdss2023_optimized; Owner: -
--

CREATE TABLE aa_sdss2023_optimized.photozcomplementary (
    key bigint NOT NULL,
    value jsonb
);


--
-- Name: platex; Type: TABLE; Schema: aa_sdss2023_optimized; Owner: -
--

CREATE TABLE aa_sdss2023_optimized.platex (
    key double precision NOT NULL,
    value jsonb
);


--
-- Name: specobjall; Type: TABLE; Schema: aa_sdss2023_optimized; Owner: -
--

CREATE TABLE aa_sdss2023_optimized.specobjall (
    key double precision NOT NULL,
    value jsonb
);


--
-- Name: specobjallcomplementary; Type: TABLE; Schema: aa_sdss2023_optimized; Owner: -
--

CREATE TABLE aa_sdss2023_optimized.specobjallcomplementary (
    key double precision NOT NULL,
    value jsonb
);


--
-- Name: field_other field_other_pkey; Type: CONSTRAINT; Schema: aa_sdss2023_optimized; Owner: -
--

ALTER TABLE ONLY aa_sdss2023_optimized.field_other
    ADD CONSTRAINT field_other_pkey PRIMARY KEY (key);


--
-- Name: frame_0 frame_0_pkey; Type: CONSTRAINT; Schema: aa_sdss2023_optimized; Owner: -
--

ALTER TABLE ONLY aa_sdss2023_optimized.frame_0
    ADD CONSTRAINT frame_0_pkey PRIMARY KEY (key1, key2);


--
-- Name: frame_other frame_other_pkey; Type: CONSTRAINT; Schema: aa_sdss2023_optimized; Owner: -
--

ALTER TABLE ONLY aa_sdss2023_optimized.frame_other
    ADD CONSTRAINT frame_other_pkey PRIMARY KEY (key1, key2);


--
-- Name: galspecextra galspecextra_pkey; Type: CONSTRAINT; Schema: aa_sdss2023_optimized; Owner: -
--

ALTER TABLE ONLY aa_sdss2023_optimized.galspecextra
    ADD CONSTRAINT galspecextra_pkey PRIMARY KEY (key);


--
-- Name: galspecindx galspecindx_pkey; Type: CONSTRAINT; Schema: aa_sdss2023_optimized; Owner: -
--

ALTER TABLE ONLY aa_sdss2023_optimized.galspecindx
    ADD CONSTRAINT galspecindx_pkey PRIMARY KEY (key);


--
-- Name: photoobjall_galaxy photoobjall_galaxy_pkey; Type: CONSTRAINT; Schema: aa_sdss2023_optimized; Owner: -
--

ALTER TABLE ONLY aa_sdss2023_optimized.photoobjall_galaxy
    ADD CONSTRAINT photoobjall_galaxy_pkey PRIMARY KEY (key);


--
-- Name: photoobjall_galaxycomplementary photoobjall_galaxycomplementary_pkey; Type: CONSTRAINT; Schema: aa_sdss2023_optimized; Owner: -
--

ALTER TABLE ONLY aa_sdss2023_optimized.photoobjall_galaxycomplementary
    ADD CONSTRAINT photoobjall_galaxycomplementary_pkey PRIMARY KEY (key);


--
-- Name: photoobjall_other photoobjall_other_pkey; Type: CONSTRAINT; Schema: aa_sdss2023_optimized; Owner: -
--

ALTER TABLE ONLY aa_sdss2023_optimized.photoobjall_other
    ADD CONSTRAINT photoobjall_other_pkey PRIMARY KEY (key);


--
-- Name: photoobjall_primary photoobjall_primary_pkey; Type: CONSTRAINT; Schema: aa_sdss2023_optimized; Owner: -
--

ALTER TABLE ONLY aa_sdss2023_optimized.photoobjall_primary
    ADD CONSTRAINT photoobjall_primary_pkey PRIMARY KEY (key);


--
-- Name: photoobjall_primarycomplementary photoobjall_primarycomplementary_pkey; Type: CONSTRAINT; Schema: aa_sdss2023_optimized; Owner: -
--

ALTER TABLE ONLY aa_sdss2023_optimized.photoobjall_primarycomplementary
    ADD CONSTRAINT photoobjall_primarycomplementary_pkey PRIMARY KEY (key);


--
-- Name: photoz photoz_pkey; Type: CONSTRAINT; Schema: aa_sdss2023_optimized; Owner: -
--

ALTER TABLE ONLY aa_sdss2023_optimized.photoz
    ADD CONSTRAINT photoz_pkey PRIMARY KEY (key);


--
-- Name: photozcomplementary photozcomplementary_pkey; Type: CONSTRAINT; Schema: aa_sdss2023_optimized; Owner: -
--

ALTER TABLE ONLY aa_sdss2023_optimized.photozcomplementary
    ADD CONSTRAINT photozcomplementary_pkey PRIMARY KEY (key);


--
-- Name: platex platex_pkey; Type: CONSTRAINT; Schema: aa_sdss2023_optimized; Owner: -
--

ALTER TABLE ONLY aa_sdss2023_optimized.platex
    ADD CONSTRAINT platex_pkey PRIMARY KEY (key);


--
-- Name: specobjall specobjall_pkey; Type: CONSTRAINT; Schema: aa_sdss2023_optimized; Owner: -
--

ALTER TABLE ONLY aa_sdss2023_optimized.specobjall
    ADD CONSTRAINT specobjall_pkey PRIMARY KEY (key);


--
-- Name: specobjallcomplementary specobjallcomplementary_pkey; Type: CONSTRAINT; Schema: aa_sdss2023_optimized; Owner: -
--

ALTER TABLE ONLY aa_sdss2023_optimized.specobjallcomplementary
    ADD CONSTRAINT specobjallcomplementary_pkey PRIMARY KEY (key);


--
-- Name: idx_photoobjall_other_ra_dec; Type: INDEX; Schema: aa_sdss2023_optimized; Owner: -
--

CREATE INDEX idx_photoobjall_other_ra_dec ON aa_sdss2023_optimized.photoobjall_other USING btree ((((value ->> 'ra'::text))::double precision), (((value ->> 'dec'::text))::double precision));


--
-- Name: idx_specobjall_bestobjid; Type: INDEX; Schema: aa_sdss2023_optimized; Owner: -
--

CREATE INDEX idx_specobjall_bestobjid ON aa_sdss2023_optimized.specobjall USING btree ((((value ->> 'bestobjid'::text))::bigint));


--
-- Name: idx_specobjall_plateid; Type: INDEX; Schema: aa_sdss2023_optimized; Owner: -
--

CREATE INDEX idx_specobjall_plateid ON aa_sdss2023_optimized.specobjall USING btree ((((value ->> 'plateid'::text))::double precision));


--
-- Name: idx_specobjall_ra_dec; Type: INDEX; Schema: aa_sdss2023_optimized; Owner: -
--

CREATE INDEX idx_specobjall_ra_dec ON aa_sdss2023_optimized.specobjall USING btree ((((value ->> 'ra'::text))::double precision), (((value ->> 'dec'::text))::double precision));


--
-- PostgreSQL database dump complete
--

