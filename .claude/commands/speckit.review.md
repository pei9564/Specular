---
description: Generate a comprehensive review report combining test results, plan execution, and task completion for code review.
handoffs: []
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

1. **Setup**: Run `.specify/scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks` from repo root and parse `FEATURE_DIR` and `AVAILABLE_DOCS` list. All paths must be absolute.

2. **Generate test reports**: Run `docker compose run --rm report`
   - This produces `reports/test-report.html` and `reports/junit.xml`
   - If the command fails, record the failure but continue — report will note test failures

3. **Load all artifacts** from `FEATURE_DIR`:
   - **Required** (STOP if missing):
     - `plan.md` — the implementation plan
     - `tasks.md` — the task breakdown
     - `.feature` file — the Gherkin specification
   - **Optional** (load if exists):
     - `checklists/` — checklist files
     - `research.md` — technical research notes
     - `data-model.md` — entity/relationship documentation
     - `contracts/` — API contract YAML files
   - **Generated** (load if exists after step 2):
     - `reports/junit.xml` — parse for pass/fail/error counts per test file

4. **Parse JUnit XML** (`reports/junit.xml`):
   - Extract total tests, passed, failed, errored, skipped
   - Categorize by file path:
     - Files matching `tests/unit/` → **Unit** layer
     - Files matching `tests/integration/` → **BDD** layer
   - If `reports/junit.xml` does not exist, mark all test sections as "NOT RUN"

5. **Parse BDD Coverage**:
   - Count Gherkin `Scenario:` and `Scenario Outline:` lines in the `.feature` file
   - Count `@scenario(` decorators in `tests/integration/test_*.py`
   - For each scenario, find the matching test function and its pass/fail status from JUnit XML
   - Calculate coverage percentage: `(@scenario count / Gherkin scenario count) * 100`

6. **Parse Plan Execution**:
   - From `plan.md`, extract:
     - **Section 1**: API endpoint (method, URL, status codes)
     - **Section 3**: Architecture (service class, repository dependencies)
     - **Section 6**: ISA mapping (pattern count)
   - Verify each planned artifact exists as a file in the repo

7. **Parse Task Completion**:
   - From `tasks.md`, extract all phases and their tasks
   - For each task, check if marked `[X]` (done) or `[ ]` (pending)
   - Group by phase and calculate completion percentages

8. **Parse Checklists** (if `FEATURE_DIR/checklists/` exists):
   - For each `.md` file in `checklists/`:
     - Count `- [X]` / `- [x]` as completed
     - Count `- [ ]` as incomplete
     - Calculate pass/fail status

9. **Detect files changed**:
   - Run `git diff --stat main...HEAD -- app/ tests/` to list changed files with line counts
   - If this fails (e.g., no `main` branch), try `git diff --stat HEAD~10 -- app/ tests/`

10. **Generate `review.md`** in `FEATURE_DIR/`:

    Use the following template, filling in all sections from parsed data:

    ```markdown
    # Code Review: [Feature Name from .feature file]
    **Branch**: [current git branch]  |  **Date**: [today's date]  |  **Status**: [PASS if all tests pass and tasks done, else FAIL]

    ## Test Results
    | Layer | Total | Passed | Failed | Skipped |
    |-------|-------|--------|--------|---------|
    | Unit  | N     | N      | N      | N       |
    | BDD   | N     | N      | N      | N       |
    | **Total** | **N** | **N** | **N** | **N** |

    [HTML report: reports/test-report.html]

    ## BDD Coverage
    | Gherkin Scenario | Test Function | Status |
    |------------------|---------------|--------|
    | Scenario name... | test_function_name | PASS/FAIL |
    | ...              | ...           | ...    |

    Scenarios in .feature: N  |  @scenario() in test: N  |  Coverage: N%

    ## Plan Execution Summary
    - **API**: [method] [endpoint] → [status codes]
    - **Architecture**: [service] → [repositories]
    - **ISA Patterns**: [count] patterns mapped

    ## Task Completion
    | Phase | Tasks | Done | Status |
    |-------|-------|------|--------|
    | Phase 1: ... | N | N | checkmark or X |
    | Phase 2: ... | N | N | checkmark or X |
    | ...   | ...   | ...  | ...    |
    | **Total** | **N** | **N** | **checkmark/X** |

    ## Checklist Status
    [If checklists/ exists:]
    | Checklist | Total | Passed | Failed | Status |
    |-----------|-------|--------|--------|--------|
    | name.md   | N     | N      | N      | PASS/FAIL |

    [If no checklists: "No checklists found."]

    ## Files Changed
    [Output from git diff --stat, filtered to app/ and tests/]

    ## Review Decision
    - [ ] Ready to Merge — All tests pass, all tasks complete, coverage 100%
    - [ ] Needs Work — [list specific sections that failed]
    ```

11. **Report**: Output the path to the generated `review.md` and print a brief summary:
    - Total tests: N passed, N failed
    - BDD coverage: N%
    - Tasks: N/N complete
    - Overall status: PASS or FAIL

Note: This command requires that tests, plan, and tasks already exist. If any required artifact is missing, suggest running the appropriate `/speckit.*` command first.
