# Specular-AI Context & Memory

> **System Critical**: This file represents the ACTIVE state of the project.
> **Last Updated**: 2026-02-11

## 1. Constitutional Mandates (Non-Negotiable)

*The following rules override all other defaults.*

1. **Specification**: Gherkin (`.feature`) files are the ONLY functional source of truth.
2. **Schema First**: Data structures in `specs/db_schema/*.dbml` are the **Absolute Truth** for field names and constraints. Provisional schemas (`@provisional`) are auto-generated during Spec phase and ratified during Plan phase. See `constitution.md §I-B` for lifecycle rules.
3. **Isolation**: The "Las Vegas Rule" applies. All external calls (HTTP/DB) MUST be mocked in tests.
4. **CQRS**: Strict separation between **COMMAND** (State Change) and **QUERY** (Read Only).
5. **Standards**: Python 3.12+ Strict.
    * **Type Hints**: Mandatory on ALL signatures.
    * **Data**: Pydantic v2 Models for all DTOs (No raw dicts).
    * **Async**: Required for I/O bound ops (FastAPI context).
6. **Docker**: All code execution (tests, lint, type checks) MUST run inside Docker. Never install or run locally.

## 2. Active Tech Stack

* **Framework**: FastAPI >= 0.115
* **Validation**: Pydantic >= 2.0
* **Server**: Uvicorn >= 0.30
* **Testing**: `pytest` + `pytest-asyncio` + `pytest-bdd` + `httpx`
* **Type Checking**: `mypy`
* **Containerization**: Docker + Docker Compose

## 3. Project Structure Map

```text
specs/
├── db_schema/              -> [TRUTH] DBML Database Definitions
│   ├── _project.dbml
│   ├── _relationships.dbml
│   ├── agent.dbml
│   ├── auth.dbml
│   ├── mcp.dbml
│   └── ...
└── features/<Domain>/      -> [TRUTH] Gherkin Specs + Plans + Tasks
    ├── <Feature>.feature
    ├── <Feature>.plan.md
    ├── <Feature>.tasks.md
    └── contracts/

app/
├── schemas/                -> Pydantic request/response models
├── services/               -> Business logic (Service Objects)
├── repositories/           -> Data access interfaces (mocked in tests)
├── routers/                -> FastAPI endpoints (thin delegation)
├── middleware/              -> Cross-cutting concerns (auth)
└── exceptions.py           -> Custom exceptions → HTTP status codes

tests/
├── conftest.py             -> Shared mock fixtures (single source of truth)
├── unit/                   -> Service unit tests (pytest + AsyncMock)
└── integration/            -> BDD integration tests (pytest-bdd)

.specify/
├── memory/constitution.md  -> Project principles (8 rules)
├── config/isa.yml          -> ISA patterns for BDD test generation
└── templates/              -> Spec/Plan/Task/Checklist templates
```

## 4. Development Workflow Cheatsheet

*How we build features in this repo.*

1. **Specify**: `/speckit.specify` — Create Gherkin spec from requirements
2. **Clarify**: `/speckit.clarify` — Detect ambiguities, record answers in spec
3. **Plan**: `/speckit.plan` — Generate API contracts, Pydantic models, ISA mapping
4. **Task**: `/speckit.tasks` — Generate phased task list (Skeleton → Unit → BDD → Logic → Lint)
5. **Implement**: `/speckit.implement` — Execute tasks via TDD in Docker

### Common Commands

```bash
# Run all tests
docker compose run --rm test

# Run specific test file
docker compose run --rm test pytest tests/unit/test_agent_service.py -v

# Run BDD integration tests only
docker compose run --rm test pytest tests/integration/ -v

# Type check
docker compose run --rm lint
```

## 5. Recent Architectural Decisions

* **Shared Fixtures**: `tests/conftest.py` is the single source of truth for mock repositories. Unit and integration tests import from conftest, with local overrides for test-specific defaults.
* **BDD Mandatory**: Every Gherkin Scenario MUST have a corresponding `@scenario()` decorator in `tests/integration/`. This is enforced in the tasks template (Phase 3) and checklist (`[BDD-Count]` gate).
* **Repository Pattern**: Service layer depends on abstract repository interfaces (`AgentRepository`, `McpRepository`). Concrete DB implementations are deferred to a future feature. Tests use `AsyncMock(spec=...)` for full isolation.
* **Fail-Fast Atomicity**: MCP validation runs BEFORE any DB writes. If validation fails, no Agent record is created (no rollback needed).
* **Global Constraint**: All datetime objects are timezone-aware (UTC).
* **Reminder**: Always check `specs/db_schema/_relationships.dbml` when handling cross-domain logic.
