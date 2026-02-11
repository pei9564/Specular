# [PROJECT NAME] Context & Memory

> **System Critical**: This file represents the ACTIVE state of the project.
> **Last Updated**: [DATE]

## 1. Constitutional Mandates (Non-Negotiable)

*The following rules override all other defaults.*

1. **Specification**: Gherkin (`.feature`) files in `specs/featuress/` are the ONLY source of truth. No `spec.md`.
2. **Isolation**: The "Las Vegas Rule" applies. All external calls (HTTP/DB) MUST be mocked in tests.
3. **Precision**: Modifications must be surgical. No "drive-by" refactoring of unrelated files.
4. **Standards**: Python 3.x+ Strict.
    * **Type Hints**: Mandatory on ALL signatures.
    * **Data**: Pydantic Models for all DTOs (No raw dicts).
    * **Async**: Required for I/O bound ops (FastAPI context).

## 2. Active Tech Stack

[EXTRACTED FROM REQUIREMENTS.TXT AND PLAN.MD]

* **Framework**: [e.g., FastAPI / Flask / Django]
* **Database**: [e.g., PostgreSQL / Redis]
* **Testing**: `pytest` + `pytest-mock` + `pytest-bdd` (or equivalent)
* **Key Libs**: [List major dependencies like Pydantic, SQLAlchemy, httpx]

## 3. Project Structure Map

*Current layout of key directories.*

```text
[ACTUAL STRUCTURE GENERATED FROM FILE SYSTEM]
# Key locations:
# specs/featuress/  -> Gherkin Source
# app/services/   -> Business Logic (Service Objects)
# app/models/     -> Pydantic Schemas & DB Models
# tests/steps/    -> Step Definitions

```

## 4. Development Workflow Cheatsheet

*How we build features in this repo.*

1. **Define**: Create `specs/featuress/[name].feature`
2. **Plan**: Run `/speckit.plan`
3. **Task**: Run `/speckit.tasks` (Generates Red/Green list)
4. **Code**: Implement using TDD (Test -> Mock -> Code)
5. **Verify**: Run `pytest specs/featuress/[name].feature`

## 5. Recent Architectural Decisions

[LAST 3 MAJOR CHANGES OR PATTERNS ADOPTED]

* [e.g., Adopted Dependency Injection for Service Layer]
* [e.g., Standardized on Pydantic V2]
* **Global Constraint**: Ensure all datetime objects are timezone-aware (UTC).
