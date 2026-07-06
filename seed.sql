SET client_encoding = 'UTF8';

-- 1. USERS
INSERT INTO public.users (username, password_hash, full_name, email, role, is_active)
VALUES 
    ('admin', crypt('Admin123!', gen_salt('bf', 10)), 'Hệ Thống Quản Trị', 'admin@faceattend.local', 'ADMIN', true),
    ('gv_cuong', crypt('Lecturer123!', gen_salt('bf', 10)), 'Nguyễn Tiến Cường', 'cuong.nt@faculty.edu.vn', 'LECTURER', true),
    ('gv_huong', crypt('Lecturer123!', gen_salt('bf', 10)), 'Phạm Thanh Hương', 'huong.pt@faculty.edu.vn', 'LECTURER', true),
    ('gv_minh', crypt('Lecturer123!', gen_salt('bf', 10)), 'Trần Hoàng Minh', 'minh.th@faculty.edu.vn', 'LECTURER', false),
    ('ncv_duc', crypt('Research123!', gen_salt('bf', 10)), 'Lê Minh Đức', 'duc.lm@research.edu.vn', 'RESEARCHER', true);

-- 2. STUDENTS
INSERT INTO public.students (research_id, full_name, student_code, email, is_active)
VALUES
    ('RID-24-001', 'Nguyễn Văn An', 'SV2024001', 'an.nv24@student.edu.vn', true),
    ('RID-24-002', 'Trần Thị Bình', 'SV2024002', 'binh.tt24@student.edu.vn', true),
    ('RID-24-003', 'Lê Hoàng Cường', 'SV2024003', 'cuong.lh24@student.edu.vn', true),
    ('RID-24-004', 'Phạm Thị Dung', 'SV2024004', 'dung.pt24@student.edu.vn', true),
    ('RID-24-005', 'Hoàng Minh Đức', 'SV2024005', 'duc.hm24@student.edu.vn', true),
    ('RID-24-006', 'Vũ Thị Hoa', 'SV2024006', 'hoa.vt24@student.edu.vn', false),
    ('RID-24-007', 'Đặng Lê Gia Bảo', 'SV2024007', 'bao.dlg24@student.edu.vn', true),
    ('RID-24-008', 'Bùi Minh Tuấn', 'SV2024008', 'tuan.bm24@student.edu.vn', true),
    ('RID-24-009', 'Đỗ Thúy Hạnh', 'SV2024009', 'hanh.dt24@student.edu.vn', true),
    ('RID-24-010', 'Ngô Quốc Khánh', 'SV2024010', 'khanh.nq24@student.edu.vn', true),
    ('RID-24-011', 'Phan Văn Nam', 'SV2024011', 'nam.pv24@student.edu.vn', true),
    ('RID-24-012', 'Lý Thị Mai', 'SV2024012', 'mai.lt24@student.edu.vn', true),
    ('RID-24-013', 'Dương Hồng Ngọc', 'SV2024013', 'ngoc.dh24@student.edu.vn', true),
    ('RID-24-014', 'Vũ Hoàng Long', 'SV2024014', 'long.vh24@student.edu.vn', true),
    ('RID-24-015', 'Trần Thu Thảo', 'SV2024015', 'thao.tt24@student.edu.vn', true),
    ('RID-24-016', 'Lê Anh Tú', 'SV2024016', 'tu.la24@student.edu.vn', true),
    ('RID-24-017', 'Phạm Minh Quân', 'SV2024017', 'quan.pm24@student.edu.vn', true),
    ('RID-24-018', 'Nguyễn Thị Kim Oanh', 'SV2024018', 'oanh.ntk24@student.edu.vn', true),
    ('RID-24-019', 'Đinh Quang Huy', 'SV2024019', 'huy.dq24@student.edu.vn', true),
    ('RID-24-020', 'Trịnh Thúy Vy', 'SV2024020', 'vy.tt24@student.edu.vn', true),
    ('RID-24-021', 'Hoàng Ngọc Sơn', 'SV2024021', 'son.hn24@student.edu.vn', true),
    ('RID-24-022', 'Nguyễn Tiến Đạt', 'SV2024022', 'dat.nt24@student.edu.vn', true),
    ('RID-24-023', 'Mai Phương Thúy', 'SV2024023', 'thuy.mp24@student.edu.vn', true),
    ('RID-24-024', 'Hồ Tấn Tài', 'SV2024024', 'tai.ht24@student.edu.vn', true),
    ('RID-24-025', 'Đoàn Văn Hậu', 'SV2024025', 'hau.dv24@student.edu.vn', true),
    ('RID-24-026', 'Nguyễn Công Phượng', 'SV2024026', 'phuong.nc24@student.edu.vn', false),
    ('RID-24-027', 'Bùi Tiến Dũng', 'SV2024027', 'dung.bt24@student.edu.vn', true),
    ('RID-24-028', 'Nguyễn Quang Hải', 'SV2024028', 'hai.nq24@student.edu.vn', true),
    ('RID-24-029', 'Phan Văn Đức', 'SV2024029', 'duc.pv24@student.edu.vn', true),
    ('RID-24-030', 'Vũ Văn Thanh', 'SV2024030', 'thanh.vv24@student.edu.vn', true);

