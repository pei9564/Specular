# Implementation Tasks: CreateAgentV2

**Source Plan**: `specs/features/agent/CreateAgentV2.plan.md`
**ISA Config**: `.specify/config/isa.yml`
**Feature**: `specs/features/agent/CreateAgentV2.feature`

## User Stories (from Gherkin Rules)

| Story | Rule / Scenario Coverage | Priority |
|-------|--------------------------|----------|
| US1 | 成功創建 Agent 並同時綁定 MCP Servers; V1 相容; enabled 預設值; triggers 模式 | P1 |
| US2 | MCP 不存在 / 已停用 / 重複綁定 — 前置驗證失敗 | P2 |
| US3 | 原子性回滾 — MCP 驗證失敗時 Agent 不應被建立 | P3 |

---

## Phase 1: Setup

> *Goal: Initialize project skeleton so all imports resolve.*

- [ ] T001 Create project package structure with `__init__.py` files for `app/`, `app/schemas/`, `app/services/`, `app/repositories/`, `app/routers/`, `app/middleware/`, `tests/`, `tests/unit/`, `tests/integration/`
- [ ] T002 Create custom exception classes in `app/exceptions.py` — `ResourceNotFound(404)`, `DuplicateResource(409)`, `InvalidState(400)`, `PermissionDenied(403)`, `QuotaExceeded(429)`, `ValidationError(422)` per Plan Section 7 / Constitution VII

---

## Phase 2: Foundational (Blocking Prerequisites)

> *Goal: Schemas, repository interfaces, and router skeleton — all tests can import without error.*

- [ ] T003 [P] Create Pydantic schemas in `app/schemas/agent.py` — `ModelConfigSchema`, `MemoryConfigSchema`, `CreateAgentV2Request` (with validators: name format, mode enum, mcp_server_ids uniqueness), `BoundMcpServerSchema`, `CreateAgentV2Response` per Plan Section 2
- [ ] T004 [P] Create `AgentRepository` interface in `app/repositories/agent_repository.py` — methods: `find_active_by_name`, `count_by_owner`, `create_agent`, `create_agent_mcp_bindings` per Plan Section 3
- [ ] T005 [P] Create `McpRepository` interface in `app/repositories/mcp_repository.py` — methods: `find_by_id`, `find_by_ids` per Plan Section 3
- [ ] T006 [P] Create `AgentService` skeleton in `app/services/agent_service.py` — constructor accepts `AgentRepository` + `McpRepository` via DI; method `create_agent_v2(user_id, req)` raises `NotImplementedError` per Plan Section 3
- [ ] T007 Create `POST /api/agents` route in `app/routers/agent_router.py` — thin delegation to `AgentService.create_agent_v2()`, inject service via `Depends()`, return 201 on success per Plan Section 1

---

## Phase 3: US1 — Create Agent with MCP Binding (Happy Path)

> *Goal: Agent creation with optional MCP binding works end-to-end.*
>
> **Gherkin coverage**: 成功 - 創建 Agent 並同時綁定 MCP Servers; 成功 - V1 相容; 成功 - enabled 預設為 true; 成功 - triggers 模式
>
> **Independent test criteria**: Given valid inputs and existing active MCP Servers, calling `POST /api/agents` with `mcp_server_ids` returns 201 with Agent + bound MCP list. Without `mcp_server_ids`, returns 201 with empty `mcp_servers` array.

- [ ] T008 [US1] Create unit test file `tests/unit/test_agent_service.py` — test happy-path scenarios: (1) create with MCP binding returns response with 2 bound servers, (2) create without MCP returns empty mcp_servers, (3) enabled defaults to true, (4) triggers mode persists. Mock `AgentRepository` and `McpRepository` per Plan Section 4
- [ ] T009 [US1] Implement `AgentService.create_agent_v2()` happy path in `app/services/agent_service.py` — steps: permission check → quota check → name uniqueness → model validation → MCP lookup (if any) → insert Agent → insert AgentMcpServers → build response. Apply defaults: `status=active`, `model_config={temperature:0.7, max_tokens:4096}`, `memory_config={type:"in_memory"}` per Plan Section 3
- [ ] T010 [US1] Run unit tests for US1 happy path — `pytest tests/unit/test_agent_service.py -k "happy"` — MUST PASS

