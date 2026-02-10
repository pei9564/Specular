# Implementation Plan: [FEATURE NAME]

**Branch**: `[###-feature-name]` | **Date**: [DATE]
**Source Feature**: `{{ path_to_feature_file }}`
> **CRITICAL**: This plan is strictly based on the Scenarios and Rules defined in the Gherkin source above. No external spec.md is used.

## Constitution Check (The 7 Commandments)
*GATE: Must pass before proceeding. If any item is unchecked, STOP and fix.*

- [ ] **I. Gherkin is King**: Plan traces directly to `.feature` scenarios.
- [ ] **II. Surgical Precision**: Changes are scoped; minimal diffs; no "drive-by" refactoring.
- [ ] **III. Plug-and-Play**: Logic encapsulated in Service Objects/Modules; Controllers are thin.
- [ ] **IV. Las Vegas Rule**: External calls (HTTP/DB) are isolated and strategy for Mocking is defined.
- [ ] **V. Modern Python**: Type hints on ALL signatures; Pydantic for DTOs; PEP 8 compliant.
- [ ] **VI. Context-Aware**: Framework (FastAPI/Django/Flask) detected and conventions respected.
- [ ] **VII. Defensive Coding**: Error handling defined (no bare `except`); Custom Exceptions used.

## Technical Context
**Framework Detected**: [e.g., FastAPI / Django / Flask or NEEDS CLARIFICATION]
**Async Requirement**: [Yes/No - based on Framework (e.g. FastAPI = Yes)]
**New Dependencies**: [List new libs to add to requirements.txt or N/A]
**Existing Components**: [List existing Services/Models to be reused]

---

## 1. Architecture & Design
> *Rule III: Plug-and-Play Architecture*

* **Summary**: [Brief description of the implementation strategy]
* **New Components**:
    * `[Service/Module Name]`: [Responsibility]
* **Modified Components**:
    * `[File Path]`: [Change description]
* **Data Flow**: [Describe how data moves: API -> Service -> DB]

## 2. Interface Contract (API & Methods)
> *Rule V: Modern Pythonic Standards (Type Hints & Pydantic)*

#### A. API Endpoints (if applicable)
```python
# [Method] [https://www.merriam-webster.com/dictionary/path](https://www.merriam-webster.com/dictionary/path)
# async def endpoint_name(payload: Schema) -> ResponseSchema:

```

#### B. Core Service Methods

```python
# class ServiceName:
#     def method_name(self, arg: int) -> str:
#         """Docstring explaining logic"""

```

## 3. Data Model Changes

> *Rule V: Pydantic Models & DB Schemas*

* **Database Schema**: [SQLAlchemy/ORM changes or N/A]
* **Pydantic Models (DTOs)**:
```python
# class UserRequest(BaseModel):
#     username: str

```

## 4. Step Definitions Mapping

> *Rule I: Gherkin is King - Connect Scenarios to Code*

| Gherkin Step | Target Python Function/Method |
| --- | --- |
| `Given [precondition]` | `tests/steps/[file].py :: [function]` |
| `When [action]` | `app/services/[service].py :: [method]` |
| `Then [outcome]` | `tests/steps/[file].py :: [assertion]` |

## 5. Verification Strategy

> *Rule IV: Las Vegas Rule (Isolation & Mocking)*

* **Unit Tests**:
* Target: `[Service Class]`
* Mocks: `[External API / DB Session]` (How will these be injected?)


* **Integration Tests**:
* Target: `[API Endpoint]`
* Scenarios covered: `[Scenario Names]`



---

## Complexity Tracking

> *Fill ONLY if Constitution principles are violated for justifiable reasons*

| Violation | Why Needed | Simpler Alternative Rejected Because |
| --- | --- | --- |
| [e.g. No Type Hints] | [e.g. Circular dependency issue] | [Refactoring takes too long] |
