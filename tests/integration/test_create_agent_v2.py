"""BDD integration tests for CreateAgentV2.

Shared infrastructure (conftest.py): table_to_dicts, context, app, client,
  ensure_called, common Given steps (auth, background MCP/LLM, preconditions).

This file contains ONLY:
  1. @scenario() decorators — 1:1 mapping from Gherkin
  2. Feature-specific API_CALL (When) steps
  3. Feature-specific API_ASSERT / DB_ASSERT (Then) steps
"""

from __future__ import annotations

from typing import Any
from unittest.mock import AsyncMock

from fastapi.testclient import TestClient
from pytest_bdd import parsers, scenario, then, when

from tests.integration.conftest import ensure_called, table_to_dicts

# ---------------------------------------------------------------------------
# Feature file path (relative to bdd_features_base_dir in pytest.ini)
# ---------------------------------------------------------------------------
FEATURE = "agent/CreateAgentV2.feature"


# ===========================================================================
# Scenarios — 1:1 mapping from Gherkin (8 scenarios)
# ===========================================================================
@scenario(FEATURE, "成功 - 創建 Agent 並同時綁定 MCP Servers")
def test_success_create_with_mcp() -> None:
    pass


@scenario(FEATURE, "成功 - 創建 Agent 不綁定任何 MCP Server（向下相容 V1）")
def test_success_without_mcp_v1_compat() -> None:
    pass


@scenario(FEATURE, "成功 - AgentMcpServers 的 enabled 預設為 true")
def test_enabled_defaults_to_true() -> None:
    pass


@scenario(FEATURE, "成功 - 以 triggers 模式創建 Agent 並綁定 MCP Server")
def test_triggers_mode() -> None:
    pass


@scenario(FEATURE, "失敗 - 綁定不存在的 MCP Server")
def test_nonexistent_mcp() -> None:
    pass


@scenario(FEATURE, "失敗 - 綁定已停用的 MCP Server")
def test_inactive_mcp() -> None:
    pass


@scenario(FEATURE, "失敗 - 綁定重複的 MCP Server")
def test_duplicate_mcp() -> None:
    pass


@scenario(FEATURE, "原子性 - Agent 基本資料驗證通過但 MCP Server 驗證失敗時，整體回滾")
def test_atomicity_rollback() -> None:
    pass


# ===========================================================================
# API_CALL — When steps (parse data tables into context["payload"])
# ===========================================================================
@when("使用者創建 Agent:")
def when_create_agent(datatable: Any, context: dict[str, Any]) -> None:
    """Parse field/value table into context payload."""
    for row in table_to_dicts(datatable):
        context["payload"][row["field"]] = row["value"]


@when("同時綁定 MCP Servers:")
def when_bind_mcp_servers(datatable: Any, context: dict[str, Any]) -> None:
    """Parse mcp_id table into context payload."""
    context["payload"]["mcp_server_ids"] = [
        row["mcp_id"] for row in table_to_dicts(datatable)
    ]


@when("未指定任何 MCP Servers")
def when_no_mcp_servers() -> None:
    """No MCP binding — payload stays without mcp_server_ids (V1 compat)."""


@when("使用者創建 Agent 並綁定 MCP Servers:")
def when_create_and_bind_mcp(datatable: Any, context: dict[str, Any]) -> None:
    """Combined create + bind — table has mcp_id column only, agent uses defaults."""
    context["payload"].setdefault("name", "TestBot")
    context["payload"].setdefault("model_id", "gpt-4o")
    context["payload"]["mcp_server_ids"] = [
        row["mcp_id"] for row in table_to_dicts(datatable)
    ]


@when(parsers.parse('使用者創建 Agent "{name}" 並綁定 {mcp_id}（未指定 enabled）'))
def when_create_with_default_enabled(
    name: str, mcp_id: str, context: dict[str, Any],
) -> None:
    """Create agent with single MCP binding, enabled not specified."""
    context["payload"]["name"] = name
    context["payload"].setdefault("model_id", "gpt-4o")
    context["payload"]["mcp_server_ids"] = [mcp_id]


# ===========================================================================
# API_ASSERT — Then steps (status code + response body checks)
# ===========================================================================
@then(parsers.parse('Agent "{name}" 應成功建立'))
def then_agent_created(
    name: str,
    context: dict[str, Any],
    client: TestClient,
    mock_mcp_repo: AsyncMock,
) -> None:
    ensure_called(context, client, mock_mcp_repo)
    resp = context["response"]
    assert resp.status_code == 201, (
        f"Expected 201, got {resp.status_code}: {resp.json()}"
    )
    assert resp.json()["name"] == name


