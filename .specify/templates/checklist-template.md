# Quality Assurance & Pre-Merge Checklist: [FEATURE NAME]

**Target Feature**: `{{ path_to_feature_file }}`
**Related Plan**: `specs/[feature_name]/plan.md`

> **Purpose**: This checklist serves as the final **Quality Gate** before merging code.
> **Audience**: Author (Self-Review) & Reviewers.

## 1. The "Las Vegas" Protocol (Rule IV)
*Verify isolation and mocking strategies.*

- [ ] **[Mock]** All external API calls (HTTP/gRPC) are mocked in tests. No real network requests.
- [ ] **[DB]** Tests use transaction rollbacks or isolated DB fixtures; no state leakage.
- [ ] **[DI]** Service classes use Dependency Injection (e.g., `client: HttpClient = Depends(...)`).

## 2. Pythonic Standards (Rule V & VI)
*Verify modern Python practices.*

- [ ] **[Types]** 100% Type Hints on all NEW function signatures (`def func(a: int) -> str:`).
- [ ] **[Schema]** Data crossing boundaries (API inputs/outputs) uses **Pydantic Models**, not `dict`.
- [ ] **[Async]** `async/await` is used correctly for I/O bound operations (if FastAPI).
- [ ] **[Style]** Code passes `ruff` / `black` / `flake8` (as configured).
- [ ] **[Error]** No bare `except Exception: pass`. Custom exceptions are used.

## 3. Gherkin Integrity (Rule I)
*Verify traceability back to requirements.*

- [ ] **[Trace]** Every Scenario in the `.feature` file has a passing test.
- [ ] **[Step]** Step definitions are reusable and not hardcoded to a single scenario logic.
- [ ] **[Gap]** No "Pending" or "Skipped" steps in the final commit.

## 4. Architectural Hygiene (Rule II & III)
*Verify modularity and surgical precision.*

- [ ] **[Scope]** The PR does NOT include reformatting of unrelated files ("Drive-by refactoring").
- [ ] **[Layer]** Controller/Router logic is thin; business logic resides in Service Objects.
- [ ] **[Files]** No circular imports introduced.

## 5. Manual Verification (Smoke Test)
*If applicable, verify strictly necessary manual steps.*

- [ ] **[Env]** New environment variables (if any) are documented in `.env.example`.
- [ ] **[Mig]** Database migrations (if any) run successfully up and down.

---

**Review Decision:**
- [ ] ✅ **Ready to Merge**: All checks passed.
- [ ] 🚧 **Needs Work**: Violations found in section [X].