-- 3. FACE EMBEDDINGS
INSERT INTO public.face_embeddings (student_id, embedding, model_name, embedding_dim, is_valid, created_by)
SELECT
    s.id,
    gen_random_bytes(512),
    (ARRAY['facenet', 'arcface', 'insightface', 'mobilefacenet']::public.model_name[])[abs(hashtext(s.student_code)) % 4 + 1],
    128,
    s.is_active,
    (SELECT id FROM public.users WHERE username = 'admin')
FROM public.students s;

-- 4. CLASSES
INSERT INTO public.classes (class_code, subject_name, lecturer_id, academic_year, term, is_active)
VALUES
    ('CS101-01', 'Nhập môn Lập trình', (SELECT id FROM public.users WHERE username = 'gv_cuong'), 2024, 1, true),
    ('CS202-01', 'Cơ sở Dữ liệu', (SELECT id FROM public.users WHERE username = 'gv_cuong'), 2024, 1, true),
    ('IT301-02', 'Trí tuệ Nhân tạo', (SELECT id FROM public.users WHERE username = 'gv_huong'), 2024, 1, true),
    ('IT402-01', 'Thị giác Máy tính', (SELECT id FROM public.users WHERE username = 'gv_huong'), 2024, 1, true),
    ('SE102-03', 'Kỹ nghệ Phần mềm', (SELECT id FROM public.users WHERE username = 'admin'), 2024, 1, true);

-- 5. CLASS ENROLLMENTS
INSERT INTO public.class_enrollments (student_id, class_id)
SELECT s.id, c.id
FROM public.students s
CROSS JOIN public.classes c
WHERE s.is_active = true
  AND (
    (c.class_code IN ('CS101-01', 'CS202-01') AND s.student_code BETWEEN 'SV2024001' AND 'SV2024015') OR
    (c.class_code IN ('IT301-02', 'IT402-01') AND s.student_code BETWEEN 'SV2024010' AND 'SV2024030') OR
    (c.class_code = 'SE102-03')
  );

