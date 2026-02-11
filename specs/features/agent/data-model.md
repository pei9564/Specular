# Data Model: CreateAgentV2

**Source**: `specs/db_schema/agent.dbml`, `specs/db_schema/mcp.dbml`

## Entities

### Agents (primary, write)

| Field | Type | Constraints | Notes |
|-------|------|------------|-------|
| id | string (UUID) | PK, auto-generated | Agent ID |
| name | string | Unique among active agents, max 64 chars, `[a-zA-Z0-9_-]` | |
| owner_id | string | FK → Users.id | Set from authenticated user |
| status | string | `active` on creation | Only `active` / `deleted` (soft-delete) |
| mode | string | `chat` (default) or `triggers` | |
| model_id | string | FK → LLM Models, must be active | |
| system_prompt | string | Optional | |
| model_config | json | `{temperature: 0.7, max_tokens: 4096}` defaults | temperature: [0, 2.0] |
| memory_config | json | `{type: "in_memory"}` default | type: `in_memory` / `database` |
| created_at | string (datetime) | Auto-set | |
| updated_at | string (datetime) | Auto-set | |

**Validation Rules (from V1 feature)**:
- Name uniqueness check MUST ignore `status=deleted` records
- `model_id` must reference an active (non-deprecated) model
- `temperature` must be in [0, 2.0]

### AgentMcpServers (association, write)

| Field | Type | Constraints | Notes |
|-------|------|------------|-------|
| agent_id | string | PK, FK → Agents.id | |
| mcp_id | string | PK, FK → McpServers.id | |
| enabled | bool | Default: `true` | |
| created_at | string (datetime) | Auto-set | |

**Validation Rules (from V2 feature)**:
- Each `mcp_id` must exist in McpServers table
- Each referenced MCP Server must have `status = "active"`
- No duplicate `mcp_id` in the same request

### McpServers (read-only reference)

| Field | Type | Used in V2 | Notes |
|-------|------|-----------|-------|
| id | string | Yes | Lookup target |
| name | string | Yes | Returned in response |
| status | string | Yes | Must be `active` to bind |

## State Transitions

```
[Request] → Validate Agent fields
          → Validate MCP Server IDs (if any)
          → BEGIN TRANSACTION
            → INSERT Agents (status=active)
            → INSERT AgentMcpServers (enabled=true, per mcp_id)
          → COMMIT
          → Return CreateAgentV2Response

On any validation failure → no records created (atomic)
```

## Relationships

```
Agents.owner_id → Users.id
AgentMcpServers.agent_id → Agents.id
AgentMcpServers.mcp_id → McpServers.id
```
