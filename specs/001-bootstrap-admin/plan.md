# Implementation Plan: 建立初始管理員帳號

**Branch**: `001-bootstrap-admin` | **Date**: 2026-02-10
**Source Feature**: `specs/features/建立初始管理員帳號.feature`
> **CRITICAL**: This plan is strictly based on the Scenarios and Rules defined in the Gherkin source above. No external spec.md is used.

## Constitution Check (The 7 Commandments)

*GATE: Must pass before proceeding. If any item is unchecked, STOP and fix.*

- [x] **I. Gherkin is King**: Plan traces directly to `.feature` scenarios (7 Rules, 9 Examples mapped below).
- [x] **II. Surgical Precision**: Only bootstrap-related files created; no modifications to unrelated code.
- [x] **III. Plug-and-Play**: Logic in `BootstrapAdminService`; FastAPI lifespan is thin delegation only.
- [x] **IV. Las Vegas Rule**: DB access via injected `AsyncSession`; all tests mock the session.
- [x] **V. Modern Python**: All signatures typed; Pydantic for settings/DTOs; PEP 8 via Ruff/Black.
- [x] **VI. Context-Aware**: FastAPI detected (`spec/tech_stack.yaml`); async/await throughout.
- [x] **VII. Defensive Coding**: Custom exceptions (`BootstrapValidationError`, `BootstrapDatabaseError`); no bare `except`.

## Technical Context

**Framework Detected**: FastAPI (via `spec/tech_stack.yaml` → `backend.framework: FastAPI`)
**Async Requirement**: Yes (FastAPI + AsyncPG)
**New Dependencies**: `fastapi`, `uvicorn`, `sqlalchemy[asyncio]`, `asyncpg`, `alembic`, `pydantic-settings`, `passlib[bcrypt]`, `structlog`, `email-validator`
**Existing Components**: None (greenfield — first feature)

---

## 1. Architecture & Design
>
> *Rule III: Plug-and-Play Architecture*

- **Summary**: On application startup, a `BootstrapAdminService` checks if the `users` table is empty. If empty, it creates an admin account using configuration from environment variables (or defaults). The service logs to both `structlog` (application logs) and the `audit_logs` DB table. The entire flow is idempotent.

- **New Components**:
  - `app/services/bootstrap.py :: BootstrapAdminService` — Core bootstrap logic (check, create, audit)
  - `app/models/user.py :: User` — SQLAlchemy ORM model for `users` table
  - `app/models/audit_log.py :: AuditLog` — SQLAlchemy ORM model for `audit_logs` table
  - `app/core/config.py :: AppSettings` — pydantic-settings configuration with `AdminBootstrapSettings` nested
  - `app/core/database.py` — Async engine, session factory, `get_db` dependency
  - `app/core/security.py` — Password hashing utilities (passlib bcrypt)
  - `app/core/exceptions.py` — Custom exception classes
  - `app/main.py` — FastAPI app with lifespan context manager
  - `alembic/` — Migration infrastructure + initial migration

- **Modified Components**: None (greenfield)

- **Data Flow**:

    ```
    FastAPI lifespan start
      → Alembic run_migrations()
      → AppSettings.load() (validates env vars or fails fast)
      → BootstrapAdminService.execute(session, settings)
        → SELECT COUNT(*) FROM users
        → If 0: hash password → INSERT user → INSERT audit_log → log event
        → If >0: log skip → INSERT audit_log (skip event)
      → yield (app ready)
    ```

## 2. Interface Contract (API & Methods)
>
> *Rule V: Modern Pythonic Standards (Type Hints & Pydantic)*

#### A. API Endpoints (if applicable)

```
None — this feature is a startup lifecycle event, not an API endpoint.
```

#### B. Core Service Methods

```python
class BootstrapAdminService:
    def __init__(self, session: AsyncSession, settings: AdminBootstrapSettings) -> None: ...

    async def execute(self) -> BootstrapResult:
        """Main entry point. Idempotent: creates admin only if users table is empty."""

    async def _has_existing_users(self) -> bool:
        """Check if any user records exist."""

    async def _create_admin_user(self) -> User:
        """Create admin user with hashed password. Raises BootstrapValidationError on bad config."""

    async def _record_audit_event(self, action: str, target_id: str | None, details: dict[str, Any]) -> None:
        """Insert immutable audit log record."""
```

```python
# Pydantic Settings
class AdminBootstrapSettings(BaseModel):
    email: EmailStr = "admin@pegatron.com"
    password: str | None = None  # None = auto-generate + warn
    full_name: str = "System Administrator"

    @field_validator("password")
    @classmethod
    def validate_password_strength(cls, v: str | None) -> str | None: ...

class AppSettings(BaseSettings):
    database_url: str
    admin: AdminBootstrapSettings = AdminBootstrapSettings()
    model_config = SettingsConfigDict(env_file=".env", env_nested_delimiter="__")
```

```python
# Result DTO
class BootstrapResult(BaseModel):
    action: Literal["created", "skipped"]
    admin_email: str | None = None
    uses_default_password: bool = False
```

