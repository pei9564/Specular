---
description: Execute the implementation planning workflow using the plan template to generate design artifacts.
handoffs: 
  - label: Create Tasks
    agent: speckit.tasks
    prompt: Break the plan into tasks
    send: true
  - label: Create Checklist
    agent: speckit.checklist
    prompt: Create a checklist for the following domain...
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

0. **Pre-check: Spec readiness gate**:
   - Read the `.feature` file header tags
   - If `@wip` is present → **STOP**. Output: `Spec is still in DRAFT (@wip). Run /speckit.clarify to audit and sign-off before planning.`
   - If `@ready` is present → proceed
   - This gate is mandated by Constitution §Quality Gates ("Spec status")

1. **Setup**: Run `.specify/scripts/bash/setup-plan.sh --json` from repo root and parse JSON for FEATURE_SPEC, IMPL_PLAN, SPECS_DIR, BRANCH. For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").

2. **Load context**: Read FEATURE_SPEC and `.specify/memory/constitution.md`. Load IMPL_PLAN template (already copied).

3. **Determine Execution Type**: Inspect the `.feature` file to classify the feature:
   - Read the SPEC-KIT SYSTEM INSTRUCTION block for `Type:` (COMMAND or QUERY)
   - If COMMAND, determine sub-type from the feature's trigger:
     - **API_COMMAND**: The `When` steps describe a user-initiated action via API
       (e.g., "When the user creates...", "When the user submits...")
     - **LIFECYCLE_COMMAND**: The `When` steps describe a system-initiated event
       (e.g., "When the system starts up", "When the scheduled job runs",
       "When the message is consumed")
   - If QUERY → **QUERY**
   - Set the `**Execution Type**` field in IMPL_PLAN header
   - Delete the unused §1 variant (keep only the matching one)
   - For API_COMMAND / QUERY: delete the "Application Wiring" subsection in §3
   - For LIFECYCLE_COMMAND: delete the "Variant A" in §1

4. **Execute plan workflow**: Follow the structure in IMPL_PLAN template to:
   - Fill Technical Context (mark unknowns as "NEEDS CLARIFICATION")
   - Fill Constitution Check section from constitution
   - Evaluate gates (ERROR if violations unjustified)
   - Phase 0: Generate research.md (resolve all NEEDS CLARIFICATION)
   - Phase 1: Generate data-model.md, contracts/ (API types only), quickstart.md
   - Phase 1: Update agent context by running the agent script
   - Re-evaluate Constitution Check post-design

5. **Stop and report**: Command ends after Phase 2 planning. Report branch, IMPL_PLAN path, and generated artifacts.

## Phases

### Phase 0: Outline & Research

1. **Extract unknowns from Technical Context** above:
   - For each NEEDS CLARIFICATION → research task
   - For each dependency → best practices task
   - For each integration → patterns task

2. **Generate and dispatch research agents**:

   ```text
   For each unknown in Technical Context:
     Task: "Research {unknown} for {feature context}"
   For each technology choice:
     Task: "Find best practices for {tech} in {domain}"
   ```

3. **Consolidate findings** in `research.md` using format:
   - Decision: [what was chosen]
   - Rationale: [why chosen]
   - Alternatives considered: [what else evaluated]

**Output**: research.md with all NEEDS CLARIFICATION resolved

### Phase 1: Design & Contracts

**Prerequisites:** `research.md` complete

1. **Extract entities from feature spec** → `data-model.md`:
   - Entity name, fields, relationships
   - Validation rules from requirements
   - State transitions if applicable

2. **Generate external interface** based on Execution Type:
   - **API_COMMAND / QUERY**: Generate API contracts from functional requirements.
     For each user action → endpoint. Use standard REST/GraphQL patterns.
     Output OpenAPI/GraphQL schema to `/contracts/`.
   - **LIFECYCLE_COMMAND**: No API contracts. Fill §1 Variant B (Lifecycle Hook)
     with trigger mechanism, entry point, and fail behavior.
     Fill §3 Application Wiring subsection with dependency assembly logic.
     Record `contracts/ → SKIPPED` in the Deviation Log.

3. **Agent context update**:
   - Run `.specify/scripts/bash/update-agent-context.sh claude`
   - These scripts detect which AI agent is in use
   - Update the appropriate agent-specific context file
   - Add only new technology from current plan
   - Preserve manual additions between markers

**Output**: data-model.md, /contracts/*, quickstart.md, agent-specific file

### Phase 1.5: BDD-Architecture Alignment Check (MANDATORY)

**Prerequisites:** Phase 1 design complete (Service Architecture, Data Models, ISA Mapping filled)

This phase enforces Constitution §IV-B (Entry Point Rule). It MUST run before the plan is finalized.

1. **Scenario Walkthrough**: For EACH Scenario in the `.feature` file:
   a. Identify the `When` step (the action under test)
   b. Map it to the designed architecture: which `class.method()` does it invoke?
   c. Trace all `Then` assertions: can they be verified from the return value or mock interactions of that method?
   d. Record the mapping in the BDD Alignment Table

2. **Entry Point Validation**: For each failure Scenario:
   a. Ask: "Does the `When` step actually execute in my architecture?"
   b. If a validation is placed in a layer BEFORE the `When` entry point
      (e.g., Config validator, Pydantic model constructor, middleware):
      - Check: Can the test `Given` step set up the invalid state and still
        reach the `When` step?
      - If YES → mark as PASS (early validation is testable)
      - If NO → mark as **FAIL: Entry Point Violation**
   c. For each FAIL: Move the validation INTO the service method that the
      `When` step invokes. Update Section 2 (Data Models) and Section 3
      (Service Architecture) accordingly.

3. **Wiring Check**: Verify that the `When` entry point can be instantiated
   in the test environment:
   - All constructor dependencies are mockable or injectable
   - If the entry point requires application-level wiring (e.g., `get_auth_service()`),
     document the wiring logic in Service Architecture or a dedicated subsection

4. **Output**: Fill the `## BDD Alignment Check` section in the plan with:
   - Alignment table (Scenario → When step → Entry point → Result)
   - Any Entry Point Violations found and how they were resolved
   - Wiring dependencies identified

5. **Data Integrity Reminder**: If validation logic is moved down to the Service
   layer to satisfy the Entry Point Rule, ensure that Service method is the
   **single point of entry** for the state change. No other component may bypass
   the Service and modify data directly (e.g., calling the repository without
   going through the validated Service method). If multiple callers exist,
   document them in the Wiring Dependencies and verify each one routes through
   the validated entry point.

**Gate**: If any Scenario cannot be mapped to a testable `When` → entry point
flow, the plan MUST NOT proceed. Fix the architecture first.

## Key rules

- Use absolute paths
- ERROR on gate failures or unresolved clarifications
