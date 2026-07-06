--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Extensions
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;

--
-- Types
--

CREATE TYPE public.attendance_status AS ENUM (
    'PRESENT',
    'ABSENT',
    'MANUAL_OVERRIDE'
);

CREATE TYPE public.audit_action AS ENUM (
    'LOGIN',
    'LOGOUT',
    'VIEW_ATTENDANCE',
    'EXPORT_REPORT',
    'CREATE_SESSION',
    'END_SESSION',
    'OVERRIDE_ATTENDANCE',
    'CREATE_EMBEDDING',
    'UPDATE_EMBEDDING',
    'DELETE_EMBEDDING',
    'CREATE_STUDENT',
    'DELETE_STUDENT',
    'CREATE_USER',
    'UPDATE_USER',
    'DELETE_USER',
    'CREATE_CLASS',
    'UPDATE_CLASS',
    'DELETE_CLASS',
    'ACTIVATE_USER',
    'DEACTIVATE_USER',
    'RESET_PASSWORD',
    'VIEW_BENCHMARK',
    'RUN_BENCHMARK',
    'UPDATE_STUDENT'
);

CREATE TYPE public.benchmark_scenario AS ENUM (
    'CONTROLLED',
    'CLASSROOM',
    'ADVERSE'
);

CREATE TYPE public.face_angle AS ENUM (
    'FRONTAL',
    'SLIGHT',
    'PROFILE'
);

CREATE TYPE public.lighting_condition AS ENUM (
    'BRIGHT',
    'NORMAL',
    'DIM',
    'BACKLIGHT'
);

CREATE TYPE public.model_name AS ENUM (
    'facenet',
    'arcface',
    'insightface',
    'dlib',
    'mobilefacenet'
);

CREATE TYPE public.occlusion_type AS ENUM (
    'NONE',
    'MASK',
    'GLASSES',
    'PARTIAL'
);

CREATE TYPE public.user_role AS ENUM (
    'ADMIN',
    'LECTURER',
    'RESEARCHER'
);

--
-- Function
--

CREATE FUNCTION public.fn_set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

SET default_tablespace = '';
SET default_table_access_method = heap;

--
-- Tables
--

CREATE TABLE public.attendance_records (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    session_id uuid NOT NULL,
    student_id uuid NOT NULL,
    status public.attendance_status DEFAULT 'ABSENT'::public.attendance_status NOT NULL,
    confidence double precision,
    detected_at timestamp with time zone DEFAULT now() NOT NULL,
    overridden_by uuid,
    override_reason text,
    CONSTRAINT attendance_records_confidence_check CHECK (((confidence IS NULL) OR ((confidence >= (0)::double precision) AND (confidence <= (1)::double precision)))),
    CONSTRAINT chk_override CHECK ((((status = 'MANUAL_OVERRIDE'::public.attendance_status) AND (overridden_by IS NOT NULL) AND (override_reason IS NOT NULL)) OR (status <> 'MANUAL_OVERRIDE'::public.attendance_status)))
);

