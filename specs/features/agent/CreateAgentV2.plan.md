# Implementation Plan: CreateAgentV2

**Branch**: `002-agent-CreateAgentV2`
**Source Feature**: `specs/features/agent/CreateAgentV2.feature`
**Base Feature**: `specs/features/agent/創建Agent.feature` (V1 rules inherited)
**Instruction Set**: `.specify/config/isa.yml`

---

## Constitution Check

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Gherkin is King | ✅ PASS | All design traces to CreateAgentV2.feature + 創建Agent.feature |
| II. Surgical Precision | ✅ PASS | V2 only adds MCP binding; does not modify V1 code paths |
| III. Plug-and-Play | ✅ PASS | New service method; thin router delegation |
| IV. Las Vegas Rule | ✅ PASS | Repository injected via DI; fully mockable |
| V. Modern Pythonic | ✅ PASS | Type hints, Pydantic models, async/await |
| VI. Context-Aware | ✅ PASS | FastAPI + SQLAlchemy + Pydantic (per constitution) |
| VII. Defensive Coding | ✅ PASS | Custom exceptions mapped to HTTP codes |

---

## 1. API Specification (The External Interface)

> **Purpose**: Defines the HTTP contract for Integration Tests.

```yaml
paths:
  # Map Gherkin Action: "使用者創建 Agent 並同時綁定 MCP Servers"
  /api/agents:
    post:
      summary: "Create Agent with optional MCP Server bindings (V2)"
      operationId: "create_agent_v2"
      tags: [agent]
      security:
        - bearerAuth: []
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreateAgentV2Request'
      responses:
        '201':
          description: "Agent created successfully"
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/CreateAgentV2Response'
        '400':
          description: "Validation error (name format, duplicate MCP, inactive MCP)"
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '403':
          description: "Permission denied (no create:agent permission)"
        '404':
          description: "Referenced resource not found (model_id, mcp_id)"
        '409':
          description: "Agent name already exists"
        '422':
          description: "Invalid parameters (temperature, llm_config)"
        '429':
          description: "Agent quota exceeded"

components:
  schemas:
    CreateAgentV2Request:
      type: object
      required: [name, model_id]
      properties:
        name:
          type: string
          pattern: "^[a-zA-Z0-9_-]+$"
          maxLength: 64
        system_prompt:
          type: string
        model_id:
          type: string
        mode:
          type: string
          enum: [chat, triggers]
          default: chat
        llm_config:
          type: object
          properties:
            temperature:
              type: number
              minimum: 0.0
              maximum: 2.0
            max_tokens:
              type: integer
              minimum: 1
        memory_config:
          type: object
          properties:
            type:
              type: string
              enum: [in_memory, database]
              default: in_memory
            retention_days:
              type: integer
        mcp_server_ids:
          type: array
          items:
            type: string
          description: "Optional list of MCP Server IDs to bind. Empty or omitted = no binding (V1 compat)."
          uniqueItems: true

    CreateAgentV2Response:
      type: object
      properties:
        id:
          type: string
          format: uuid
        name:
          type: string
        owner_id:
          type: string
        status:
          type: string
          enum: [active]
        mode:
          type: string
        model_id:
          type: string
        system_prompt:
          type: string
        llm_config:
          type: object
        memory_config:
          type: object
        mcp_servers:
          type: array
          items:
            $ref: '#/components/schemas/BoundMcpServer'
        created_at:
          type: string
          format: date-time

    BoundMcpServer:
      type: object
      properties:
        mcp_id:
          type: string
        name:
          type: string
        enabled:
          type: boolean
          default: true

    ErrorResponse:
      type: object
      properties:
        error_code:
          type: string
        message:
          type: string
        details:
          type: object
```

---

## 2. Data Models (The Shared Contract)

> **Instruction**: Define Pydantic Models. MUST match `specs/db_schema/agent.dbml` + `mcp.dbml`.

