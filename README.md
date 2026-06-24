# Face Attendance Backend

Hệ thống điểm danh nhận diện khuôn mặt — Spring Boot (REST API) + PostgreSQL.

## Tech Stack

| Layer    | Technology                        |
| -------- | --------------------------------- |
| Backend  | Spring Boot 3.5.14 / Java 21      |
| Database | PostgreSQL 17                     |
| Infra    | Docker / Docker Compose           |

## Yêu cầu

- Docker & Docker Compose

## Quick Start

**1. Tạo file môi trường**

```bash
cp .env.example .env
```

Chỉnh sửa `.env`:

```env
DB_PASSWORD=
JWT_SECRET=
JWT_ACCESS_TOKEN_EXPIRY=
JWT_REFRESH_TOKEN_EXPIRY=
INTERNAL_API_KEY=
ENCRYPTION_SECRET_KEY=
```

**2. Chạy**

```bash
docker compose up -d
```

Schema và seed data được tự động khởi tạo khi container postgres khởi động lần đầu.

**3. Swagger UI:** `http://localhost:8080/swagger-ui.html`

## API Overview

| Group              | Base URL                 |
| ------------------ | ------------------------ |
| Auth               | `/api/auth`              |
| Users              | `/api/users`             |
| Classes            | `/api/classes`           |
| Students           | `/api/students`          |
| Enrollments        | `/api/enrollments`       |
| Sessions           | `/api/sessions`          |
| Attendance         | `/api/attendance`        |
| Export CSV         | `/api/attendance/export` |
| Embeddings         | `/api/embeddings`        |
| Benchmark          | `/api/benchmarks`        |
| Audit Logs         | `/api/audit-logs`        |
| Internal (FastAPI) | `/internal`              |

Chi tiết từng endpoint xem tại Swagger UI.

## Internal API cho FastAPI

Header: `X-Internal-Api-Key: {api-key}`

| Method | Endpoint                           | Mô tả                  |
| ------ | ---------------------------------- | ---------------------- |
| GET    | `/internal/embeddings`             | Load tất cả embedding  |
| GET    | `/internal/embeddings/{studentId}` | Embedding 1 sinh viên  |
| POST   | `/internal/attendance/mark`        | Ghi kết quả nhận diện  |
| POST   | `/internal/benchmark`              | Lưu kết quả benchmark  |

**Flow:** Tạo session → Load embeddings → Nhận diện realtime → Mark attendance → End session → Benchmark

## Roles

| Role       | Quyền                              |
| ---------- | ---------------------------------- |
| ADMIN      | Toàn quyền                         |
| LECTURER   | Quản lý lớp, sinh viên, điểm danh  |
| RESEARCHER | Xem và chạy benchmark              |

## CI/CD

GitHub Actions tự động build và test khi push lên `main` hoặc `develop`.
