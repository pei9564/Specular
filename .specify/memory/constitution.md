<!--
  Sync Impact Report
  ==================
  Version change: 1.0.0 → 1.1.0 (MINOR: new principle added)
  Modified principles: None
  Added sections:
    - VII. Defensive Coding & Error Handling
  Removed sections: None
  Templates requiring updates:
    - .specify/templates/plan-template.md: ✅ updated (VII gate added to Constitution Check)
    - .specify/templates/spec-template.md: ✅ no update needed (unused per Principle I)
    - .specify/templates/tasks-template.md: ✅ no update needed
    - .specify/templates/agent-file-template.md: ✅ no update needed
  Follow-up TODOs: None
-->

# Specular-AI Constitution

## Core Principles

### I. Gherkin is King (Single Source of Truth)

The `.feature` files in `spec/features/` are the **ONLY** specification
artifacts. No separate markdown spec files (e.g., `spec.md`) MUST be
generated or maintained.

- All planning, implementation, and testing decisions MUST trace back to
  Scenarios and Rules defined in the corresponding `.feature` file.
- Workflow order MUST be: Read Gherkin → Generate Step Definitions (Red)
  → Implement Feature (Green) → Refactor.
- When a Gherkin file is ambiguous or incomplete, the gap MUST be
  resolved by updating the `.feature` file — never by inventing
  requirements in downstream artifacts.

### II. Surgical Precision (Team Collaboration)

This is a multi-contributor repository. Git conflicts are the enemy.

- Every change MUST be the **minimum viable change** required by the
  current task.
- "Drive-by" refactoring of unrelated code, global helpers, or shared
  components is PROHIBITED unless explicitly requested.
- Formatting changes, comment additions, and import reordering outside
  the task scope MUST NOT appear in diffs.

### III. Plug-and-Play Architecture (Modularity)

Code MUST follow the Open/Closed Principle: open for extension, closed
for modification.

- New features SHOULD be delivered as new modules, Service Objects, or
  classes rather than by inflating existing functions.
- Business logic MUST be encapsulated in Service Objects or specialized
  classes. Controllers, Handlers, and Routers MUST remain thin
  (delegation only).
- Cross-cutting concerns (logging, auth, validation) MUST use middleware
  or decorator patterns, not inline code.

### IV. The "Las Vegas" Rule (Service Isolation & Mocking)

What happens inside a service stays inside that service.

- Tests MUST run hermetically — no real network calls, no shared
  database state, no filesystem side-effects.
- Every interaction with an external service (HTTP APIs, gRPC, databases,
  message queues) MUST be mocked by default in unit and integration
  tests.
- Service classes MUST accept dependencies via Dependency Injection so
  that swapping mocks for real clients is seamless.
- End-to-end tests are the ONLY exception and MUST be explicitly marked
  as such.

### V. Modern Pythonic Standards

All new code MUST meet the following bar:

- **Type hints are mandatory** on every function signature
  (e.g., `def func(a: int) -> str:`).
- **Pydantic Models** MUST be used for DTOs, request/response schemas,
  and configuration — raw dictionaries are PROHIBITED for structured
  data crossing module boundaries.
- **PEP 8** MUST be followed. Where PEP 8 conflicts with readability,
  readability wins.
- `async/await` MUST be used for I/O-bound operations in FastAPI
  services.

### VI. Context-Aware Adaptability

Before generating code, the framework and toolchain MUST be detected by
scanning `requirements.txt`, `pyproject.toml`, or `Pipfile`.

- **FastAPI** (current default): Use `async/await`, Pydantic schemas,
  dependency injection via `Depends()`.
- **Django**: Adhere to Django ORM patterns and the standard project
  layout.
- **Flask**: Use the Application Factory pattern and standard extensions.
- Generated code MUST NOT introduce patterns that conflict with the
  project's installed dependencies or established conventions.

### VII. Defensive Coding & Error Handling

Errors MUST be visible, structured, and actionable.

- Bare `try...except` blocks that swallow errors are PROHIBITED. Every
  caught exception MUST be logged with a full stack trace.
- Microservice code MUST use custom exception classes that map to HTTP
  status codes (e.g., `ResourceNotFound` → 404,
  `PermissionDenied` → 403, `ValidationError` → 422).
- **Stop-Loss Rule**: If a task fails (Red light) more than 3 times
  during implementation, work MUST stop and human guidance MUST be
  requested. Infinite fix-break loops are PROHIBITED.

## Development Workflow

1. **Spec phase**: Author or update the `.feature` file in
   `spec/features/`.
2. **Plan phase** (`/speckit.plan`): Read the `.feature` file, produce
   `plan.md` with architecture, contracts, and data model.
3. **Task phase** (`/speckit.tasks`): Decompose the plan into ordered,
   parallelizable tasks grouped by Gherkin Rule / Scenario.
4. **Implement phase** (`/speckit.implement`): Execute tasks following
   Red-Green-Refactor discipline.
5. **Verify phase**: Run the full test suite; every Gherkin Scenario
   MUST map to at least one passing test.

## Quality Gates

| Gate | Criteria |
|------|----------|
| **Spec completeness** | Every Rule has at least one Example (happy + sad path) |
| **Plan approval** | Constitution Check passes; no unresolved NEEDS CLARIFICATION |
| **Task readiness** | All tasks have exact file paths and [P] / dependency annotations |
| **Code merge** | All tests green, type-check passes, linter clean, no unrelated diff |

## Governance

- This constitution supersedes all other development practices and
  style guides within the repository.
- Amendments require: (1) a documented rationale, (2) team review,
  (3) a migration plan for any code that no longer complies.
- All pull requests and code reviews MUST verify compliance with these
  principles.
- Complexity beyond what a principle allows MUST be justified in the
  plan's Complexity Tracking table.

**Version**: 1.1.0 | **Ratified**: 2026-02-10 | **Last Amended**: 2026-02-10
