---
description: Audit the feature spec with evidence-based checklist, resolve ambiguities, and sign-off for planning.
handoffs:
  - label: Build Technical Plan
    agent: speckit.plan
    prompt: Create a plan for the spec. I am building with...
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

Goal: Perform an evidence-based audit of the feature specification, resolve ambiguities, fill the requirements checklist with cited evidence, and sign-off the spec for planning.

Note: This workflow MUST be completed BEFORE invoking `/speckit.plan`. The `.feature` file MUST transition from `@wip` to `@ready` here. If the user explicitly states they are skipping clarification (e.g., exploratory spike), you may proceed, but must warn that downstream rework risk increases.

Execution steps:

## Phase 1: Setup & Load

1. Run `.specify/scripts/bash/check-prerequisites.sh --json --paths-only` from repo root **once** (combined `--json --paths-only` mode / `-Json -PathsOnly`). Parse minimal JSON payload fields:
   - `FEATURE_DIR`
   - `FEATURE_SPEC`
   - (Optionally capture `IMPL_PLAN`, `TASKS` for future chained flows.)
   - If JSON parsing fails, abort and instruct user to re-run `/speckit.specify` or verify feature branch environment.
   - For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").

2. Load the following files:
   - `FEATURE_SPEC` (the `.feature` file)
   - `FEATURE_DIR/checklists/requirements.md` (the empty checklist from specify)
   - `specs/db_schema/<domain>.dbml` (check provisional/ratified status)
   - `.specify/memory/constitution.md` (for naming convention rules)

3. **Pre-check**: Verify `.feature` file has `@wip` tag. If `@ready` is already present, report "Spec already audited" and suggest proceeding to `/speckit.plan`.

## Phase 2: Evidence-Based Audit

4. **Fill the requirements checklist** (`FEATURE_DIR/checklists/requirements.md`):

   For EACH checklist item:
   a. Search the `.feature` file for matching evidence
   b. If evidence found → check the item `[x]` and replace `_[evidence]_` with the specific Scenario name, line reference, or quoted text
   c. If NOT found → leave unchecked `[ ]` and replace `_[evidence]_` with a description of what is missing

   **CRITICAL**: Do NOT rubber-stamp. Every `[x]` MUST have a concrete citation. If you cannot point to a specific Scenario or line, the item is NOT passed.

5. **Audit Gate** (MANDATORY — cannot be skipped):
   - You MUST identify at least 1 improvement suggestion (optimization, clarity, consistency)
   - You MUST identify at least 1 boundary risk (uncovered edge case, weak coverage, race condition)
   - If unable to find any, re-examine with adversarial lens: "What would a hostile user, edge case, or race condition break?"
   - Record findings in the Audit Gate section of the checklist

6. **DBML Consistency Check** (from Constitution §VIII):
   - Scan all fields referenced in `.feature` scenarios
   - Compare against `<domain>.dbml` — field names must match exactly
   - If DBML is `@provisional`: flag for ratification, but still validate name consistency
   - Error if: field names mismatch, NOT NULL field lacks failure scenario, UNIQUE field lacks duplicate scenario

7. **Naming Convention Check** (from Constitution §VIII):
   - Command Feature: Precondition Rules must use "XX 必須/只能 YY"; Postcondition Rules must use "XX 應該 ZZ"
   - Query Feature: Precondition Rules must use "XX 必須/只能 YY"; Success Rules must use "成功查詢應 XX"

8. **@auto_generated Audit**:
   - Review scenarios tagged `@auto_generated`
   - Flag any that seem redundant or logically impossible

## Phase 3: Ambiguity Resolution (Interactive)