-- 6. CLASS SESSIONS
INSERT INTO public.class_sessions (id, class_id, created_by, started_at, ended_at, notes)
VALUES
    ('00000000-0000-0000-0000-000000000001', (SELECT id FROM public.classes WHERE class_code = 'CS101-01'), (SELECT id FROM public.users WHERE username = 'gv_cuong'), now() - interval '14 days', now() - interval '14 days' + interval '90 minutes', 'Tuần 1 - Tổng quan'),
    ('00000000-0000-0000-0000-000000000002', (SELECT id FROM public.classes WHERE class_code = 'CS101-01'), (SELECT id FROM public.users WHERE username = 'gv_cuong'), now() - interval '7 days', now() - interval '7 days' + interval '90 minutes', 'Tuần 2 - Biến và Kiểu dữ liệu'),
    ('00000000-0000-0000-0000-000000000003', (SELECT id FROM public.classes WHERE class_code = 'CS101-01'), (SELECT id FROM public.users WHERE username = 'gv_cuong'), now() - interval '2 hours', NULL, 'Tuần 3 - Đang diễn ra'),
    
    ('00000000-0000-0000-0000-000000000004', (SELECT id FROM public.classes WHERE class_code = 'CS202-01'), (SELECT id FROM public.users WHERE username = 'gv_cuong'), now() - interval '10 days', now() - interval '10 days' + interval '90 minutes', 'Tuần 1 - Mô hình ER'),
    ('00000000-0000-0000-0000-000000000005', (SELECT id FROM public.classes WHERE class_code = 'CS202-01'), (SELECT id FROM public.users WHERE username = 'gv_cuong'), now() - interval '3 days', now() - interval '3 days' + interval '90 minutes', 'Tuần 2 - Ngôn ngữ SQL'),
    
    ('00000000-0000-0000-0000-000000000006', (SELECT id FROM public.classes WHERE class_code = 'IT301-02'), (SELECT id FROM public.users WHERE username = 'gv_huong'), now() - interval '5 days', now() - interval '5 days' + interval '90 minutes', 'Tuần 1 - Thuật toán tìm kiếm'),
    ('00000000-0000-0000-0000-000000000007', (SELECT id FROM public.classes WHERE class_code = 'IT301-02'), (SELECT id FROM public.users WHERE username = 'gv_huong'), now() - interval '30 minutes', NULL, 'Tuần 2 - Đang diễn ra'),

    ('00000000-0000-0000-0000-000000000008', (SELECT id FROM public.classes WHERE class_code = 'IT402-01'), (SELECT id FROM public.users WHERE username = 'gv_huong'), now() - interval '8 days', now() - interval '8 days' + interval '90 minutes', 'Tuần 1 - Xử lý ảnh cơ bản'),
    ('00000000-0000-0000-0000-000000000009', (SELECT id FROM public.classes WHERE class_code = 'SE102-03'), (SELECT id FROM public.users WHERE username = 'admin'), now() - interval '12 days', now() - interval '12 days' + interval '90 minutes', 'Tuần 1 - Quy trình Agile');

-- 7. ATTENDANCE RECORDS
-- Session 1
INSERT INTO public.attendance_records (session_id, student_id, status, confidence, detected_at)
SELECT 
    '00000000-0000-0000-0000-000000000001', 
    ce.student_id,
    CASE WHEN abs(hashtext(s.student_code)) % 7 = 0 THEN 'ABSENT'::public.attendance_status ELSE 'PRESENT'::public.attendance_status END,
    CASE WHEN abs(hashtext(s.student_code)) % 7 = 0 THEN NULL ELSE ROUND((0.78 + RANDOM() * 0.21)::numeric, 4)::double precision END,
    now() - interval '14 days' + interval '5 minutes' + (abs(hashtext(s.student_code)) % 20 * interval '1 minute')
FROM public.class_enrollments ce
JOIN public.students s ON ce.student_id = s.id
WHERE ce.class_id = (SELECT class_id FROM public.class_sessions WHERE id = '00000000-0000-0000-0000-000000000001');

-- Session 2
INSERT INTO public.attendance_records (session_id, student_id, status, confidence, overridden_by, override_reason, detected_at)
SELECT 
    '00000000-0000-0000-0000-000000000002', 
    ce.student_id,
    CASE 
        WHEN s.student_code = 'SV2024002' THEN 'MANUAL_OVERRIDE'::public.attendance_status 
        WHEN abs(hashtext(s.student_code)) % 8 = 0 THEN 'ABSENT'::public.attendance_status 
        ELSE 'PRESENT'::public.attendance_status 
    END,
    CASE WHEN s.student_code = 'SV2024002' OR abs(hashtext(s.student_code)) % 8 = 0 THEN NULL ELSE ROUND((0.80 + RANDOM() * 0.19)::numeric, 4)::double precision END,
    CASE WHEN s.student_code = 'SV2024002' THEN (SELECT id FROM public.users WHERE username = 'gv_cuong') ELSE NULL END,
    CASE WHEN s.student_code = 'SV2024002' THEN 'Hệ thống không nhận diện được do góc nghiêng lớn' ELSE NULL END,
    now() - interval '7 days' + interval '2 minutes' + (abs(hashtext(s.student_code)) % 15 * interval '1 minute')
FROM public.class_enrollments ce
JOIN public.students s ON ce.student_id = s.id
WHERE ce.class_id = (SELECT class_id FROM public.class_sessions WHERE id = '00000000-0000-0000-0000-000000000002');

-- Session 3
INSERT INTO public.attendance_records (session_id, student_id, status, confidence, detected_at)
SELECT 
    '00000000-0000-0000-0000-000000000003', 
    ce.student_id,
    'PRESENT'::public.attendance_status,
    ROUND((0.85 + RANDOM() * 0.14)::numeric, 4)::double precision,
    now() - interval '1 hour' + (abs(hashtext(s.student_code)) % 10 * interval '2 minutes')
