CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TYPE user_role AS ENUM ('ADMIN', 'LECTURER', 'RESEARCHER');
CREATE TYPE attendance_status AS ENUM ('PRESENT', 'ABSENT', 'MANUAL_OVERRIDE');
CREATE TYPE benchmark_scenario AS ENUM ('CONTROLLED', 'CLASSROOM', 'ADVERSE');
CREATE TYPE model_name AS ENUM ('facenet', 'arcface', 'insightface', 'dlib', 'mobilefacenet');
CREATE TYPE audit_action AS ENUM (
  'LOGIN', 'LOGOUT',
  'VIEW_ATTENDANCE', 'EXPORT_REPORT',
  'CREATE_SESSION', 'END_SESSION',
  'OVERRIDE_ATTENDANCE',
  'CREATE_EMBEDDING', 'UPDATE_EMBEDDING', 'DELETE_EMBEDDING',
  'CREATE_STUDENT', 'DELETE_STUDENT',
  'CREATE_USER', 'UPDATE_USER', 'DELETE_USER',
  'CREATE_CLASS', 'UPDATE_CLASS', 'DELETE_CLASS',
  'ACTIVATE_USER', 'DEACTIVATE_USER', 'RESET_PASSWORD',
  'VIEW_BENCHMARK', 'RUN_BENCHMARK'
);