## 3. Data Model Changes

> *Rule V: Pydantic Models & DB Schemas*

- **Database Schema**: See `data-model.md` for full table definitions.

```python
class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False)
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    full_name: Mapped[str] = mapped_column(String(100), nullable=False)
    role: Mapped[str] = mapped_column(String(20), nullable=False, default="user")
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    must_change_password: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())


class AuditLog(Base):
    __tablename__ = "audit_logs"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    action: Mapped[str] = mapped_column(String(100), nullable=False)
    actor_id: Mapped[str] = mapped_column(String(100), nullable=False)
    target_type: Mapped[str] = mapped_column(String(50), nullable=False)
    target_id: Mapped[str | None] = mapped_column(String(100), nullable=True)
    details: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
```

## 4. Step Definitions Mapping

> *Rule I: Gherkin is King - Connect Scenarios to Code*

| Gherkin Step | Target Python Function/Method |
| --- | --- |
| `Given 系統資料庫 users 表為空（記錄數 = 0）` | `tests/steps/test_bootstrap.py :: given_empty_users_table` |
| `Given 未配置自訂管理員環境變數` | `tests/steps/test_bootstrap.py :: given_default_env` |
| `Given 已配置自訂管理員 Email 與 Password` | `tests/steps/test_bootstrap.py :: given_custom_env` |
| `Given 系統資料庫 users 表已存在記錄` | `tests/steps/test_bootstrap.py :: given_existing_users` |
| `Given 配置了無效格式的管理員 Email` | `tests/steps/test_bootstrap.py :: given_invalid_email_env` |
| `Given 配置了強度不足的密碼` | `tests/steps/test_bootstrap.py :: given_weak_password_env` |
| `Given 系統首次啟動已建立初始管理員` | `tests/steps/test_bootstrap.py :: given_admin_already_created` |
| `Given 系統使用預設密碼建立初始管理員` | `tests/steps/test_bootstrap.py :: given_default_password_admin` |
| `When 系統啟動完成` | `app/services/bootstrap.py :: BootstrapAdminService.execute()` |
| `When 系統啟動` | `app/services/bootstrap.py :: BootstrapAdminService.execute()` |
| `When 系統重新啟動` | `app/services/bootstrap.py :: BootstrapAdminService.execute()` |
| `When 管理員使用預設密碼登入` | Future feature (login); test validates `must_change_password=True` |
| `Then users 表應新增一筆記錄` | `tests/steps/test_bootstrap.py :: then_user_record_created` |
| `Then 系統日誌應記錄初始帳號建立事件` | `tests/steps/test_bootstrap.py :: then_log_contains_bootstrap_event` |
| `Then 系統日誌應警告使用預設密碼` | `tests/steps/test_bootstrap.py :: then_log_warns_default_password` |
| `Then 系統日誌不應出現預設密碼警告` | `tests/steps/test_bootstrap.py :: then_log_no_default_password_warning` |
| `Then users 表記錄數量應維持不變` | `tests/steps/test_bootstrap.py :: then_user_count_unchanged` |
| `Then 系統應啟動失敗並提示 Email 格式錯誤` | `tests/steps/test_bootstrap.py :: then_startup_fails_email_error` |
| `Then 系統應啟動失敗並提示密碼安全性不足` | `tests/steps/test_bootstrap.py :: then_startup_fails_password_error` |
| `Then audit_logs 表應新增一筆記錄` | `tests/steps/test_bootstrap.py :: then_audit_log_created` |
| `Then 系統日誌不應包含密碼明文` | `tests/steps/test_bootstrap.py :: then_log_no_plaintext_password` |
| `Then 系統應強制要求變更密碼` | `tests/steps/test_bootstrap.py :: then_must_change_password_flag` |

## 5. Verification Strategy

> *Rule IV: Las Vegas Rule (Isolation & Mocking)*

- **Unit Tests**:
  - Target: `BootstrapAdminService`
  - Mocks: `AsyncSession` (injected via constructor). All DB calls mocked with `AsyncMock`.
  - Coverage: All 9 Gherkin Examples → 9 test cases minimum
  - Password hashing: Mock `passlib.context.CryptContext` to avoid slow hashing in tests

- **Integration Tests**:
  - Target: FastAPI lifespan bootstrap flow
  - Uses: In-memory SQLite or test PostgreSQL container (via `testcontainers`)
  - Scenarios covered:
    - 成功 - 首次啟動使用預設值建立管理員
    - 成功 - 首次啟動使用自訂配置
    - 跳過 - 已存在用戶帳號
    - 重複啟動 - 保持既有狀態
    - 密碼不應出現在日誌中

- **Validation Tests (config)**:
  - Target: `AdminBootstrapSettings` pydantic validator
  - Test invalid email, weak password → `ValidationError`

---

## Complexity Tracking

> *Fill ONLY if Constitution principles are violated for justifiable reasons*

| Violation | Why Needed | Simpler Alternative Rejected Because |
| --- | --- | --- |
| (none) | — | — |
