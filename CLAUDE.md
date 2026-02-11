# Specular-AI Context & Memory

> **System Critical**: This file represents the ACTIVE state of the project.
> **Last Updated**: 2026-02-11

## 1. Constitutional Mandates (Non-Negotiable)

*The following rules override all other defaults.*

1. **Specification**: Gherkin (`.feature`) files are the ONLY functional source of truth.
2. **Schema First**: Data structures defined in `specs/db_schema/*.dbml` are the **Absolute Truth** for field names and constraints.
3. **Isolation**: The "Las Vegas Rule" applies. All external calls (HTTP/DB) MUST be mocked in tests.
4. **CQRS**: Strict separation between **COMMAND** (State Change) and **QUERY** (Read Only).
5. **Standards**: Python 3.x+ Strict.
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
# specs/db_schema/           -> [TRUTH] DBML Database Definitions
# specs/features/<Domain>/   -> [TRUTH] Gherkin Specs (Command/Query)
# app/services/<Domain>/    -> Business Logic (Service Objects)
# app/models/               -> Pydantic Schemas & DB Models
# tests/steps/              -> Step Definitions

```

## 4. Development Workflow Cheatsheet

*How we build features in this repo.*

1. **Specify**: `/speckit.specify` (Provide **Type: COMMAND/QUERY** + **@dbml context**).
2. **Clarify**: `/speckit.clarify` (Auto-QA: Verify Gherkin against DBML constraints).
3. **Plan**: `/speckit.plan` (Design Pydantic models & Mocking strategy).
4. **Task**: `/speckit.tasks` (Generate Red/Green task list).
5. **Code**: Implement using TDD (Test -> Mock -> Code).
6. **Verify**: Run `pytest specs/features/<Domain>/[name].feature`.

## 5. Recent Architectural Decisions

[LAST 3 MAJOR CHANGES OR PATTERNS ADOPTED]

* **Structure**: Adopted Domain-Driven directory structure.
* **Pattern**: Enforced CQRS naming conventions (Precondition/Postcondition).
* **Global Constraint**: Ensure all datetime objects are timezone-aware (UTC).
* **Reminder**: Always check `specs/db_schema/_relationships.dbml` when handling cross-domain logic.
