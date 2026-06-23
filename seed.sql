
-- USERS
INSERT INTO users (id, username, password_hash, full_name, email, role, is_active)
VALUES
  ('a0000000-0000-0000-0000-000000000001',
   'admin',
   crypt('Admin123!', gen_salt('bf', 10)),
   'Administrator',
   'admin@attendance.com',
   'ADMIN',
   true),

  ('a0000000-0000-0000-0000-000000000002',
   'lecturer01',
   crypt('Admin123!', gen_salt('bf', 10)),
   'Nguyễn Văn Giảng',
   'lecturer01@attendance.com',
   'LECTURER',
   true),

  ('a0000000-0000-0000-0000-000000000003',
   'researcher01',
   crypt('Admin123!', gen_salt('bf', 10)),
   'Trần Thị Nghiên',
   'researcher01@attendance.com',
   'RESEARCHER',
   true);