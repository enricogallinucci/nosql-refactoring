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
-- Name: aa_sdss2013; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA aa_sdss2013;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: field; Type: TABLE; Schema: aa_sdss2013; Owner: -
--

CREATE TABLE aa_sdss2013.field (
    key bigint NOT NULL,
    value jsonb
);


--
-- Name: frame; Type: TABLE; Schema: aa_sdss2013; Owner: -
--

CREATE TABLE aa_sdss2013.frame (
    key1 bigint NOT NULL,
    key2 bigint NOT NULL,
    value jsonb
);


--
-- Name: galspecindx; Type: TABLE; Schema: aa_sdss2013; Owner: -
--

CREATE TABLE aa_sdss2013.galspecindx (
    key bigint NOT NULL,
    value jsonb
);


--
-- Name: photoobjall; Type: TABLE; Schema: aa_sdss2013; Owner: -
--

CREATE TABLE aa_sdss2013.photoobjall (
    key bigint NOT NULL,
    value jsonb
);


--
-- Name: photoz; Type: TABLE; Schema: aa_sdss2013; Owner: -
--

CREATE TABLE aa_sdss2013.photoz (
    key bigint NOT NULL,
    value jsonb
);


--
-- Name: photozrf; Type: TABLE; Schema: aa_sdss2013; Owner: -
--

CREATE TABLE aa_sdss2013.photozrf (
    key bigint NOT NULL,
    value jsonb
);


--
-- Name: specobjall; Type: TABLE; Schema: aa_sdss2013; Owner: -
--

CREATE TABLE aa_sdss2013.specobjall (
    key double precision NOT NULL,
    value jsonb
);


--
-- Name: field field_pkey; Type: CONSTRAINT; Schema: aa_sdss2013; Owner: -
--

ALTER TABLE ONLY aa_sdss2013.field
    ADD CONSTRAINT field_pkey PRIMARY KEY (key);


--
-- Name: frame frame_pkey; Type: CONSTRAINT; Schema: aa_sdss2013; Owner: -
--

ALTER TABLE ONLY aa_sdss2013.frame
    ADD CONSTRAINT frame_pkey PRIMARY KEY (key1, key2);


--
-- Name: galspecindx galspecindx_pkey; Type: CONSTRAINT; Schema: aa_sdss2013; Owner: -
--

ALTER TABLE ONLY aa_sdss2013.galspecindx
    ADD CONSTRAINT galspecindx_pkey PRIMARY KEY (key);


--
-- Name: photoobjall photoobjall_pkey; Type: CONSTRAINT; Schema: aa_sdss2013; Owner: -
--

ALTER TABLE ONLY aa_sdss2013.photoobjall
    ADD CONSTRAINT photoobjall_pkey PRIMARY KEY (key);


--
-- Name: photoz photoz_pkey; Type: CONSTRAINT; Schema: aa_sdss2013; Owner: -
--

ALTER TABLE ONLY aa_sdss2013.photoz
    ADD CONSTRAINT photoz_pkey PRIMARY KEY (key);


--
-- Name: photozrf photozrf_pkey; Type: CONSTRAINT; Schema: aa_sdss2013; Owner: -
--

ALTER TABLE ONLY aa_sdss2013.photozrf
    ADD CONSTRAINT photozrf_pkey PRIMARY KEY (key);


--
-- Name: specobjall specobjall_pkey; Type: CONSTRAINT; Schema: aa_sdss2013; Owner: -
--

ALTER TABLE ONLY aa_sdss2013.specobjall
    ADD CONSTRAINT specobjall_pkey PRIMARY KEY (key);


--
-- PostgreSQL database dump complete
--

