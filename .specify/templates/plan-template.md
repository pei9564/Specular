# Implementation Plan: [FEATURE NAME]

**Branch**: `{{ branch_name }}`
**Source Feature**: `{{ path_to_feature_file }}`
**Instruction Set**: `.specify/config/isa.yml`

## 1. API Specification (The External Interface)
>
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
> This section guides Step 6 (`/speckit.tasks`) in generating `tests/integration/`.

| Gherkin Phrase | ISA Pattern | Target Implementation |
| --- | --- | --- |
| `(UID={user_id}) {{ gherkin_action }}, call table:` | `API_CALL` | `{{ http_method }} /api/{{ domain }}/{{ action_slug }}` |
| `回應, with table:` | `API_ASSERT` | `{{ response_model }}` |
| `外部服務 {{ service_name }} 回傳:` | `MOCK_SETUP` | `app.services.{{ domain }}_service.{{ dependency }}` |

## 7. File Structure

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
