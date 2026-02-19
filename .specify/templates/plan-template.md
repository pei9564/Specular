# Implementation Plan: [FEATURE NAME]

**Branch**: `{{ branch_name }}`
**Source Feature**: `{{ path_to_feature_file }}`
**Instruction Set**: `.specify/config/isa.yml`
**Execution Type**: `{{ API_COMMAND | LIFECYCLE_COMMAND | QUERY }}`

<!--
  Execution Type is determined from the .feature file:
  - API_COMMAND:       COMMAND type + triggered by user action via HTTP (has API caller)
  - LIFECYCLE_COMMAND: COMMAND type + triggered by system event (startup, cron, queue, migration)
  - QUERY:            QUERY type (read-only, always has HTTP endpoint)

  The Execution Type drives which variant of §1 and §6 to use,
  and whether §3 needs an Application Wiring subsection.
-->

## 1. External Interface

<!--
  Fill ONLY the variant matching your Execution Type. Delete the others.
-->

### Variant A: API Contract (API_COMMAND / QUERY)

> **Purpose**: Defines the HTTP contract for Integration Tests.

```yaml
paths:
  # Map Gherkin Action: "{{ action_description }}"
  /api/{{ domain }}/{{ action_slug }}:
    {{ http_method }}:
      summary: "{{ summary }}"
      operationId: "{{ op_id }}"
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/{{ request_model }}'
      responses:
        200:
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/{{ response_model }}'

```

### Variant B: Lifecycle Hook (LIFECYCLE_COMMAND)

> **Purpose**: Defines the system event trigger. No HTTP endpoint.

**Trigger**: {{ event type — e.g., FastAPI lifespan, cron schedule, message queue consumer }}
**Entry Point**: `{{ module.function or Class.method }}`
**Fail Behavior**: {{ fail-fast (abort) | degrade (log + continue) | retry (with backoff) }}

```python
# {{ trigger registration code snippet }}
```

## 2. Data Models (The Shared Contract)

> **Instruction**: Define Pydantic Models. MUST match `specs/db_schema/*.dbml`.

```python
# app/schemas/{{ domain }}.py
class {{ request_model }}(BaseModel):
    # Define fields based on DBML constraints
    pass

class {{ response_model }}(BaseModel):
    # Define response fields
    pass

```

## 3. Service Architecture (The Internal Skeleton)

> **Instruction**: Define Class and Method signatures.
> **Note**: This skeleton will be used for both **Unit Testing** and **Implementation**.

```python
# app/services/{{ domain }}_service.py
class {{ domain_capitalized }}Service:
    def __init__(self, repo: {{ domain_capitalized }}Repository):
        self.repo = repo

    def {{ method_name }}(self, user_id: str, req: {{ request_model }}) -> {{ response_model }}:
        """
        [BUSINESS LOGIC STEPS]
        1. Step one (e.g., Validation)
        2. Step two (e.g., DB Persistence)
        3. Step three (e.g., Result Mapping)
        """
        # Skeleton Phase: Always raise NotImplementedError
        raise NotImplementedError("Skeleton created. Implementation pending Phase 3.")

```

### Application Wiring (LIFECYCLE_COMMAND only)

<!--
  For LIFECYCLE_COMMAND features, the Service is not invoked by a Router.
  Document how the Service is instantiated and called during the system event.
  For API_COMMAND / QUERY, delete this subsection — the Router handles wiring via Depends().

  IMPORTANT — deferred repository: If no concrete repository implementation exists yet,
  keep `raise NotImplementedError("Wiring pending implementation.")` as the stub.
  Do NOT substitute an InMemoryRepository — it loses all state on restart, which
  silently breaks idempotency (every restart re-creates records that should exist).
  Record the missing implementation as a dependency in §9 Deviation Log.
-->

> **Instruction**: Define how the Service is assembled and invoked at the trigger point.
> This must match the entry point declared in §1 Variant B.

```python
# {{ wiring location, e.g., app/main.py or app/startup.py }}

def get_{{ domain }}_service() -> {{ domain_capitalized }}Service:
    """Assemble dependencies and return configured service instance."""
    # config = {{ config_class }}()
    # repo = {{ repo_implementation }}()
    # return {{ domain_capitalized }}Service(repo=repo, config=config)
    raise NotImplementedError("Wiring pending implementation.")
```

## 4. Mocking Strategy (The Las Vegas Rule)

> **Instruction**: List external dependencies to be mocked in both Unit and Integration tests.