---

## Phase 4: US2 — MCP Validation Failures

> *Goal: All MCP precondition checks reject invalid requests with correct error messages.*
>
> **Gherkin coverage**: 失敗 - 綁定不存在的 MCP Server; 失敗 - 綁定已停用的 MCP Server; 失敗 - 綁定重複的 MCP Server
>
> **Independent test criteria**: Requests with non-existent, inactive, or duplicate MCP IDs return 400/404 with descriptive error. No Agent or binding records created.

- [ ] T011 [US2] Add unit tests for MCP validation failures in `tests/unit/test_agent_service.py` — test: (1) non-existent mcp_id → `ResourceNotFound`, (2) inactive mcp status → `InvalidState`, (3) duplicate mcp_ids → `ValidationError` (caught at schema level). Mock `McpRepository.find_by_ids` to return partial/mismatched results per Plan Section 4
- [ ] T012 [US2] Implement MCP validation logic in `app/services/agent_service.py` within `create_agent_v2()` — after model validation, before DB insert: call `mcp_repo.find_by_ids(req.mcp_server_ids)`, check all IDs found, check all statuses are "active". Raise `ResourceNotFound` or `InvalidState` with specific mcp_id in message
- [ ] T013 [US2] Run unit tests for US2 — `pytest tests/unit/test_agent_service.py -k "mcp_validation"` — MUST PASS

---

## Phase 5: US3 — Atomicity / Rollback

> *Goal: Failed MCP validation prevents any Agent record from being created.*
>
> **Gherkin coverage**: 原子性 - Skills 驗證通過但 MCP Server 驗證失敗時，整體回滾
>
> **Independent test criteria**: When MCP validation fails, querying Agents table for the requested name returns zero results. AgentMcpServers table has no orphaned records.

- [ ] T014 [US3] Add unit test for atomicity in `tests/unit/test_agent_service.py` — test: valid agent data + invalid mcp_id → exception raised, assert `agent_repo.create_agent` was NOT called, assert `agent_repo.create_agent_mcp_bindings` was NOT called (fail-fast before DB writes)
- [ ] T015 [US3] Verify fail-fast ordering in `app/services/agent_service.py` — MCP validation MUST execute before any `create_agent` call. No code change needed if T012 implemented correctly; this is a verification task. Run `pytest tests/unit/test_agent_service.py -k "atomicity"` — MUST PASS

---

## Phase 6: Polish & Cross-Cutting

> *Goal: Type safety, linting, and full test suite pass.*

- [ ] T016 Run full test suite — `pytest tests/ -v` — ALL tests MUST PASS (Green)
- [ ] T017 Run type check — `mypy app/` — no errors
- [ ] T018 Verify OpenAPI contract alignment — compare router response schema against `specs/features/agent/contracts/create-agent-v2.yaml`, ensure all fields and status codes match

---

## Dependency Graph

```
T001 → T002 → T003,T004,T005 (parallel) → T006 → T007
                                                    ↓
                                              T008 → T009 → T010 (US1 complete)
                                                              ↓
                                              T011 → T012 → T013 (US2 complete)
                                                              ↓
                                              T014 → T015 (US3 complete)
                                                       ↓
                                              T016 → T017 → T018 (Polish)
```

## Parallel Execution Opportunities

| Phase | Parallelizable Tasks | Reason |
|-------|---------------------|--------|
| Phase 2 | T003, T004, T005 | Different files, no interdependencies |
| Phase 3-5 | US2 and US3 tests (T011, T014) | Independent test scenarios, same test file but different test functions |

## Implementation Strategy

1. **MVP (Phase 1-3)**: Setup + Foundational + US1 = working `POST /api/agents` with MCP binding
2. **Hardening (Phase 4-5)**: US2 + US3 = validation + atomicity guarantees
3. **Ship (Phase 6)**: Full green, type-safe, contract-verified

**Suggested MVP scope**: Complete through Phase 3 (US1). This delivers a working endpoint that creates agents with MCP bindings. Validation edge cases (US2, US3) can be shipped as a fast follow.