```python
# app/schemas/agent.py
from pydantic import BaseModel, Field, field_validator
from typing import Optional
import re

class ModelConfigSchema(BaseModel):
    temperature: float = Field(default=0.7, ge=0.0, le=2.0)
    max_tokens: int = Field(default=4096, ge=1)

class MemoryConfigSchema(BaseModel):
    type: str = Field(default="in_memory")  # in_memory | database
    retention_days: int = Field(default=30, ge=1)

class CreateAgentV2Request(BaseModel):
    """V2: Agent creation with optional MCP Server binding."""
    name: str = Field(..., max_length=64)
    system_prompt: Optional[str] = None
    model_id: str
    mode: str = Field(default="chat")  # chat | triggers
    llm_config: Optional[ModelConfigSchema] = None
    memory_config: Optional[MemoryConfigSchema] = None
    mcp_server_ids: list[str] = Field(default_factory=list)

    @field_validator("name")
    @classmethod
    def validate_name_format(cls, v: str) -> str:
        if not re.match(r"^[a-zA-Z0-9_-]+$", v):
            raise ValueError("Name must contain only alphanumeric, underscore, hyphen")
        return v

    @field_validator("mode")
    @classmethod
    def validate_mode(cls, v: str) -> str:
        if v not in ("chat", "triggers"):
            raise ValueError("Mode must be 'chat' or 'triggers'")
        return v

    @field_validator("mcp_server_ids")
    @classmethod
    def validate_no_duplicates(cls, v: list[str]) -> list[str]:
        if len(v) != len(set(v)):
            raise ValueError("MCP Server IDs must not contain duplicates")
        return v


class BoundMcpServerSchema(BaseModel):
    mcp_id: str
    name: str
    enabled: bool = True


class CreateAgentV2Response(BaseModel):
    """Response after successful Agent creation."""
    id: str
    name: str
    owner_id: str
    status: str  # always "active" on creation
    mode: str
    model_id: str
    system_prompt: Optional[str]
    llm_config: dict
    memory_config: dict
    mcp_servers: list[BoundMcpServerSchema]
    created_at: str
```

---

## 3. Service Architecture (The Internal Skeleton)

> **Instruction**: Define Class and Method signatures.
> **Note**: This skeleton will be used for both **Unit Testing** and **Implementation**.

```python
# app/services/agent_service.py
from app.schemas.agent import CreateAgentV2Request, CreateAgentV2Response
from app.repositories.agent_repository import AgentRepository
from app.repositories.mcp_repository import McpRepository
from app.exceptions import (
    ResourceNotFound,
    DuplicateResource,
    InvalidState,
    PermissionDenied,
    QuotaExceeded,
    ValidationError,
)


class AgentService:
    def __init__(
        self,
        agent_repo: AgentRepository,
        mcp_repo: McpRepository,
    ):
        self.agent_repo = agent_repo
        self.mcp_repo = mcp_repo

    async def create_agent_v2(
        self, user_id: str, req: CreateAgentV2Request
    ) -> CreateAgentV2Response:
        """
        Create Agent with optional MCP Server bindings (atomic).

        Business Logic Steps:
        1. Permission check: user has "create:agent"
        2. Quota check: user has not exceeded agent limit
        3. Name uniqueness: no active agent with same name
        4. Model validation: model_id exists and is active (not deprecated)
        5. Model config validation: temperature in [0, 2.0]
        6. MCP validation (if mcp_server_ids provided):
           a. All mcp_ids exist in McpServers table
           b. All referenced MCP Servers have status = "active"
        7. Atomic transaction:
           a. Insert Agent record (status=active, defaults applied)
           b. Insert AgentMcpServers records (enabled=true)
        8. Return created Agent with bound MCP Servers
        """
        raise NotImplementedError("Skeleton created. Implementation pending.")
```

```python
# app/repositories/agent_repository.py
from typing import Optional


class AgentRepository:
    """Data access for Agents and AgentMcpServers tables."""

    async def find_active_by_name(self, name: str) -> Optional[dict]:
        """Find active (non-deleted) agent by name."""
        raise NotImplementedError

    async def count_by_owner(self, owner_id: str) -> int:
        """Count active agents owned by user (for quota check)."""
        raise NotImplementedError

    async def create_agent(self, agent_data: dict) -> dict:
        """Insert new Agent record."""
        raise NotImplementedError

    async def create_agent_mcp_bindings(
        self, agent_id: str, mcp_ids: list[str]
    ) -> list[dict]:
        """Insert AgentMcpServers records. All enabled=true by default."""
        raise NotImplementedError
```

```python
# app/repositories/mcp_repository.py
from typing import Optional


class McpRepository:
    """Data access for McpServers table."""

    async def find_by_id(self, mcp_id: str) -> Optional[dict]:
        """Find MCP Server by ID."""
        raise NotImplementedError

    async def find_by_ids(self, mcp_ids: list[str]) -> list[dict]:
        """Find multiple MCP Servers by IDs."""
        raise NotImplementedError
```

```python
# app/routers/agent_router.py (thin delegation)
# POST /api/agents → AgentService.create_agent_v2()
# Auth via middleware → extracts user_id + permissions
# Returns 201 on success with CreateAgentV2Response
```

