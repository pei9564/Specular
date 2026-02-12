# Implementation Tasks

**Source Plan**: `{{ path_to_plan_file }}`
**ISA Config**: `.specify/config/isa.yml`
**Execution Type**: `{{ execution_type }}`

## Phase 1: Structure & Skeletons (The Foundation)
>
> *Goal: Create files so tests can import/reference them.*

- [ ] **[Skeleton]** Create `app/schemas/{{ domain }}.py`.
  - *Action*: Port Pydantic models from **Plan Section 2**.
- [ ] **[Skeleton]** Create `app/services/{{ domain }}_service.py`.
  - *Action*: Port Class/Method signatures from **Plan Section 3** (keep `NotImplementedError`).

<!--
  Phase 1 branches by Execution Type:
  - API_COMMAND / QUERY: Create a Router that delegates to the Service via Depends().
  - LIFECYCLE_COMMAND: Create application wiring (no Router). The Service is invoked
    by a system event (startup, cron, etc.), not by an HTTP endpoint.
-->

### Variant A: API_COMMAND / QUERY

- [ ] **[Skeleton]** Create `app/routers/{{ domain }}.py`.
  - *Action*: Define FastAPI route per **Plan Section 1** (Inject Service and call it).

### Variant B: LIFECYCLE_COMMAND

- [ ] **[Skeleton]** Create application wiring per **Plan Section 3** (Application Wiring subsection).
  - *Action*: Define the factory/assembly function that instantiates the Service with its dependencies.
  - *Location*: As specified in **Plan Section 1** Variant B (entry point).

## Phase 2: Unit Tests (The Inner Loop — "RED" State)
>
> *Goal: Generate failing unit tests for service logic.*

- [ ] **[Unit-Test]** Create `tests/unit/test_{{ domain }}_service.py`.
  - **Target**: Test individual methods in `{{ domain_capitalized }}Service`.
  - **Logic**: Use the `[BUSINESS LOGIC STEPS]` in **Plan Section 3** to derive test cases (Happy/Sad paths).
  - **Isolation**: Apply `mocker.patch` based on **Plan Section 4**.

## Phase 3: BDD Integration Tests (The Outer Loop — MANDATORY)
>
> *Goal: Generate `pytest-bdd` step definitions that wire every Gherkin Scenario to a test.*
>
> **GATE**: This phase is **NOT optional**. Every Gherkin Scenario in the feature file MUST have a corresponding integration test. Skip = checklist failure.

<!--
  Phase 3 infrastructure docs branch by Execution Type.
  Fill ONLY the variant matching the Execution Type from the Plan header. Delete the other.
-->

### Infrastructure: API_COMMAND / QUERY

> **Architecture**: All BDD tests MUST use the shared infrastructure in `tests/integration/conftest.py`:
> - **`table_to_dicts(datatable)`** — converts pytest-bdd datatable (`list[list[str]]`) to `list[dict]`. NEVER parse datatables manually.
> - **`context` fixture** — mutable state carrier for Given → When → Then. When steps accumulate `context["payload"]` from data tables. Then steps read `context["response"]`.
> - **`ensure_called(context, client, {{ mock_repo }})`** — lazy API trigger. Called by Then steps before any assertion. Fires the HTTP request ONCE per scenario, configures mocks from `context["background_*"]`, caches response.
> - **`app` / `client` fixtures** — FastAPI app factory with mocked repos + auth middleware.
> - **Common Given steps** — auth, background entities, preconditions. Do NOT redefine these in test files.
>
> **Test file structure**: Each `test_{{ feature_slug }}.py` contains ONLY:
> 1. `@scenario()` decorators — 1:1 mapping from Gherkin
> 2. Feature-specific When steps (API_CALL) — parse data tables into `context["payload"]`
> 3. Feature-specific Then steps (API_ASSERT / DB_ASSERT) — call `ensure_called()`, then assert

### Infrastructure: LIFECYCLE_COMMAND