FROM public.class_enrollments ce
JOIN public.students s ON ce.student_id = s.id
WHERE ce.class_id = (SELECT class_id FROM public.class_sessions WHERE id = '00000000-0000-0000-0000-000000000003')
  AND s.student_code <= 'SV2024010';

-- Session 4
INSERT INTO public.attendance_records (session_id, student_id, status, confidence, detected_at)
SELECT '00000000-0000-0000-0000-000000000004', ce.student_id, 'PRESENT', ROUND((0.82 + RANDOM() * 0.17)::numeric, 4)::double precision, now() - interval '10 days' + interval '10 minutes'
FROM public.class_enrollments ce WHERE ce.class_id = (SELECT class_id FROM public.class_sessions WHERE id = '00000000-0000-0000-0000-000000000004');

-- Session 5
INSERT INTO public.attendance_records (session_id, student_id, status, confidence, detected_at)
SELECT '00000000-0000-0000-0000-000000000005', ce.student_id, 'PRESENT', ROUND((0.81 + RANDOM() * 0.18)::numeric, 4)::double precision, now() - interval '3 days' + interval '8 minutes'
FROM public.class_enrollments ce WHERE ce.class_id = (SELECT class_id FROM public.class_sessions WHERE id = '00000000-0000-0000-0000-000000000005');

-- Session 6
INSERT INTO public.attendance_records (session_id, student_id, status, confidence, detected_at)
SELECT 
    '00000000-0000-0000-0000-000000000006', 
    ce.student_id,
    CASE WHEN s.student_code IN ('SV2024015', 'SV2024025') THEN 'ABSENT'::public.attendance_status ELSE 'PRESENT'::public.attendance_status END,
    CASE WHEN s.student_code IN ('SV2024015', 'SV2024025') THEN NULL ELSE ROUND((0.75 + RANDOM() * 0.23)::numeric, 4)::double precision END,
    now() - interval '5 days' + interval '12 minutes'
FROM public.class_enrollments ce
JOIN public.students s ON ce.student_id = s.id
WHERE ce.class_id = (SELECT class_id FROM public.class_sessions WHERE id = '00000000-0000-0000-0000-000000000006');

-- Session 7
INSERT INTO public.attendance_records (session_id, student_id, status, confidence, detected_at)
SELECT '00000000-0000-0000-0000-000000000007', ce.student_id, 'PRESENT', ROUND((0.88 + RANDOM() * 0.10)::numeric, 4)::double precision, now() - interval '15 minutes'
FROM public.class_enrollments ce WHERE ce.class_id = (SELECT class_id FROM public.class_sessions WHERE id = '00000000-0000-0000-0000-000000000007') AND ce.student_id IN (SELECT id FROM public.students WHERE student_code >= 'SV2024020');

-- Session 8
INSERT INTO public.attendance_records (session_id, student_id, status, confidence, detected_at)
SELECT '00000000-0000-0000-0000-000000000008', ce.student_id, 'PRESENT', ROUND((0.79 + RANDOM() * 0.20)::numeric, 4)::double precision, now() - interval '8 days' + interval '4 minutes'
FROM public.class_enrollments ce WHERE ce.class_id = (SELECT class_id FROM public.class_sessions WHERE id = '00000000-0000-0000-0000-000000000008');

-- Session 9
INSERT INTO public.attendance_records (session_id, student_id, status, confidence, detected_at)
SELECT '00000000-0000-0000-0000-000000000009', ce.student_id, 'PRESENT', ROUND((0.84 + RANDOM() * 0.15)::numeric, 4)::double precision, now() - interval '12 days' + interval '6 minutes'
FROM public.class_enrollments ce WHERE ce.class_id = (SELECT class_id FROM public.class_sessions WHERE id = '00000000-0000-0000-0000-000000000009');