CREATE TABLE users (
  id            UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
  username      VARCHAR(50)  UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  full_name     VARCHAR(100),
  email         VARCHAR(100) UNIQUE,
  role          user_role    NOT NULL DEFAULT 'LECTURER',
  is_active     BOOLEAN      NOT NULL DEFAULT true,
  last_login_at TIMESTAMPTZ,
  created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE user_sessions (
  id                 UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id            UUID         NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  refresh_token_hash VARCHAR(255) NOT NULL,
  ip_address         INET,
  user_agent         VARCHAR(255),
  is_revoked         BOOLEAN      NOT NULL DEFAULT false,
  expires_at         TIMESTAMPTZ  NOT NULL,
  created_at         TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  last_used_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE classes (
  id            UUID     PRIMARY KEY DEFAULT uuid_generate_v4(),
  class_code    VARCHAR(20)  UNIQUE NOT NULL,
  subject_name  VARCHAR(100) NOT NULL,
  lecturer_id   UUID         NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  academic_year SMALLINT     NOT NULL CHECK (academic_year >= 2000),
  term          SMALLINT     NOT NULL CHECK (term BETWEEN 1 AND 3),
  is_active     BOOLEAN      NOT NULL DEFAULT true,
  created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE students (
  id          UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  research_id VARCHAR(20) UNIQUE NOT NULL,
  is_active   BOOLEAN     NOT NULL DEFAULT true,
  enrolled_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE class_enrollments (
  id          UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  student_id  UUID        NOT NULL REFERENCES students(id) ON DELETE RESTRICT,
  class_id    UUID        NOT NULL REFERENCES classes(id)  ON DELETE RESTRICT,
  enrolled_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE (student_id, class_id)
);

CREATE TABLE class_sessions (
  id          UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  class_id    UUID        NOT NULL REFERENCES classes(id) ON DELETE RESTRICT,
  created_by  UUID        NOT NULL REFERENCES users(id)   ON DELETE RESTRICT,
  started_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ended_at    TIMESTAMPTZ,
  notes       TEXT,

  CONSTRAINT chk_class_session_time CHECK (ended_at IS NULL OR ended_at > started_at)
);

CREATE TABLE attendance_records (
  id              UUID              PRIMARY KEY DEFAULT uuid_generate_v4(),
  session_id      UUID              NOT NULL REFERENCES class_sessions(id) ON DELETE RESTRICT,
  student_id      UUID              NOT NULL REFERENCES students(id)        ON DELETE RESTRICT,
  status          attendance_status NOT NULL DEFAULT 'ABSENT',
  confidence      FLOAT             CHECK (confidence IS NULL OR confidence BETWEEN 0 AND 1),
  detected_at     TIMESTAMPTZ       NOT NULL DEFAULT NOW(),
  overridden_by   UUID              REFERENCES users(id),
  override_reason TEXT,

  UNIQUE (session_id, student_id),

  CONSTRAINT chk_override CHECK (
    (status = 'MANUAL_OVERRIDE' AND overridden_by IS NOT NULL AND override_reason IS NOT NULL)
    OR status != 'MANUAL_OVERRIDE'
  )
);

CREATE TABLE face_embeddings (
  id            UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  student_id    UUID        NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  embedding     BYTEA       NOT NULL,
  model_name    model_name  NOT NULL,
  embedding_dim SMALLINT    NOT NULL,
  is_valid      BOOLEAN     NOT NULL DEFAULT true,
  created_by    UUID        NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE audit_logs (
  id           UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
  actor_id     UUID         REFERENCES users(id) ON DELETE SET NULL,
  action       audit_action NOT NULL,
  target_table VARCHAR(50),
  target_id    UUID,
  old_value    JSONB,
  new_value    JSONB,
  ip_address   INET,
  user_agent   VARCHAR(255),
  created_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE benchmark_results (
  id           UUID               PRIMARY KEY DEFAULT uuid_generate_v4(),
  session_id   UUID               REFERENCES class_sessions(id) ON DELETE SET NULL,
  model_name   model_name         NOT NULL,
  scenario     benchmark_scenario NOT NULL,
  threshold    FLOAT              NOT NULL CHECK (threshold BETWEEN 0 AND 1),
  accuracy     FLOAT              CHECK (accuracy  IS NULL OR accuracy  BETWEEN 0 AND 1),
  precision    FLOAT              CHECK (precision IS NULL OR precision BETWEEN 0 AND 1),
  recall       FLOAT              CHECK (recall    IS NULL OR recall    BETWEEN 0 AND 1),
  f1_score     FLOAT              CHECK (f1_score  IS NULL OR f1_score  BETWEEN 0 AND 1),
  far          FLOAT              CHECK (far       IS NULL OR far       BETWEEN 0 AND 1),
  frr          FLOAT              CHECK (frr       IS NULL OR frr       BETWEEN 0 AND 1),
  eer          FLOAT              CHECK (eer       IS NULL OR eer       BETWEEN 0 AND 1),
  avg_latency  FLOAT              CHECK (avg_latency IS NULL OR avg_latency > 0),
  fps          FLOAT              CHECK (fps         IS NULL OR fps         > 0),
  sample_count INT                CHECK (sample_count IS NULL OR sample_count > 0),
  recorded_at  TIMESTAMPTZ        NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_user_sessions_user       ON user_sessions(user_id);
CREATE INDEX idx_user_sessions_expires    ON user_sessions(expires_at);
CREATE INDEX idx_classes_lecturer         ON classes(lecturer_id);
CREATE INDEX idx_enrollments_student      ON class_enrollments(student_id);
CREATE INDEX idx_enrollments_class        ON class_enrollments(class_id);
CREATE INDEX idx_class_sessions_class     ON class_sessions(class_id);
CREATE INDEX idx_class_sessions_created   ON class_sessions(created_by);
CREATE INDEX idx_attendance_session       ON attendance_records(session_id);
CREATE INDEX idx_attendance_student       ON attendance_records(student_id);
CREATE INDEX idx_attendance_status        ON attendance_records(status);
CREATE INDEX idx_audit_actor              ON audit_logs(actor_id);
CREATE INDEX idx_audit_created_at         ON audit_logs(created_at DESC);
CREATE INDEX idx_audit_target             ON audit_logs(target_table, target_id);
CREATE INDEX idx_benchmark_model_scenario ON benchmark_results(model_name, scenario);

CREATE UNIQUE INDEX idx_embeddings_active_student
  ON face_embeddings(student_id) WHERE is_valid = true;

CREATE OR REPLACE FUNCTION fn_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_embeddings_updated_at
  BEFORE UPDATE ON face_embeddings
  FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

INSERT INTO users (username, password_hash, full_name, role)
VALUES ('admin', crypt('admin123', gen_salt('bf', 12)), 'System Admin', 'ADMIN');