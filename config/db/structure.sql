--
-- PostgreSQL database dump
--


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

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: absolute_identifiers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.absolute_identifiers (
    id bigint NOT NULL,
    barcode character varying,
    batch_id bigint,
    batch_type character varying DEFAULT 'Batch'::character varying,
    created_at timestamp(6) without time zone NOT NULL,
    holding_cache jsonb,
    holding_id character varying,
    original_box_number integer,
    pool_identifier character varying,
    prefix character varying,
    suffix integer,
    sync_status character varying,
    top_container_uri character varying,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: absolute_identifiers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.absolute_identifiers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: absolute_identifiers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.absolute_identifiers_id_seq OWNED BY public.absolute_identifiers.id;


--
-- Name: batches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.batches (
    id bigint NOT NULL,
    call_number character varying,
    container_profile_data jsonb,
    container_profile_uri character varying,
    created_at timestamp(6) without time zone NOT NULL,
    end_box integer,
    first_barcode character varying,
    generate_abid boolean DEFAULT true,
    location_data jsonb,
    location_uri character varying,
    resource_uri character varying,
    start_box integer,
    updated_at timestamp(6) without time zone NOT NULL,
    user_id bigint
);


--
-- Name: batches_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.batches_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: batches_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.batches_id_seq OWNED BY public.batches.id;


--
-- Name: marc_batches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.marc_batches (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    ignore_size_validation boolean DEFAULT false,
    updated_at timestamp(6) without time zone NOT NULL,
    user_id bigint NOT NULL
);


--
-- Name: marc_batches_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.marc_batches_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: marc_batches_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.marc_batches_id_seq OWNED BY public.marc_batches.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    filename text NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    aspace_uri character varying,
    created_at timestamp(6) without time zone NOT NULL,
    provider character varying DEFAULT 'cas'::character varying NOT NULL,
    remember_created_at timestamp without time zone,
    uid character varying NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: absolute_identifiers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.absolute_identifiers ALTER COLUMN id SET DEFAULT nextval('public.absolute_identifiers_id_seq'::regclass);


--
-- Name: batches id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.batches ALTER COLUMN id SET DEFAULT nextval('public.batches_id_seq'::regclass);


--
-- Name: marc_batches id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marc_batches ALTER COLUMN id SET DEFAULT nextval('public.marc_batches_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: absolute_identifiers absolute_identifiers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.absolute_identifiers
    ADD CONSTRAINT absolute_identifiers_pkey PRIMARY KEY (id);


--
-- Name: batches batches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.batches
    ADD CONSTRAINT batches_pkey PRIMARY KEY (id);


--
-- Name: marc_batches marc_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marc_batches
    ADD CONSTRAINT marc_batches_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (filename);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: absolute_identifiers_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX absolute_identifiers_uniqueness ON public.absolute_identifiers USING btree (prefix, suffix, pool_identifier);


--
-- Name: index_absolute_identifiers_on_batch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_absolute_identifiers_on_batch_id ON public.absolute_identifiers USING btree (batch_id);


--
-- Name: index_batches_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_batches_on_user_id ON public.batches USING btree (user_id);


--
-- Name: index_marc_batches_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_marc_batches_on_user_id ON public.marc_batches USING btree (user_id);


--
-- Name: index_users_on_provider; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_provider ON public.users USING btree (provider);


--
-- Name: index_users_on_uid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_uid ON public.users USING btree (uid);


--
-- Name: index_users_on_uid_and_provider; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_uid_and_provider ON public.users USING btree (uid, provider);


--
-- Name: marc_batches fk_rails_5bd1f9ffcf; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marc_batches
    ADD CONSTRAINT fk_rails_5bd1f9ffcf FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: batches fk_rails_ae06cb64ba; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.batches
    ADD CONSTRAINT fk_rails_ae06cb64ba FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- PostgreSQL database dump complete
--
SET search_path TO "$user", public;

INSERT INTO schema_migrations (filename) VALUES
('20240216174259_baseline_schema.rb');
