# Specular-AI Context & Memory

> **System Critical**: This file represents the ACTIVE state of the project.
> **Last Updated**: 2026-02-10

## 1. Constitutional Mandates (Non-Negotiable)
*The following rules override all other defaults.*

1.  **Specification**: Gherkin (`.feature`) files in `spec/features/` are the ONLY source of truth. No `spec.md`.
2.  **Isolation**: The "Las Vegas Rule" applies. All external calls (HTTP/DB) MUST be mocked in tests.
3.  **Precision**: Modifications must be surgical. No "drive-by" refactoring of unrelated files.
4.  **Standards**: Python 3.11+ Strict.
    * **Type Hints**: Mandatory on ALL signatures.
    * **Data**: Pydantic Models for all DTOs (No raw dicts).
    * **Async**: Required for I/O bound ops (FastAPI context).

## 2. Active Tech Stack
* **Framework**: FastAPI + Uvicorn (ASGI)
* **Validation**: Pydantic v2
* **Database**: PostgreSQL 15 (relational), Milvus (vector), Redis (queue/cache)
* **ORM**: SQLAlchemy 2.0 async + AsyncPG
* **Migrations**: Alembic
* **Testing**: pytest + pytest-bdd (Playwright + playwright-bdd for E2E)
* **Key Libs**: passlib[bcrypt], structlog, pydantic-settings, email-validator
* **Frontend**: React + Vite (TypeScript SPA, separate from backend)
* **Agent Framework**: AgentScope

## 3. Project Structure Map
*Current layout of key directories.*

```text
spec/features/          -> Gherkin Source (7 features)
specs/001-*/            -> Per-feature planning artifacts (plan.md, data-model.md, contracts/)
app/services/           -> Business Logic (Service Objects)
app/models/             -> Pydantic Schemas & DB Models
app/core/               -> Config, DB, Security, Exceptions
tests/steps/            -> Step Definitions
alembic/                -> Database migrations
```

## 4. Development Workflow Cheatsheet

*How we build features in this repo.*

1. **Define**: Create `spec/features/[name].feature`
2. **Plan**: Run `/speckit.plan`
3. **Task**: Run `/speckit.tasks` (Generates Red/Green list)
4. **Code**: Implement using TDD (Test -> Mock -> Code)
5. **Verify**: Run `pytest tests/steps/`

## 5. Recent Architectural Decisions

* Adopted FastAPI lifespan context manager for startup/shutdown lifecycle
* Password hashing via passlib[bcrypt] (bcrypt scheme, rounds=12)
* Dual audit logging: structlog (JSON app logs) + audit_logs DB table (permanent)
* **Global Constraint**: Ensure all datetime objects are timezone-aware (UTC).