9. Perform a structured ambiguity & coverage scan using this taxonomy. For each category, mark status: Clear / Partial / Missing. Produce an internal coverage map used for prioritization (do not output raw map unless no questions will be asked).

   Functional Scope & Behavior:
   - Core user goals & success criteria
   - Explicit out-of-scope declarations
   - User roles / personas differentiation

   Domain & Data Model:
   - Entities, attributes, relationships
   - Identity & uniqueness rules
   - Lifecycle/state transitions
   - Data volume / scale assumptions

   Interaction & UX Flow:
   - Critical user journeys / sequences
   - Error/empty/loading states
   - Accessibility or localization notes

   Non-Functional Quality Attributes:
   - Performance (latency, throughput targets)
   - Scalability (horizontal/vertical, limits)
   - Reliability & availability (uptime, recovery expectations)
   - Observability (logging, metrics, tracing signals)
   - Security & privacy (authN/Z, data protection, threat assumptions)
   - Compliance / regulatory constraints (if any)

   Integration & External Dependencies:
   - External services/APIs and failure modes
   - Data import/export formats
   - Protocol/versioning assumptions

   Edge Cases & Failure Handling:
   - Negative scenarios
   - Rate limiting / throttling
   - Conflict resolution (e.g., concurrent edits)

   Constraints & Tradeoffs:
   - Technical constraints (language, storage, hosting)
   - Explicit tradeoffs or rejected alternatives

   Terminology & Consistency:
   - Canonical glossary terms
   - Avoided synonyms / deprecated terms

   Completion Signals:
   - Acceptance criteria testability
   - Measurable Definition of Done style indicators

   Misc / Placeholders:
   - TODO markers / unresolved decisions
   - Ambiguous adjectives ("robust", "intuitive") lacking quantification

   For each category with Partial or Missing status, add a candidate question opportunity unless:
   - Clarification would not materially change implementation or validation strategy
   - Information is better deferred to planning phase (note internally)

10. Generate (internally) a prioritized queue of candidate clarification questions (maximum 5). Do NOT output them all at once. Apply these constraints:
    - Maximum of 10 total questions across the whole session.
    - Each question must be answerable with EITHER:
       - A short multiple‑choice selection (2–5 distinct, mutually exclusive options), OR
       - A one-word / short‑phrase answer (explicitly constrain: "Answer in <=5 words").
    - Only include questions whose answers materially impact architecture, data modeling, task decomposition, test design, UX behavior, operational readiness, or compliance validation.
    - Ensure category coverage balance: attempt to cover the highest impact unresolved categories first; avoid asking two low-impact questions when a single high-impact area (e.g., security posture) is unresolved.
    - Exclude questions already answered, trivial stylistic preferences, or plan-level execution details (unless blocking correctness).
    - Favor clarifications that reduce downstream rework risk or prevent misaligned acceptance tests.
    - If more than 5 categories remain unresolved, select the top 5 by (Impact * Uncertainty) heuristic.

11. Sequential questioning loop (interactive):
    - Present EXACTLY ONE question at a time.
    - For multiple‑choice questions:
       - **Analyze all options** and determine the **most suitable option** based on:
          - Best practices for the project type
          - Common patterns in similar implementations
          - Risk reduction (security, performance, maintainability)
          - Alignment with any explicit project goals or constraints visible in the spec
       - Present your **recommended option prominently** at the top with clear reasoning (1-2 sentences explaining why this is the best choice).
       - Format as: `**Recommended:** Option [X] - <reasoning>`
       - Then render all options as a Markdown table:

       | Option | Description |
       |--------|-------------|
       | A | <Option A description> |
       | B | <Option B description> |
       | C | <Option C description> (add D/E as needed up to 5) |
       | Short | Provide a different short answer (<=5 words) (Include only if free-form alternative is appropriate) |

       - After the table, add: `You can reply with the option letter (e.g., "A"), accept the recommendation by saying "yes" or "recommended", or provide your own short answer.`
    - For short‑answer style (no meaningful discrete options):
       - Provide your **suggested answer** based on best practices and context.
       - Format as: `**Suggested:** <your proposed answer> - <brief reasoning>`
       - Then output: `Format: Short answer (<=5 words). You can accept the suggestion by saying "yes" or "suggested", or provide your own answer.`
    - After the user answers:
       - If the user replies with "yes", "recommended", or "suggested", use your previously stated recommendation/suggestion as the answer.
       - Otherwise, validate the answer maps to one option or fits the <=5 word constraint.
       - If ambiguous, ask for a quick disambiguation (count still belongs to same question; do not advance).
       - Once satisfactory, record it in working memory (do not yet write to disk) and move to the next queued question.
    - Stop asking further questions when:
       - All critical ambiguities resolved early (remaining queued items become unnecessary), OR
       - User signals completion ("done", "good", "no more"), OR
       - You reach 5 asked questions.
    - Never reveal future queued questions in advance.
    - If no valid questions exist at start, skip to Phase 4.