-- 8. BENCHMARK RESULTS
INSERT INTO public.benchmark_results (session_id, model_name, scenario, threshold, accuracy, "precision", recall, f1_score, far, frr, eer, avg_latency, fps, sample_count, lighting_condition, face_angle, occlusion, distance_cm, notes)
VALUES
    ('00000000-0000-0000-0000-000000000001', 'arcface', 'CONTROLLED', 0.65, 0.9850, 0.9900, 0.9800, 0.9850, 0.0050, 0.0150, 0.0100, 12.5, 60.0, 500, 'BRIGHT', 'FRONTAL', 'NONE', 100, 'Kết quả môi trường lab chuẩn'),
    ('00000000-0000-0000-0000-000000000002', 'facenet', 'CLASSROOM', 0.70, 0.9120, 0.9250, 0.9000, 0.9123, 0.0210, 0.0340, 0.0280, 24.1, 30.5, 1200, 'NORMAL', 'SLIGHT', 'GLASSES', 250, 'Thử nghiệm thực tế camera giảng đường'),
    ('00000000-0000-0000-0000-000000000004', 'insightface', 'CLASSROOM', 0.60, 0.9640, 0.9710, 0.9580, 0.9645, 0.0080, 0.0120, 0.0095, 18.2, 45.0, 1500, 'NORMAL', 'FRONTAL', 'NONE', 300, 'Insightface tối ưu tốt trên diện rộng'),
    ('00000000-0000-0000-0000-000000000005', 'mobilefacenet', 'ADVERSE', 0.55, 0.8450, 0.8300, 0.8500, 0.8398, 0.0450, 0.0620, 0.0510, 8.4, 90.0, 800, 'DIM', 'PROFILE', 'MASK', 150, 'Mô hình nhẹ chạy trên thiết bị Edge khi sinh viên đeo khẩu trang góc nghiêng'),
    (NULL, 'arcface', 'ADVERSE', 0.68, 0.8910, 0.9050, 0.8800, 0.8923, 0.0180, 0.0410, 0.0310, 14.2, 55.0, 2000, 'BACKLIGHT', 'SLIGHT', 'PARTIAL', 200, 'Benchmark không liên kết session - test trường hợp ngược sáng');

-- 9. USER SESSIONS
INSERT INTO public.user_sessions (user_id, refresh_token_hash, ip_address, user_agent, is_revoked, expires_at, last_used_at)
VALUES
    ((SELECT id FROM public.users WHERE username = 'admin'), 'hash_token_123456', '192.168.1.10', 'Mozilla/5.0 Chrome/120.0', false, now() + interval '30 days', now()),
    ((SELECT id FROM public.users WHERE username = 'gv_cuong'), 'hash_token_789012', '192.168.1.15', 'Mozilla/5.0 Firefox/121.0', false, now() + interval '30 days', now() - interval '1 hour'),
    ((SELECT id FROM public.users WHERE username = 'gv_huong'), 'hash_token_345678', '172.16.0.45', 'Mozilla/5.0 Safari/17.2', false, now() - interval '1 day', now() - interval '1 day');

-- 10. AUDIT LOGS
INSERT INTO public.audit_logs (actor_id, action, target_table, target_id, ip_address, user_agent)
VALUES
    ((SELECT id FROM public.users WHERE username = 'admin'), 'LOGIN', NULL, NULL, '192.168.1.10', 'PostmanRuntime/7.36.0'),
    ((SELECT id FROM public.users WHERE username = 'admin'), 'CREATE_USER', 'users', (SELECT id FROM public.users WHERE username = 'gv_cuong'), '192.168.1.10', 'PostmanRuntime/7.36.0'),
    ((SELECT id FROM public.users WHERE username = 'gv_cuong'), 'LOGIN', NULL, NULL, '192.168.1.15', 'Mozilla/5.0 Chrome/120.0'),
    ((SELECT id FROM public.users WHERE username = 'gv_cuong'), 'CREATE_SESSION', 'class_sessions', '00000000-0000-0000-0000-000000000003', '192.168.1.15', 'Mozilla/5.0 Chrome/120.0'),
    ((SELECT id FROM public.users WHERE username = 'gv_cuong'), 'OVERRIDE_ATTENDANCE', 'attendance_records', NULL, '192.168.1.15', 'Mozilla/5.0 Chrome/120.0'),
    ((SELECT id FROM public.users WHERE username = 'gv_huong'), 'LOGIN', NULL, NULL, '172.16.0.45', 'Mozilla/5.0 Safari/17.2'),
    ((SELECT id FROM public.users WHERE username = 'gv_huong'), 'RUN_BENCHMARK', 'benchmark_results', NULL, '172.16.0.45', 'Mozilla/5.0 Safari/17.2');