CREATE TABLE public.audit_logs (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    actor_id uuid,
    action public.audit_action NOT NULL,
    target_table character varying(50),
    target_id uuid,
    old_value jsonb,
    new_value jsonb,
    ip_address character varying(45),
    user_agent character varying(255),
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE public.benchmark_results (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    session_id uuid,
    model_name public.model_name NOT NULL,
    scenario public.benchmark_scenario NOT NULL,
    threshold double precision NOT NULL,
    accuracy double precision,
    "precision" double precision,
    recall double precision,
    f1_score double precision,
    far double precision,
    frr double precision,
    eer double precision,
    avg_latency double precision,
    fps double precision,
    sample_count integer,
    recorded_at timestamp with time zone DEFAULT now() NOT NULL,
    lighting_condition public.lighting_condition,
    face_angle public.face_angle,
    occlusion public.occlusion_type,
    distance_cm integer,
    notes text,
    CONSTRAINT benchmark_results_accuracy_check CHECK (((accuracy IS NULL) OR ((accuracy >= (0)::double precision) AND (accuracy <= (1)::double precision)))),
    CONSTRAINT benchmark_results_avg_latency_check CHECK (((avg_latency IS NULL) OR (avg_latency > (0)::double precision))),
    CONSTRAINT benchmark_results_eer_check CHECK (((eer IS NULL) OR ((eer >= (0)::double precision) AND (eer <= (1)::double precision)))),
    CONSTRAINT benchmark_results_f1_score_check CHECK (((f1_score IS NULL) OR ((f1_score >= (0)::double precision) AND (f1_score <= (1)::double precision)))),
    CONSTRAINT benchmark_results_far_check CHECK (((far IS NULL) OR ((far >= (0)::double precision) AND (far <= (1)::double precision)))),
    CONSTRAINT benchmark_results_fps_check CHECK (((fps IS NULL) OR (fps > (0)::double precision))),
    CONSTRAINT benchmark_results_frr_check CHECK (((frr IS NULL) OR ((frr >= (0)::double precision) AND (frr <= (1)::double precision)))),
    CONSTRAINT benchmark_results_precision_check CHECK ((("precision" IS NULL) OR (("precision" >= (0)::double precision) AND ("precision" <= (1)::double precision)))),
    CONSTRAINT benchmark_results_recall_check CHECK (((recall IS NULL) OR ((recall >= (0)::double precision) AND (recall <= (1)::double precision)))),
    CONSTRAINT benchmark_results_sample_count_check CHECK (((sample_count IS NULL) OR (sample_count > 0))),
    CONSTRAINT benchmark_results_threshold_check CHECK (((threshold >= (0)::double precision) AND (threshold <= (1)::double precision)))
);

CREATE TABLE public.class_enrollments (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    student_id uuid NOT NULL,
    class_id uuid NOT NULL,
    enrolled_at timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE public.class_sessions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    class_id uuid NOT NULL,
    created_by uuid NOT NULL,
    started_at timestamp with time zone DEFAULT now() NOT NULL,
    ended_at timestamp with time zone,
    notes text,
    CONSTRAINT chk_class_session_time CHECK (((ended_at IS NULL) OR (ended_at > started_at)))
);

CREATE TABLE public.classes (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    class_code character varying(20) NOT NULL,
    subject_name character varying(100) NOT NULL,
    lecturer_id uuid NOT NULL,
    academic_year smallint NOT NULL,
    term smallint NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT classes_academic_year_check CHECK ((academic_year >= 2000)),
    CONSTRAINT classes_term_check CHECK (((term >= 1) AND (term <= 3)))
);

CREATE TABLE public.face_embeddings (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    student_id uuid NOT NULL,
    embedding bytea NOT NULL,
    model_name public.model_name NOT NULL,
    embedding_dim smallint NOT NULL,
    is_valid boolean DEFAULT true NOT NULL,
    created_by uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE public.students (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    research_id character varying(20) NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    enrolled_at timestamp with time zone DEFAULT now() NOT NULL,
    full_name character varying(100),
    student_code character varying(20),
    email character varying(100)
);

CREATE TABLE public.user_sessions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    refresh_token_hash character varying(255) NOT NULL,
    ip_address character varying(45),
    user_agent character varying(255),
    is_revoked boolean DEFAULT false NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    last_used_at timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE public.users (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    username character varying(50) NOT NULL,
    password_hash character varying(255) NOT NULL,
    full_name character varying(100),
    email character varying(100),
    role public.user_role DEFAULT 'LECTURER'::public.user_role NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    last_login_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

--
-- Primary keys / unique constraints
--

ALTER TABLE ONLY public.attendance_records
    ADD CONSTRAINT attendance_records_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.attendance_records
    ADD CONSTRAINT attendance_records_session_id_student_id_key UNIQUE (session_id, student_id);

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.benchmark_results
    ADD CONSTRAINT benchmark_results_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.class_enrollments
    ADD CONSTRAINT class_enrollments_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.class_enrollments
    ADD CONSTRAINT class_enrollments_student_id_class_id_key UNIQUE (student_id, class_id);

ALTER TABLE ONLY public.class_sessions
    ADD CONSTRAINT class_sessions_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.classes
    ADD CONSTRAINT classes_class_code_key UNIQUE (class_code);

ALTER TABLE ONLY public.classes
    ADD CONSTRAINT classes_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.face_embeddings
    ADD CONSTRAINT face_embeddings_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_email_key UNIQUE (email);

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_research_id_key UNIQUE (research_id);

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_student_code_key UNIQUE (student_code);

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT user_sessions_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);

--
-- Indexes
--

CREATE INDEX idx_attendance_session ON public.attendance_records USING btree (session_id);
CREATE INDEX idx_attendance_status ON public.attendance_records USING btree (status);
CREATE INDEX idx_attendance_student ON public.attendance_records USING btree (student_id);
CREATE INDEX idx_audit_actor ON public.audit_logs USING btree (actor_id);
CREATE INDEX idx_audit_created_at ON public.audit_logs USING btree (created_at DESC);
CREATE INDEX idx_audit_target ON public.audit_logs USING btree (target_table, target_id);
CREATE INDEX idx_benchmark_model_scenario ON public.benchmark_results USING btree (model_name, scenario);
CREATE INDEX idx_class_sessions_class ON public.class_sessions USING btree (class_id);
CREATE INDEX idx_class_sessions_created ON public.class_sessions USING btree (created_by);
CREATE INDEX idx_classes_lecturer ON public.classes USING btree (lecturer_id);
CREATE UNIQUE INDEX idx_embeddings_active_student ON public.face_embeddings USING btree (student_id) WHERE (is_valid = true);
CREATE INDEX idx_enrollments_class ON public.class_enrollments USING btree (class_id);
CREATE INDEX idx_enrollments_student ON public.class_enrollments USING btree (student_id);
CREATE INDEX idx_user_sessions_expires ON public.user_sessions USING btree (expires_at);
CREATE INDEX idx_user_sessions_user ON public.user_sessions USING btree (user_id);

--
-- Triggers
--

CREATE TRIGGER trg_embeddings_updated_at BEFORE UPDATE ON public.face_embeddings FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();
CREATE TRIGGER trg_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();

--
-- Foreign keys
--

ALTER TABLE ONLY public.attendance_records
    ADD CONSTRAINT attendance_records_overridden_by_fkey FOREIGN KEY (overridden_by) REFERENCES public.users(id);

ALTER TABLE ONLY public.attendance_records
    ADD CONSTRAINT attendance_records_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.class_sessions(id) ON DELETE RESTRICT;

ALTER TABLE ONLY public.attendance_records
    ADD CONSTRAINT attendance_records_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE RESTRICT;

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_actor_id_fkey FOREIGN KEY (actor_id) REFERENCES public.users(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.benchmark_results
    ADD CONSTRAINT benchmark_results_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.class_sessions(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.class_enrollments
    ADD CONSTRAINT class_enrollments_class_id_fkey FOREIGN KEY (class_id) REFERENCES public.classes(id) ON DELETE RESTRICT;

ALTER TABLE ONLY public.class_enrollments
    ADD CONSTRAINT class_enrollments_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE RESTRICT;

ALTER TABLE ONLY public.class_sessions
    ADD CONSTRAINT class_sessions_class_id_fkey FOREIGN KEY (class_id) REFERENCES public.classes(id) ON DELETE RESTRICT;

ALTER TABLE ONLY public.class_sessions
    ADD CONSTRAINT class_sessions_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE RESTRICT;

ALTER TABLE ONLY public.classes
    ADD CONSTRAINT classes_lecturer_id_fkey FOREIGN KEY (lecturer_id) REFERENCES public.users(id) ON DELETE RESTRICT;

ALTER TABLE ONLY public.face_embeddings
    ADD CONSTRAINT face_embeddings_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE RESTRICT;

ALTER TABLE ONLY public.face_embeddings
    ADD CONSTRAINT face_embeddings_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT user_sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

--
-- PostgreSQL database dump complete
--