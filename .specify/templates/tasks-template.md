# Implementation Tasks: [FEATURE NAME]

**Source Plan**: `specs/[feature_name]/plan.md`
**Source Feature**: `{{ path_to_feature_file }}`

> **Constitution Enforcement**:
> 1. **Surgical Precision**: Only touch files listed in the Plan.
> 2. **Las Vegas Rule**: Tasks MUST include "Mocking" steps for external dependencies.
> 3. **Red-Green-Refactor**: Tests must be written (and fail) BEFORE implementation code.

## Phase 1: Preparation & Scaffolding
*Create the file structure defined in the Plan.*

- [ ] **[Scaffold]** Create/Update Pydantic Models in `[path/to/models.py]` (Rule V)
- [ ] **[Scaffold]** Create Service Class stubs in `[path/to/service.py]`
- [ ] **[Scaffold]** Create empty Step Definitions file in `tests/steps/[feature_steps.py]`
- [ ] **[Config]** Update `requirements.txt` if Plan listed new dependencies.

---

## Phase 2: Implementation (Scenario by Scenario)
*Iterate through each Scenario defined in the `.feature` file.*

### Scenario A: [Name from Gherkin]
- [ ] **[Test]** Write failing Step Definitions in `tests/steps/...` (Red State)
- [ ] **[Mock]** Implement Mocks/Fixtures for `[External Dependency]` (Las Vegas Rule)
- [ ] **[Code]** Implement core logic in `app/services/...` (Green State)
- [ ] **[API]** Wire up the Controller/Router endpoint (if applicable)
- [ ] **[Verify]** Run `pytest -k "Scenario Name"` to confirm pass.

### Scenario B: [Name from Gherkin]
- [ ] **[Test]** Write failing Step Definitions...
- [ ] **[Mock]** Adjust Mocks for this scenario...
- [ ] **[Code]** Implement logic...
- [ ] **[Verify]** Run tests...

*(Repeat for all Scenarios in the Feature file)*

---

## Phase 3: Refinement & Quality Gate
*Final checks before marking "Done".*

- [ ] **[Refactor]** Check Type Hints coverage (Rule V: Mandatory Types).
- [ ] **[Refactor]** Ensure no "drive-by" formatting changes in unrelated files.
- [ ] **[Lint]** Run linter/formatter on modified files.
- [ ] **[Final]** Run full feature test suite: `pytest spec/features/[feature_name].feature`