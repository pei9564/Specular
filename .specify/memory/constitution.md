# Specular-AI Constitution

## Core Principles

### I. Gherkin is King (Single Source of Truth)

The `.feature` files in `specs/features/` are the **ONLY** specification
artifacts. No separate markdown spec files (e.g., `spec.md`) MUST be
generated or maintained.

- All planning, implementation, and testing decisions MUST trace back to
  Scenarios and Rules defined in the corresponding `.feature` file.
- Workflow order MUST be: Read Gherkin → Generate Step Definitions (Red)
  → Implement Feature (Green) → Refactor.
- When a Gherkin file is ambiguous or incomplete, the gap MUST be
  resolved by updating the `.feature` file — never by inventing
  requirements in downstream artifacts.

### I-B. Schema as Living Truth (DBML Lifecycle)

Database schema definitions in `specs/db_schema/<domain>.dbml` follow a
two-phase lifecycle:

1. **Provisional** (`@provisional` tag present): Auto-generated during
   the Spec phase based on entities inferred from the feature description.
   Field names, types, and constraints are best-effort drafts.
   - Scenarios in `.feature` files MUST use provisional field names
     as-is (no separate guesses).
   - Provisional schemas MUST be reviewed and ratified before the
     Plan phase begins.

2. **Ratified** (no `@provisional` tag): Reviewed during Clarify or
   Plan phase. Once ratified, DBML becomes the Absolute Truth per
   existing convention.
   - Any subsequent feature in the same domain MUST extend (not
     replace) the ratified schema.
   - Field renames after ratification require a migration note in
     the plan.

**Generation Rules**:
- If `specs/db_schema/<domain>.dbml` does not exist when a feature
  enters the Spec phase, the specify step MUST generate a provisional
  DBML before writing scenarios.
- If it already exists (ratified), new tables/fields are appended
  with `@provisional` on the new parts only.
- A domain DBML file MUST NEVER be regenerated from scratch if a
  ratified version exists.

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

### VIII. Clarify Command Protocol (Auto-QA)

**Trigger**: When the user invokes `/speckit.clarify`.
**Role**: Acting as a Strict QA Automation Engineer.
**Mandatory Task**: Perform a "Schema & Logic Consistency Check" WITHOUT asking for further instructions.

**Checklist to Execute Automatically**:

1. **DBML Consistency Check**:
    - Scan all fields in the Gherkin feature.
    - Compare them against the provided `@...dbml` context.
    - *Error if:* Field names do not match exactly (e.g., `user_id` vs `userId`).
    - *Error if:* A `NOT NULL` field in DBML is missing a validation scenario in Gherkin.
2. **Naming Convention Check**:
    - *Command Feature:* Must use "XX 必須/只能 YY" (Precondition) and "XX 應該 ZZ" (Postcondition).
    - *Query Feature:* Must use "XX 必須/只能 YY" (Precondition) and "成功查詢應 XX" (Success).
3. **@auto_generated Audit**:
    - Review scenarios tagged `@auto_generated`.
    - Flag any that seem redundant or logically impossible (e.g., checking uniqueness on a non-unique field).

**Output Format**:
Provide a structured report:

- ✅ **PASS**: [List of passed checks]
- ⚠️ **WARNING**: [Potential logic gaps or redundancies]
- ❌ **FAIL**: [Schema mismatches or Naming violations]

## Development Workflow

1. **Spec phase** (`/speckit.specify`): Author the `.feature` file in
   `specs/features/` and generate provisional DBML if needed (see §I-B).
   Output status: **[DRAFT]**. Produce an empty `requirements.md`
   checklist — do NOT self-validate.
2. **Clarify phase** (`/speckit.clarify`): Perform evidence-based audit
   of the `.feature` file. Fill `requirements.md` with cited evidence
   for each item. Transition status from `@wip` → `@ready` only when
   all items pass including the mandatory Audit Gate. If DBML is still
   `@provisional`, flag it for ratification.
3. **Plan phase** (`/speckit.plan`): Read the `.feature` file, produce
   `plan.md` with architecture, contracts, and data model. Any
   `@provisional` DBML MUST be ratified (tag removed) before plan is
   approved.
4. **Task phase** (`/speckit.tasks`): Decompose the plan into ordered,
   parallelizable tasks grouped by Gherkin Rule / Scenario.
5. **Implement phase** (`/speckit.implement`): Execute tasks following
   Red-Green-Refactor discipline.
6. **Verify phase**: Run the full test suite; every Gherkin Scenario
   MUST map to at least one passing test.

## Quality Gates

| Gate | Criteria |
|------|----------|
| **Spec completeness** | Every Rule has at least one Example (happy + sad path) |
| **Spec status** | `.feature` header contains `@ready` tag (set by `/speckit.clarify`). `@wip` specs MUST NOT enter Plan phase |
| **Clarify Check** | Auto-QA report shows no ❌ FAIL; Audit Gate items (improvement + boundary risk) are filled |
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

**Version**: 1.4.0 | **Ratified**: 2026-02-11 | **Last Amended**: 2026-02-12
