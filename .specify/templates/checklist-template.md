# Quality Assurance & Pre-Merge Checklist: [FEATURE NAME]

**Target Feature**: `{{ path_to_feature_file }}`
**Related Plan**: `{{ path_to_plan_file }}`
**Related Schema**: `{{ path_to_dbml_file }}`

> **Purpose**: This checklist serves as the final **Quality Gate** before merging code.
> **Audience**: Author (Self-Review) & Reviewers.

## 1. Contract Adherence (The "Plan" Gate)

*Verify implementation matches the approved design.*

- [ ] **[API]** Endpoints (URL, Method, Body) match the **API Specification** defined in `plan.md`.
- [ ] **[Schema]** Pydantic Models match the **Data Contracts** defined in `plan.md`.
- [ ] **[DBML]** Database constraints (NotNull, Unique, Length) are correctly reflected in Pydantic `Field(...)` validations.

## 2. Testing Excellence (The "TDD" Gate)

*Verify both Integration and Unit test quality.*

- [ ] **[Integration]** Every Gherkin Scenario has a passing test using **ISA patterns** from `isa.yml`.
- [ ] **[Unit]** Service methods have dedicated unit tests covering both **Happy Path** and **Edge Cases** (Sad Path).
- [ ] **[Mock]** All external dependencies identified in `plan.md` are mocked; no real I/O in tests.
- [ ] **[Coverage]** No `NotImplementedError` or `TODO` remains in the implementation.

## 3. Pythonic & Architectural Hygiene

*Verify modern Python practices and modularity.*

- [ ] **[Types]** 100% Type Hints on all new function signatures.
- [ ] **[DI]** Service classes use Dependency Injection; no hardcoded instantiations.
- [ ] **[Layer]** **Router is thin**: It only handles request parsing and service delegation.
- [ ] **[Layer]** **Service is pure**: It contains all business logic and remains testable in isolation.
- [ ] **[Error]** Custom exceptions are used (mapped to HTTP codes), no bare `except: pass`.

## 4. Gherkin & Metadata Integrity

*Verify traceability and cleanliness.*

- [ ] **[Trace]** Implementation code maps 1:1 to the Gherkin Rules.
- [ ] **[Clean]** No "Pending" or "Skipped" steps in the final commit.
- [ ] **[Scope]** The PR does NOT include reformatting of unrelated files ("Drive-by refactoring").

## 5. Deployment Readiness

- [ ] **[Async]** `async/await` is used correctly for I/O bound operations.
- [ ] **[Files]** No circular imports introduced.

---

**Review Decision:**

- [ ] ✅ **Ready to Merge**: All checks passed.
- [ ] 🚧 **Needs Work**: Violations found in section [X].