---

## 4. Mocking Strategy (The Las Vegas Rule)

> **Instruction**: List external dependencies to be mocked in both Unit and Integration tests.

| Dependency | Mock Path | Mock Return (Happy Path) |
|------------|-----------|--------------------------|
| Agent Repository | `app.services.agent_service.AgentRepository` | `find_active_by_name → None`, `count_by_owner → 0`, `create_agent → {id: "uuid", ...}` |
| MCP Repository | `app.services.agent_service.McpRepository` | `find_by_ids → [{id: "mcp-001", status: "active", name: "Slack"}, ...]` |
| UUID Generator | `uuid.uuid4` | Deterministic UUID for test assertions |
| Permission Middleware | `app.middleware.auth.get_current_user` | `{user_id: "user-001", permissions: ["create:agent"]}` |

**Transaction Mocking**: Wrap service method in a mock transaction context. On rollback scenarios (MCP validation fails after agent data is valid), assert that neither Agent nor AgentMcpServers records persist.

---

## 5. ISA Mapping (Test Generation Guide)

> **Instruction**: Map Gherkin Phrases to ISA Patterns.
> This section guides `/speckit.tasks` in generating `tests/integration/`.

| Gherkin Phrase | ISA Pattern | Target Implementation |
|----------------|-------------|----------------------|
| `(UID=user-001) 創建 Agent 並綁定 MCP Servers, call table:` | `API_CALL` | `POST /api/agents` with `mcp_server_ids` in body |
| `Agent "X" 應成功建立` | `API_ASSERT` | Assert `201`, response body has `name == X`, `status == active` |
| `資料庫 AgentMcpServers 表應包含 N 筆記錄` | `DB_ASSERT` | Query `AgentMcpServers` where `agent_id = created_id`, assert count == N |
| `創建應失敗` | `API_ASSERT` | Assert `4xx` status code |
| `錯誤訊息應提示 "X"` | `API_ASSERT` | Assert `response.json()["message"]` contains X |
| `資料庫 Agents 表不應包含 "X"` | `DB_ASSERT` | Query `Agents` where `name = X`, assert count == 0 (rollback) |
| `AgentMcpServers 記錄的 enabled 欄位應為 true` | `DB_ASSERT` | Query `AgentMcpServers`, assert all `enabled == true` |

---

## 6. File Structure

```
app/
├── schemas/
│   └── agent.py          # CreateAgentV2Request, CreateAgentV2Response, BoundMcpServerSchema
├── services/
│   └── agent_service.py  # AgentService.create_agent_v2()
├── repositories/
│   ├── agent_repository.py  # AgentRepository (Agents + AgentMcpServers)
│   └── mcp_repository.py    # McpRepository (McpServers read-only)
├── routers/
│   └── agent_router.py   # POST /api/agents (thin delegation)
├── exceptions.py          # ResourceNotFound, DuplicateResource, InvalidState, etc.
└── middleware/
    └── auth.py            # Permission extraction middleware

tests/
├── unit/
│   └── test_agent_service.py  # Unit tests for AgentService.create_agent_v2
└── integration/
    └── test_create_agent_v2.py  # BDD step definitions for CreateAgentV2.feature
```

---

## 7. Complexity Tracking

| Item | Complexity | Justification |
|------|-----------|---------------|
| Atomic transaction (Agent + MCP bindings) | Medium | Constitution III requires modularity; single DB transaction wrapping both inserts is minimal viable approach |
| MCP bulk validation (find_by_ids) | Low | Single query instead of N queries; no over-engineering |

---

## Research Notes

No NEEDS CLARIFICATION items remain. Key decisions:

| Decision | Rationale | Alternatives Considered |
|----------|-----------|------------------------|
| Single `POST /api/agents` endpoint (V2 replaces V1 route) | V2 is backward-compatible (empty `mcp_server_ids` = V1 behavior). No need for separate endpoints. | Separate `/api/agents/v2` endpoint — rejected to avoid route sprawl |
| `mcp_server_ids` as flat array of IDs | Minimizes request complexity. `enabled` always defaults to `true` per DBML. | Nested objects with per-binding config — rejected; DBML only has `enabled` (default true) and no other config fields |
| MCP validation before Agent insert | Fail-fast: reject early if any MCP is invalid. Avoids creating Agent records that would need rollback. | Validate after insert — rejected; wasteful DB writes |
| Repository pattern for data access | Constitution IV (Las Vegas Rule) requires DI and mockability. | Direct ORM calls in service — rejected; violates testability principle |