> **Architecture**: All BDD tests MUST use the shared infrastructure in `tests/integration/conftest.py`:
> - **`table_to_dicts(datatable)`** — converts pytest-bdd datatable (`list[list[str]]`) to `list[dict]`. NEVER parse datatables manually.
> - **`context` fixture** — mutable state carrier for Given → When → Then. Given steps set up `context["config"]`. When steps invoke the service directly and store results in `context["result"]`.
> - **No HTTP client** — LIFECYCLE_COMMAND tests do NOT use `app`, `client`, or `ensure_called()`. The service is instantiated directly with mocked dependencies.
> - **Common Given steps** — background entities, preconditions. Do NOT redefine these in test files.
>
> **Context flow**:
> - `context["config"]` ← Given steps (configuration setup, e.g., `{{ config_class }}`)
> - `context["result"]` ← When step stores return value OR caught exception
>
> **Test file structure**: Each `test_{{ feature_slug }}.py` contains ONLY:
> 1. `@scenario()` decorators — 1:1 mapping from Gherkin
> 2. Feature-specific Given steps (CONFIG_SETUP) — set up config in `context["config"]`
> 3. Feature-specific When steps (SERVICE_CALL) — `await {{ service }}.{{ method }}()`, store result or exception
> 4. Feature-specific Then steps (SERVICE_ASSERT / EXCEPTION_ASSERT) — assert `context["result"]`

### Tasks

- [ ] **[ISA-Map]** Generate `tests/integration/test_{{ feature_slug }}.py`.
  - **Source**: Read `.specify/config/isa.yml` and match with **Plan Section 6** (ISA Mapping).
  - **ISA Layer**: Use the `api` layer for API_COMMAND / QUERY, or the `service` layer for LIFECYCLE_COMMAND.
  - **Shared Infra**: Import `table_to_dicts` from `tests.integration.conftest`. Reuse `context` fixture — do NOT redefine it.
  - **Action**: Create `pytest-bdd` step definitions that link to `{{ path_to_feature_file }}`.
  - **Context Flow**: Follow the context flow documented in the Infrastructure section above.
  - **Coverage rule**: Count Gherkin Scenarios in `.feature` file → assert equal number of `@scenario()` decorators in test file.
- [ ] **[Verify-BDD]** Run BDD tests in Docker → confirm scenario count matches.
      *Command*: `docker compose run --rm test pytest tests/integration/test_{{ feature_slug }}.py -v`

## Phase 3.5: Verify RED State (TDD Gate — MANDATORY)
>
> *Goal: Prove tests FAIL before implementation. If all tests pass here, the tests are not testing real logic.*
>
> **GATE**: This phase confirms TDD discipline. Skeletons have `raise NotImplementedError`, so all unit and BDD tests MUST fail. A passing suite means tests are vacuous.

- [ ] **[Verify-RED]** Run full test suite in Docker → **MUST FAIL**.
      *Command*: `docker compose run --rm test || true`
      - **Expected**: Non-zero exit code. All tests that hit service methods should raise `NotImplementedError`.
      - **Record**: Note the failure count (e.g. "8 unit + 8 BDD = 16 FAILED"). This count MUST match the GREEN count in Phase 4.
      - **If all tests PASS**: STOP. Tests are not exercising real logic. Review test assertions before proceeding.

## Phase 4: Logic Implementation (The "GREEN" State)
>
> *Goal: Make ALL tests (unit + BDD) pass by filling in the Skeletons.*
> The failure count from **[Verify-RED]** must match the pass count here. No test should be silently dropped.

- [ ] **[Logic]** Implement business logic in `app/services/{{ domain }}_service.py`.
      *(Replace `raise NotImplementedError` with logic derived from Gherkin Rules)*.
- [ ] **[Verify-GREEN]** Run full test suite in Docker → **MUST PASS**.
      *Command*: `docker compose run --rm test`
      - **Verify**: Pass count == failure count from [Verify-RED]. No tests were removed or skipped.

## Phase 5: Refactor & Cleanup

- [ ] **[Lint]** Run Type Check and Linter in Docker.
      *Command*: `docker compose run --rm lint`
- [ ] **[Report]** Generate test reports (HTML + JUnit XML).
      *Command*: `docker compose run --rm report`
- [ ] **[Checklist]** Complete `checklist.md` to ensure contract adherence.