12. Integration after EACH accepted answer (incremental update approach):
    - Maintain in-memory representation of the spec (loaded once at start) plus the raw file contents.
    - For the first integrated answer in this session:
       - Ensure a `## Clarifications` section exists (create it just after the highest-level contextual/overview section per the spec template if missing).
       - Under it, create (if not present) a `### Session YYYY-MM-DD` subheading for today.
    - Append a bullet line immediately after acceptance: `- Q: <question> → A: <final answer>`.
    - Then immediately apply the clarification to the most appropriate section(s):
       - Functional ambiguity → Update or add a bullet in Functional Requirements.
       - User interaction / actor distinction → Update User Stories or Actors subsection (if present) with clarified role, constraint, or scenario.
       - Data shape / entities → Update Data Model (add fields, types, relationships) preserving ordering; note added constraints succinctly.
       - Non-functional constraint → Add/modify measurable criteria in Non-Functional / Quality Attributes section (convert vague adjective to metric or explicit target).
       - Edge case / negative flow → Add a new bullet under Edge Cases / Error Handling (or create such subsection if template provides placeholder for it).
       - Terminology conflict → Normalize term across spec; retain original only if necessary by adding `(formerly referred to as "X")` once.
    - If the clarification invalidates an earlier ambiguous statement, replace that statement instead of duplicating; leave no obsolete contradictory text.
    - Save the spec file AFTER each integration to minimize risk of context loss (atomic overwrite).
    - Preserve formatting: do not reorder unrelated sections; keep heading hierarchy intact.
    - Keep each inserted clarification minimal and testable (avoid narrative drift).

## Phase 4: Fix, Validate & Sign-Off

13. **Address audit failures**: For each unchecked item in the checklist:
    - Update the `.feature` file to address the gap (add missing scenarios, fix naming, etc.)
    - Re-check the item with new evidence
    - Maximum 2 fix iterations — if items still fail after 2 rounds, document in Notes

14. **Re-validate checklist** after all fixes:
    - Every `[x]` item must still have valid evidence
    - Audit Gate items must be filled

15. Validation checks:
    - Clarifications session contains exactly one bullet per accepted answer (no duplicates).
    - Total asked (accepted) questions ≤ 5.
    - Updated sections contain no lingering vague placeholders the new answer was meant to resolve.
    - No contradictory earlier statement remains (scan for now-invalid alternative choices removed).
    - Markdown structure valid; only allowed new headings: `## Clarifications`, `### Session YYYY-MM-DD`.
    - Terminology consistency: same canonical term used across all updated sections.

16. **State transition**:
    - If ALL checklist items pass (including Audit Gate):
       → Change `@wip` to `@ready` in the `.feature` file
       → Update checklist Status to: `READY FOR PLANNING`
    - If items remain unchecked after 2 fix iterations:
       → Keep `@wip`
       → Update checklist Status to: `DRAFT - NEEDS MANUAL REVIEW`
       → List remaining issues in checklist Notes

17. Write updated files:
    - `.feature` file (with fixes, clarifications, and tag update)
    - `checklists/requirements.md` (with evidence and audit results)

## Phase 5: Report

18. **Output structured report**:

    ```
    ## Audit Report: [Feature Name]

    **Status**: [READY FOR PLANNING] or [DRAFT - NEEDS MANUAL REVIEW]
    **Spec**: [path]
    **Checklist**: [path]

    ### Checklist Results
    - Passed: X/Y items
    - Failed: Z items (list names)

    ### Audit Gate Findings
    - Improvement: [finding]
    - Boundary Risk: [finding]

    ### Clarifications
    - Questions asked: N
    - Sections touched: [list]

    ### Auto-QA Results
    - ✅ PASS: [list]
    - ⚠️ WARNING: [list]
    - ❌ FAIL: [list]

    ### Coverage Summary
    | Category | Status |
    |----------|--------|
    | ... | Clear / Resolved / Deferred / Outstanding |

    ### Next Step
    → `/speckit.plan` (if READY) or fix issues and re-run `/speckit.clarify`
    ```

Behavior rules:

- If no meaningful ambiguities found (or all potential questions would be low-impact), skip Phase 3 questioning but STILL complete Phase 2 audit and Phase 4 sign-off.
- If spec file missing, instruct user to run `/speckit.specify` first (do not create a new spec here).
- Never exceed 5 total asked questions (clarification retries for a single question do not count as new questions).
- Avoid speculative tech stack questions unless the absence blocks functional clarity.
- Respect user early termination signals ("stop", "done", "proceed") — but ALWAYS complete Phase 2 audit even if user skips questions.
- If quota reached with unresolved high-impact categories remaining, explicitly flag them under Deferred with rationale.

Context for prioritization: $ARGUMENTS
