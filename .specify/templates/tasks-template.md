# Implementation Tasks

**Source Plan**: `{{ path_to_plan_file }}`
**ISA Config**: `.specify/config/isa.yml`

## Phase 1: Structure & Skeletons (The Foundation)
>
> *Goal: Create files so tests can import/reference them.*

- [ ] **[Skeleton]** Create `app/schemas/{{ domain }}.py`.
  - *Action*: Port Pydantic models from **Plan Section 2**.
- [ ] **[Skeleton]** Create `app/services/{{ domain }}_service.py`.
  - *Action*: Port Class/Method signatures from **Plan Section 3** (keep `NotImplementedError`).
- [ ] **[Skeleton]** Create `app/routers/{{ domain }}.py`.
  - *Action*: Define FastAPI route per **Plan Section 1** (Inject Service and call it).

## Phase 2: Test Generation (The "RED" State)
>
> *Goal: Generate failing tests for both Logic (Unit) and Contract (API).*

### 2.1 Service Unit Tests (Inner Loop)

- [ ] **[Unit-Test]** Create `tests/unit/test_{{ domain }}_service.py`.
  - **Target**: Test individual methods in `{{ domain_capitalized }}Service`.
  - **Logic**: Use the `[BUSINESS LOGIC STEPS]` in **Plan Section 3** to derive test cases (Happy/Sad paths).
  - **Isolation**: Apply `mocker.patch` based on **Plan Section 4**.

### 2.2 API Integration Tests (Outer Loop)

- [ ] **[ISA-Map]** Generate `tests/steps/test_{{ feature_slug }}.py`.
  - **Rule**: MUST load step patterns from `.specify/config/isa.yml`.
  - **Action**: Map Gherkin steps to API calls using **Plan Section 5**.
  - **Context**: Reference the feature file at `{{ path_to_feature_file }}`.

### 2.3 Verification

- [ ] **[Verify]** Run `pytest` -> **MUST FAIL** (Red).
      *(Expected failure: `NotImplementedError` or `500 Internal Server Error`)*.

## Phase 3: Logic Implementation (The "GREEN" State)
>
> *Goal: Make tests pass by filling in the Skeletons.*

- [ ] **[Logic]** Implement business logic in `app/services/{{ domain }}_service.py`.
      *(Replace `raise NotImplementedError` with logic derived from Gherkin Rules)*.
- [ ] **[Verify]** Run `pytest` -> **MUST PASS** (Green).

## Phase 4: Refactor & Cleanup

- [ ] **[Lint]** Run Type Check (`mypy`) and Linter.
- [ ] **[Checklist]** Complete `checklist.md` to ensure contract adherence.