* **External Service**: `{{ service_name }}`
* **Mock Path**: `app.services.{{ domain }}_service.{{ dependency }}`
* **Expected Mock Data**: [Briefly describe the mock return value]

## 5. Development Environment

> **Instruction**: All code execution (tests, lint, type checks) MUST run inside Docker.

```bash
# Run all tests
docker compose run --rm test

# Run specific test file
docker compose run --rm test pytest tests/unit/test_{{ domain }}_service.py -v

# Run type check
docker compose run --rm lint

# Run a one-off command
docker compose run --rm app <command>
```

**Required files** (create if missing):
- `Dockerfile` — Python image with `requirements.txt` installed
- `docker-compose.yml` — Services: `app`, `test`, `lint` (and `db` when needed)
- `requirements.txt` — All runtime + dev dependencies

## 6. ISA Mapping (Test Generation Guide)

> **Instruction**: Map Gherkin Phrases to ISA Patterns.
> This section guides `/speckit.tasks` in generating `tests/integration/`.
>
> **Pattern selection by Execution Type**:
> - **API_COMMAND / QUERY**: Use `API_CALL` / `API_ASSERT` patterns (tests use HTTP client)
> - **LIFECYCLE_COMMAND**: Use `SERVICE_CALL` / `SERVICE_ASSERT` patterns (tests invoke Service directly)
>
> **When step parameter variants**: If a `When` step has a parameterised form
> (e.g., `When the system executes ... with username "admin"`), it needs its own
> `@when(parsers.parse(...))` step definition — it cannot share the bare `@when`
> of the parameter-free variant. Flag these in the mapping table with a `[param]` note.

### ISA Pattern Reference

| Execution Type | When Pattern | Then Pattern | Test Trigger |
|----------------|-------------|-------------|--------------|
| API_COMMAND | `API_CALL` | `API_ASSERT` | `httpx` TestClient → Router → Service |
| LIFECYCLE_COMMAND | `SERVICE_CALL` | `SERVICE_ASSERT` | Direct `await service.method()` |
| QUERY | `API_CALL` | `API_ASSERT` | `httpx` TestClient → Router → Service |

### Gherkin → ISA Mapping

| Gherkin Phrase | ISA Pattern | Target Implementation |
| --- | --- | --- |
| `(UID={user_id}) {{ gherkin_action }}, call table:` | `API_CALL` | `{{ http_method }} /api/{{ domain }}/{{ action_slug }}` |
| `回應, with table:` | `API_ASSERT` | `{{ response_model }}` |
| `外部服務 {{ service_name }} 回傳:` | `MOCK_SETUP` | `app.services.{{ domain }}_service.{{ dependency }}` |

## 7. BDD Alignment Check (Constitution §IV-B)

> **Instruction**: For each Scenario, verify the `When` step maps to a testable
> entry point. This section is filled during Phase 1.5 of `/speckit.plan`.

### Alignment Table

| Scenario | When Step | Entry Point | Testable? | Notes |
|----------|-----------|-------------|-----------|-------|
| {{ scenario_name }} | {{ when_step }} | {{ class.method }} | PASS / FAIL | {{ notes }} |

### Entry Point Violations & Resolutions

> List any validations that were moved to satisfy the Entry Point Rule.
> If none, write "No violations found."

- **[Violation]**: {{ description of what was misplaced }}
  - **Resolution**: {{ where validation was moved and why }}

### Wiring Dependencies

> How is the entry point instantiated in tests? List constructor dependencies
> and their mock/injection strategy.

- `{{ ServiceClass }}({{ dep1 }}, {{ dep2 }})` → `{{ dep1 }}` = `AsyncMock(spec=...)`, `{{ dep2 }}` = direct instantiation

## 8. File Structure

> **Instruction**: List all files that will be created or modified.

```
app/
├── schemas/
│   └── {{ domain }}.py
├── services/
│   └── {{ domain }}_service.py
├── repositories/
│   └── {{ domain }}_repository.py
├── routers/
│   └── {{ domain }}.py
└── exceptions.py

tests/
├── unit/
│   └── test_{{ domain }}_service.py
└── integration/
    └── test_{{ feature_slug }}.py

Dockerfile
docker-compose.yml
requirements.txt
```

## 9. Deviation Log

> **Instruction**: Record any template sections that were intentionally skipped,
> replaced, or adapted for this feature. Every deviation MUST have a rationale.
> If no deviations, write "No deviations from template."

| Template Section | Status | Rationale |
|-----------------|--------|-----------|
| {{ section_name }} | USED / REPLACED / SKIPPED | {{ reason }} |
