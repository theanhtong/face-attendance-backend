-- =============================================================
-- SEED DATA — face-attendance-backend
-- Docker init script (runs after schema)
-- =============================================================

-- -------------------------------------------------------------
-- 1. USERS — 1 admin
-- -------------------------------------------------------------
INSERT INTO public.users (username, password_hash, full_name, email, role, is_active)
VALUES (
    'admin',
    crypt('Admin123!', gen_salt('bf', 10)),
    'System Administrator',
    'admin@faceattend.local',
    'ADMIN',
    true
);

-- -------------------------------------------------------------
-- 2. STUDENTS — 6 sinh viên, cover active/inactive edge case
-- -------------------------------------------------------------
INSERT INTO public.students (research_id, full_name, student_code, email, is_active)
VALUES
    ('RID-2024-001', 'Nguyễn Văn An',   'SV2024001', 'an.nguyen@student.edu.vn',   true),
    ('RID-2024-002', 'Trần Thị Bình',   'SV2024002', 'binh.tran@student.edu.vn',   true),
    ('RID-2024-003', 'Lê Hoàng Cường',  'SV2024003', 'cuong.le@student.edu.vn',    true),
    ('RID-2024-004', 'Phạm Thị Dung',   'SV2024004', 'dung.pham@student.edu.vn',   true),
    ('RID-2024-005', 'Hoàng Minh Đức',  'SV2024005', 'duc.hoang@student.edu.vn',   true),
    ('RID-2024-006', 'Vũ Thị Hoa',      'SV2024006', 'hoa.vu@student.edu.vn',      false); -- inactive edge case

-- -------------------------------------------------------------
-- 3. FACE EMBEDDINGS
--    - mock bytea 512 bytes (arcface/facenet dim=128, 4 bytes/float)
--    - SV2024006 is_valid=false vì student inactive
-- -------------------------------------------------------------
INSERT INTO public.face_embeddings (student_id, embedding, model_name, embedding_dim, is_valid, created_by)
SELECT
    s.id,
    gen_random_bytes(512),
    CASE WHEN s.student_code IN ('SV2024001','SV2024002','SV2024003') THEN 'arcface' ELSE 'facenet' END::public.model_name,
    128,
    s.is_active,          -- is_valid khớp với is_active của student
    (SELECT id FROM public.users WHERE username = 'admin')
FROM public.students s;

-- -------------------------------------------------------------
-- 4. CLASSES — 2 lớp do admin tạm giữ vai lecturer
-- -------------------------------------------------------------
INSERT INTO public.classes (class_code, subject_name, lecturer_id, academic_year, term, is_active)
SELECT 'CS101-01', 'Nhập môn Lập trình', id, 2024, 1, true  FROM public.users WHERE username = 'admin'
UNION ALL
SELECT 'CS202-01', 'Cơ sở Dữ liệu',      id, 2024, 1, true  FROM public.users WHERE username = 'admin';

-- -------------------------------------------------------------
-- 5. CLASS ENROLLMENTS — 5 SV active enroll vào cả 2 lớp
--    SV2024006 bị bỏ qua do inactive
-- -------------------------------------------------------------
INSERT INTO public.class_enrollments (student_id, class_id)
SELECT s.id, c.id
FROM public.students s
CROSS JOIN public.classes c
WHERE s.is_active = true;

-- -------------------------------------------------------------
-- 6. CLASS SESSIONS — mỗi lớp 2 buổi: 1 đã kết thúc, 1 đang mở
-- -------------------------------------------------------------
INSERT INTO public.class_sessions (class_id, created_by, started_at, ended_at, notes)
SELECT
    c.id,
    (SELECT id FROM public.users WHERE username = 'admin'),
    now() - interval '7 days',
    now() - interval '7 days' + interval '90 minutes',
    'Buổi 1 — đã kết thúc'
FROM public.classes c
UNION ALL
SELECT
    c.id,
    (SELECT id FROM public.users WHERE username = 'admin'),
    now() - interval '1 hour',
    NULL,   -- đang mở, chưa kết thúc
    'Buổi 2 — đang diễn ra'
FROM public.classes c;

-- -------------------------------------------------------------
-- 7. ATTENDANCE RECORDS
--    Buổi đã kết thúc: mix PRESENT / ABSENT / MANUAL_OVERRIDE
--    Buổi đang mở:     chỉ PRESENT (chưa chốt)
-- -------------------------------------------------------------

-- Buổi đã kết thúc (ended_at IS NOT NULL)
INSERT INTO public.attendance_records (session_id, student_id, status, confidence, overridden_by, override_reason)
SELECT
    cs.id,
    s.id,
    CASE ROW_NUMBER() OVER (PARTITION BY cs.id ORDER BY s.student_code)
        WHEN 1 THEN 'PRESENT'
        WHEN 2 THEN 'PRESENT'
        WHEN 3 THEN 'ABSENT'
        WHEN 4 THEN 'MANUAL_OVERRIDE'
        ELSE        'PRESENT'
    END::public.attendance_status,
    CASE ROW_NUMBER() OVER (PARTITION BY cs.id ORDER BY s.student_code)
        WHEN 3 THEN NULL          -- ABSENT không có confidence
        WHEN 4 THEN NULL          -- MANUAL_OVERRIDE không cần
        ELSE ROUND((0.75 + RANDOM() * 0.24)::numeric, 4)::double precision
    END,
    CASE ROW_NUMBER() OVER (PARTITION BY cs.id ORDER BY s.student_code)
        WHEN 4 THEN (SELECT id FROM public.users WHERE username = 'admin')
        ELSE NULL
    END,
    CASE ROW_NUMBER() OVER (PARTITION BY cs.id ORDER BY s.student_code)
        WHEN 4 THEN 'Sinh viên có mặt nhưng khuôn mặt bị che khuất'
        ELSE NULL
    END
FROM public.class_sessions cs
JOIN public.class_enrollments ce ON ce.class_id = cs.class_id
JOIN public.students s ON s.id = ce.student_id
WHERE cs.ended_at IS NOT NULL;

-- Buổi đang mở: chỉ record PRESENT cho SV nhận diện được
INSERT INTO public.attendance_records (session_id, student_id, status, confidence)
SELECT
    cs.id,
    s.id,
    'PRESENT',
    ROUND((0.80 + RANDOM() * 0.19)::numeric, 4)::double precision
FROM public.class_sessions cs
JOIN public.class_enrollments ce ON ce.class_id = cs.class_id
JOIN public.students s ON s.id = ce.student_id
WHERE cs.ended_at IS NULL
  AND s.student_code NOT IN ('SV2024003'); -- SV003 chưa điểm danh

-- -------------------------------------------------------------
-- 8. AUDIT LOGS — vài entry thực tế
-- -------------------------------------------------------------
INSERT INTO public.audit_logs (actor_id, action, target_table, ip_address, user_agent)
SELECT id, 'LOGIN',           NULL,       '127.0.0.1', 'seed-script' FROM public.users WHERE username = 'admin'
UNION ALL
SELECT id, 'CREATE_STUDENT',  'students', '127.0.0.1', 'seed-script' FROM public.users WHERE username = 'admin'
UNION ALL
SELECT id, 'CREATE_CLASS',    'classes',  '127.0.0.1', 'seed-script' FROM public.users WHERE username = 'admin'
UNION ALL
SELECT id, 'CREATE_SESSION',  'class_sessions', '127.0.0.1', 'seed-script' FROM public.users WHERE username = 'admin';