@then("創建應失敗")
def then_creation_failed(
    context: dict[str, Any],
    client: TestClient,
    mock_mcp_repo: AsyncMock,
) -> None:
    ensure_called(context, client, mock_mcp_repo)
    resp = context["response"]
    assert resp.status_code >= 400, f"Expected 4xx, got {resp.status_code}"


@then(parsers.parse('錯誤訊息應提示 "{text}" 不存在'))
def then_error_not_found(
    text: str,
    context: dict[str, Any],
    client: TestClient,
    mock_mcp_repo: AsyncMock,
) -> None:
    ensure_called(context, client, mock_mcp_repo)
    body = context["response"].json()
    assert text in body.get("message", ""), (
        f"Expected '{text}' in message, got: {body}"
    )


@then(parsers.parse('錯誤訊息應提示 "{mcp_id}" 目前為停用狀態，無法綁定'))
def then_error_inactive(
    mcp_id: str,
    context: dict[str, Any],
    client: TestClient,
    mock_mcp_repo: AsyncMock,
) -> None:
    ensure_called(context, client, mock_mcp_repo)
    body = context["response"].json()
    assert mcp_id in body.get("message", ""), (
        f"Expected '{mcp_id}' in message, got: {body}"
    )


@then("錯誤訊息應提示 MCP Server 不可重複綁定")
def then_error_duplicate(
    context: dict[str, Any],
    client: TestClient,
    mock_mcp_repo: AsyncMock,
) -> None:
    ensure_called(context, client, mock_mcp_repo)
    body = context["response"].json()
    msg = body.get("message", "") + str(body.get("detail", ""))
    assert "duplicate" in msg.lower() or "重複" in msg, (
        f"Expected duplicate error, got: {body}"
    )


# ===========================================================================
# DB_ASSERT — Then steps (mock repository call assertions)
# ===========================================================================
@then("資料庫 Agents 表應包含:")
def then_agents_table_contains(
    datatable: Any,
    context: dict[str, Any],
    client: TestClient,
    mock_mcp_repo: AsyncMock,
) -> None:
    ensure_called(context, client, mock_mcp_repo)
    body = context["response"].json()
    for row in table_to_dicts(datatable):
        field, value = row["field"], row["value"]
        assert str(body.get(field)) == value, (
            f"Expected {field}={value}, got {body.get(field)}"
        )


@then(parsers.parse('資料庫 AgentMcpServers 表應包含 {count:d} 筆記錄，關聯至 "{name}"'))
def then_mcp_bindings_count(
    count: int,
    name: str,
    context: dict[str, Any],
    client: TestClient,
    mock_mcp_repo: AsyncMock,
    mock_agent_repo: AsyncMock,
) -> None:
    ensure_called(context, client, mock_mcp_repo)
    body = context["response"].json()
    assert body["name"] == name
    actual = len(body.get("mcp_servers", []))
    assert actual == count, f"Expected {count} MCP bindings, got {actual}"
    if count > 0:
        mock_agent_repo.create_agent_mcp_bindings.assert_awaited_once()


@then(parsers.parse('資料庫 AgentMcpServers 表不應有 "{name}" 的關聯記錄'))
def then_no_mcp_bindings(
    name: str,
    context: dict[str, Any],
    client: TestClient,
    mock_mcp_repo: AsyncMock,
    mock_agent_repo: AsyncMock,
) -> None:
    ensure_called(context, client, mock_mcp_repo)
    resp = context["response"]
    if resp.status_code == 201:
        assert resp.json().get("mcp_servers", []) == []
    else:
        mock_agent_repo.create_agent_mcp_bindings.assert_not_awaited()


@then("AgentMcpServers 記錄的 enabled 欄位應為 true")
def then_enabled_is_true(
    context: dict[str, Any],
    client: TestClient,
    mock_mcp_repo: AsyncMock,
) -> None:
    ensure_called(context, client, mock_mcp_repo)
    servers = context["response"].json().get("mcp_servers", [])
    assert len(servers) > 0, "Expected at least one MCP server binding"
    for server in servers:
        assert server["enabled"] is True


@then(parsers.parse('資料庫 Agents 表不應包含 "{name}"'))
def then_no_agent_record(
    name: str,
    context: dict[str, Any],
    client: TestClient,
    mock_mcp_repo: AsyncMock,
    mock_agent_repo: AsyncMock,
) -> None:
    ensure_called(context, client, mock_mcp_repo)
    mock_agent_repo.create_agent.assert_not_awaited()


@then(parsers.parse('資料庫 Agents 表中 "{name}" 的 mode 應為 "{mode}"'))
def then_agent_mode(
    name: str,
    mode: str,
    context: dict[str, Any],
    client: TestClient,
    mock_mcp_repo: AsyncMock,
) -> None:
    ensure_called(context, client, mock_mcp_repo)
    body = context["response"].json()
    assert body["name"] == name
    assert body["mode"] == mode
