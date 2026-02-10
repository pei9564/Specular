# Implementation Tasks: 建立初始管理員帳號

**Source Plan**: `specs/001-bootstrap-admin/plan.md`
**Source Feature**: `spec/features/建立初始管理員帳號.feature`

> **Constitution Enforcement**:
> 1. **Surgical Precision**: Only touch files listed in the Plan.
> 2. **Las Vegas Rule**: Tasks MUST include "Mocking" steps for external dependencies.
> 3. **Red-Green-Refactor**: Tests must be written (and fail) BEFORE implementation code.

## User Story Mapping

| Story | Gherkin Rule(s) | Description |
|-------|-----------------|-------------|
| US1 | Rule 1, 2, 4 | Core bootstrap: create admin on first startup, skip if exists, idempotent on restart |
| US2 | Rule 3 | Config validation: reject invalid email/weak password at startup |
| US3 | Rule 5, 6 | Audit & security: audit log, no password in logs, force password change |

---

## Phase 1: Setup & Scaffolding

- [x] T001 Create backend project structure: `app/__init__.py`, `app/core/__init__.py`, `app/models/__init__.py`, `app/services/__init__.py`, `tests/__init__.py`, `tests/steps/__init__.py`
- [x] T002 Create `requirements.txt` with dependencies: fastapi, uvicorn, sqlalchemy[asyncio], asyncpg, alembic, pydantic-settings, passlib[bcrypt], structlog, email-validator, pytest, pytest-asyncio, testcontainers[postgres]
- [x] T003 Create `.env.example` with documented configuration variables (DATABASE_URL, ADMIN__EMAIL, ADMIN__PASSWORD, ADMIN__FULL_NAME)
- [x] T004 Initialize Alembic with async configuration in `alembic/env.py` and `alembic.ini`

---

## Phase 2: Foundational (Blocking)

- [x] T005 [P] Implement custom exceptions in `app/core/exceptions.py`: BootstrapValidationError, BootstrapDatabaseError (mapped to appropriate exit codes)
- [x] T006 [P] Implement password hashing utilities in `app/core/security.py`: hash_password(), verify_password() using passlib CryptContext with bcrypt scheme
- [x] T007 [P] Implement AppSettings and AdminBootstrapSettings with validators in `app/core/config.py`: EmailStr validation, password strength validator (min 12 chars, mixed case, digit, special char), env_nested_delimiter="__"
- [x] T008 Implement async database engine, session factory, and get_db dependency in `app/core/database.py`
- [x] T009 [P] Configure structlog with JSON renderer and password redaction processor in `app/core/logging.py`
- [x] T010 Create SQLAlchemy declarative Base in `app/models/base.py` and re-export in `app/models/__init__.py`
- [x] T011 Implement User ORM model in `app/models/user.py` per data-model.md schema (depends on T010)
- [x] T012 Implement AuditLog ORM model in `app/models/audit_log.py` per data-model.md schema (depends on T010)
- [x] T013 Generate Alembic initial migration for users and audit_logs tables: `alembic revision --autogenerate -m "create users and audit_logs tables"`

---

## Phase 3: US1 — Core Bootstrap Logic
> **Goal**: On first startup with empty users table, create admin. Skip if users exist. Idempotent on restart.
> **Gherkin**: Rule 1 (Examples 1-2), Rule 2 (Example 3), Rule 4 (Example 6)
> **Test criteria**: Service creates exactly 1 admin when table empty; creates 0 when table has records; re-running produces no duplicates.

### Red: Write failing tests

- [ ] T014 Write test `test_bootstrap_default_credentials` in `tests/steps/test_bootstrap.py`: mock AsyncSession, verify User created with email=admin@pegatron.com, role=admin, is_active=True, must_change_password=True; assert structlog output contains "bootstrap_admin_created" event; assert warning log about default password; assert auto-generated password is 16 chars
- [ ] T015 Write test `test_bootstrap_custom_credentials` in `tests/steps/test_bootstrap.py`: mock AsyncSession + custom AdminBootstrapSettings, verify User created with custom email; assert structlog output contains "bootstrap_admin_created" event; assert NO default-password warning in logs
- [ ] T016 Write test `test_bootstrap_skip_existing_users` in `tests/steps/test_bootstrap.py`: mock AsyncSession returning count=1, verify no INSERT executed; assert structlog output contains "bootstrap_admin_skipped" event
- [ ] T017 Write test `test_bootstrap_idempotent_restart` in `tests/steps/test_bootstrap.py`: mock session with existing admin, verify user count unchanged after execute(); assert structlog output contains "bootstrap_admin_skipped" event

### Green: Implement service

- [ ] T018 Implement BootstrapAdminService in `app/services/bootstrap.py`: constructor accepts AsyncSession + AdminBootstrapSettings, execute() method with _has_existing_users() and _create_admin_user() per plan.md contract
- [ ] T019 Implement BootstrapResult Pydantic DTO in `app/services/bootstrap.py`: action (created/skipped), admin_email, uses_default_password

