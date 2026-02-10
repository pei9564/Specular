# Research: 建立初始管理員帳號

**Branch**: `001-bootstrap-admin` | **Date**: 2026-02-10

## Technical Decisions

### 1. Database — PostgreSQL 15

- **Decision**: PostgreSQL 15 (as specified in `spec/tech_stack.yaml`)
- **Rationale**: Multi-user platform with concurrent access, audit requirements, and JSONB support for flexible configurations. Advisory locks ensure idempotent bootstrap across replicas.
- **Alternatives considered**: SQLite (rejected: no concurrent writes, no advisory locks)

### 2. ORM — SQLAlchemy 2.0 Async

- **Decision**: SQLAlchemy 2.0 with AsyncPG driver, using `select()` API
- **Rationale**: Tech stack specifies `AsyncPG / SQLModel / SQLAlchemy`. SQLAlchemy 2.0 `select()` API provides full type hint support, native async, and is future-proof. Separate ORM models from Pydantic DTOs for clear boundaries.
- **Alternatives considered**: SQLModel (too tightly couples ORM + API schemas), Tortoise ORM (smaller ecosystem, less mature async)

### 3. Password Hashing — passlib with bcrypt

- **Decision**: `passlib[bcrypt]` with bcrypt scheme, rounds=12
- **Rationale**: Industry-standard, well-supported in Python ecosystem, ~100ms per hash. Simpler dependency than argon2-cffi for MVP phase.
- **Alternatives considered**: Argon2id (superior GPU resistance but adds `argon2-cffi` C dependency), PBKDF2 (weaker against GPU attacks)

### 4. Migrations — Alembic (async)

- **Decision**: Alembic with async support via `connection.run_sync()` pattern
- **Rationale**: De facto standard for SQLAlchemy migrations. Version-controlled, auto-generates from model changes, supports rollback.
- **Alternatives considered**: Raw SQL migrations (no version tracking), SQLModel auto-create (no rollback support)

### 5. Startup Hook — FastAPI Lifespan

- **Decision**: `@asynccontextmanager` lifespan pattern
- **Rationale**: Modern FastAPI pattern replacing deprecated `on_event`. Single entry point for startup/shutdown with proper exception handling and cleanup.
- **Alternatives considered**: `@app.on_event("startup")` (deprecated in FastAPI 0.93+)

### 6. Configuration — pydantic-settings

- **Decision**: `pydantic-settings` with `BaseSettings` for env var management
- **Rationale**: Type-safe configuration with built-in `EmailStr` validation and nested settings. Fail-fast on invalid config at startup, not runtime.
- **Alternatives considered**: `python-dotenv` (no type validation), `os.getenv` (manual parsing, scattered config)

### 7. Audit Logging — structlog + DB audit table

- **Decision**: Dual approach — `structlog` for application logs (JSON), `audit_logs` table for permanent queryable record
- **Rationale**: Application logs are ephemeral; DB audit table provides compliance-ready permanent record. structlog's processor pipeline enables automatic password redaction.
- **Alternatives considered**: Python stdlib `logging` (no native JSON/context), custom logger (reinventing the wheel)
