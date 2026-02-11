# Quickstart: CreateAgentV2

## What this feature does

Creates an Agent and optionally binds MCP Servers to it in a single atomic operation. Backward-compatible with V1 (omitting `mcp_server_ids` produces the same result as V1).

## Key files to implement

| File | Purpose |
|------|---------|
| `app/schemas/agent.py` | Pydantic request/response models |
| `app/services/agent_service.py` | Business logic: validation + atomic creation |
| `app/repositories/agent_repository.py` | DB access for Agents + AgentMcpServers |
| `app/repositories/mcp_repository.py` | DB read access for McpServers |
| `app/routers/agent_router.py` | `POST /api/agents` → thin delegation |
| `app/exceptions.py` | Custom exceptions (ResourceNotFound, DuplicateResource, etc.) |

## Test files

| File | Purpose |
|------|---------|
| `tests/unit/test_agent_service.py` | Unit tests: mock repos, test all Gherkin scenarios |
| `tests/integration/test_create_agent_v2.py` | BDD integration tests from feature file |

## Critical business rules

1. Agent name must be unique among active (non-deleted) agents
2. All referenced MCP Servers must exist and have `status=active`
3. No duplicate MCP Server IDs in a single request
4. Transaction is atomic: if MCP validation fails, no Agent record is created
5. `AgentMcpServers.enabled` defaults to `true`

## API contract

```
POST /api/agents
Authorization: Bearer <token>

{
  "name": "MyBot",
  "model_id": "gpt-4o",
  "mode": "chat",
  "system_prompt": "You are a helpful assistant",
  "mcp_server_ids": ["mcp-001", "mcp-002"]
}

→ 201 Created
{
  "id": "uuid",
  "name": "MyBot",
  "status": "active",
  "mcp_servers": [
    {"mcp_id": "mcp-001", "name": "Slack", "enabled": true},
    {"mcp_id": "mcp-002", "name": "GitHub", "enabled": true}
  ],
  ...
}
```