### Verify

- [ ] T020 Run `pytest tests/steps/test_bootstrap.py -k "default or custom or skip or idempotent" -v` — all 4 tests must pass

---

## Phase 4: US2 — Configuration Validation
> **Goal**: System fails fast on invalid email format or weak password in env vars.
> **Gherkin**: Rule 3 (Examples 4-5)
> **Test criteria**: Invalid email raises ValidationError; weak password raises ValidationError; both prevent startup.

### Red: Write failing tests

- [ ] T021 [P] Write test `test_invalid_email_rejects` in `tests/steps/test_bootstrap.py`: construct AdminBootstrapSettings with invalid email, assert ValidationError raised
- [ ] T022 [P] Write test `test_weak_password_rejects` in `tests/steps/test_bootstrap.py`: construct AdminBootstrapSettings with password="123", assert ValidationError raised with password strength message

### Green: Validate implementation

- [ ] T023 Verify password strength validator in `app/core/config.py` enforces: min 12 chars, mixed case, digit, special character (already scaffolded in T007 — adjust if tests fail)

### Verify

- [ ] T024 Run `pytest tests/steps/test_bootstrap.py -k "invalid_email or weak_password" -v` — both tests must pass

---

## Phase 5: US3 — Audit Logging & Security
> **Goal**: Bootstrap events recorded in audit_logs; passwords never appear in logs; default password forces change.
> **Gherkin**: Rule 5 (Example 7), Rule 6 (Examples 8-9)
> **Test criteria**: audit_logs gets INSERT on bootstrap; structlog output contains no password string; User.must_change_password=True when using default password.

### Red: Write failing tests

- [ ] T025 Write test `test_audit_log_created_on_bootstrap` in `tests/steps/test_bootstrap.py`: mock AsyncSession, verify AuditLog INSERT with action="system.bootstrap.admin", actor_id="system", target_type="user"
- [ ] T026 Write test `test_no_password_in_logs` in `tests/steps/test_bootstrap.py`: capture structlog output during execute(), assert no password plaintext in any log entry
- [ ] T027 Write test `test_default_password_forces_change` in `tests/steps/test_bootstrap.py`: execute with default password (None), verify created User has must_change_password=True

### Green: Implement audit

- [ ] T028 Implement _record_audit_event() in `app/services/bootstrap.py`: INSERT into audit_logs table with action, actor_id, target_type, target_id, details (no sensitive data)
- [ ] T029 Wire structlog calls in BootstrapAdminService.execute() in `app/services/bootstrap.py`: log bootstrap_admin_created/bootstrap_admin_skipped events, warn on default password usage

### Verify

- [ ] T030 Run `pytest tests/steps/test_bootstrap.py -k "audit or password_in_logs or forces_change" -v` — all 3 tests must pass

---

## Phase 6: Integration & Polish

- [ ] T031 Implement FastAPI app with lifespan context manager in `app/main.py`: load settings → run migrations → call BootstrapAdminService.execute() → yield → cleanup
- [ ] T032 Write integration test `test_full_bootstrap_lifespan` in `tests/steps/test_bootstrap.py`: use TestClient or mock lifespan to verify full startup flow end-to-end
- [ ] T033 Run full test suite: `pytest tests/steps/test_bootstrap.py -v` — all tests must pass
- [ ] T034 Run linter on all modified files: `ruff check app/ tests/`
- [ ] T035 Run type checker on all modified files: `mypy app/ --ignore-missing-imports` (or pyright)

---

## Dependencies

```
Phase 1 (T001-T004) → Phase 2 (T005-T013) → Phase 3 (T014-T020)
                                             → Phase 4 (T021-T024) [parallel with Phase 3]
                                             → Phase 5 (T025-T030) [after Phase 3]
                                             → Phase 6 (T031-T035) [after all]
```

### Parallel Execution Opportunities

| Parallel Group | Tasks | Rationale |
|---------------|-------|-----------|
| Foundational infra | T005, T006, T007, T008, T009 | Independent files, no cross-dependencies (T010→T011,T012 sequential) |
| US1 tests | T014, T015, T016, T017 | Independent test functions |
| US2 tests | T021, T022 | Independent validation tests |
| US3 tests | T025, T026, T027 | Independent audit/security tests |
| US1 + US2 phases | Phase 3 + Phase 4 | US2 config validation is independent of US1 service logic |

---

## Implementation Strategy

- **MVP scope**: Phase 1 + Phase 2 + Phase 3 (US1) — system can bootstrap an admin account
- **Incremental delivery**: Add US2 (validation) and US3 (audit/security) as follow-up
- **Each phase is independently testable**: US1 tests pass without US2/US3 being complete
