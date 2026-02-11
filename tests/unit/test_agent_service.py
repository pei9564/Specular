"""Unit tests for AgentService.create_agent_v2()."""

from unittest.mock import AsyncMock

import pytest

from app.exceptions import DuplicateResource, InvalidState, ResourceNotFound
from app.schemas.agent import CreateAgentV2Request
from app.services.agent_service import AgentService


# ---------------------------------------------------------------------------
# Local fixture overrides (unit tests need pre-populated MCP data)
# ---------------------------------------------------------------------------
@pytest.fixture
def mock_mcp_repo(mock_mcp_repo: AsyncMock) -> AsyncMock:
    """Override conftest default: pre-populate with 2 active MCP servers."""
    mock_mcp_repo.find_by_ids.return_value = [
        {"id": "mcp-001", "name": "Slack", "status": "active"},
        {"id": "mcp-002", "name": "GitHub", "status": "active"},
    ]
    return mock_mcp_repo


@pytest.fixture
def service(mock_agent_repo: AsyncMock, mock_mcp_repo: AsyncMock) -> AgentService:
    return AgentService(agent_repo=mock_agent_repo, mcp_repo=mock_mcp_repo)


# =============================================================================
# US1: Happy Path
# =============================================================================


class TestCreateAgentV2HappyPath:
    """Gherkin: 成功 - 創建 Agent 並同時綁定 MCP Servers"""

    @pytest.mark.asyncio
    async def test_happy_create_with_mcp_binding(
        self, service: AgentService, mock_agent_repo: AsyncMock, mock_mcp_repo: AsyncMock
    ) -> None:
        req = CreateAgentV2Request(
            name="McpBot",
            system_prompt="你是一個全能助手",
            model_id="gpt-4o",
            mode="chat",
            mcp_server_ids=["mcp-001", "mcp-002"],
        )

        result = await service.create_agent_v2(user_id="user-001", req=req)

        assert result.name == "McpBot"
        assert result.owner_id == "user-001"
        assert result.status == "active"
        assert result.mode == "chat"
        assert result.model_id == "gpt-4o"
        assert len(result.mcp_servers) == 2
        assert result.mcp_servers[0].mcp_id == "mcp-001"
        assert result.mcp_servers[0].name == "Slack"
        assert result.mcp_servers[0].enabled is True
        mock_agent_repo.create_agent.assert_awaited_once()
        created_id = mock_agent_repo.create_agent.call_args[0][0]["id"]
        mock_agent_repo.create_agent_mcp_bindings.assert_awaited_once_with(
            created_id, ["mcp-001", "mcp-002"]
        )

    @pytest.mark.asyncio
    async def test_happy_create_without_mcp_v1_compat(
        self, service: AgentService, mock_agent_repo: AsyncMock, mock_mcp_repo: AsyncMock
    ) -> None:
        """Gherkin: 成功 - 創建 Agent 不綁定任何 MCP Server（向下相容 V1）"""
        req = CreateAgentV2Request(
            name="SimpleBot",
            system_prompt="你是一個簡單助手",
            model_id="claude-3",
            mode="chat",
        )

        result = await service.create_agent_v2(user_id="user-001", req=req)

        assert result.name == "SimpleBot"
        assert result.status == "active"
        assert result.mcp_servers == []
        mock_mcp_repo.find_by_ids.assert_not_awaited()
        mock_agent_repo.create_agent_mcp_bindings.assert_not_awaited()

    @pytest.mark.asyncio
    async def test_happy_enabled_defaults_to_true(
        self, service: AgentService, mock_agent_repo: AsyncMock
    ) -> None:
        """Gherkin: 成功 - AgentMcpServers 的 enabled 預設為 true"""
        req = CreateAgentV2Request(
            name="DefaultBot",
            model_id="gpt-4o",
            mcp_server_ids=["mcp-001"],
        )

        result = await service.create_agent_v2(user_id="user-001", req=req)

        for server in result.mcp_servers:
            assert server.enabled is True

    @pytest.mark.asyncio
    async def test_happy_triggers_mode(
        self, service: AgentService, mock_agent_repo: AsyncMock
    ) -> None:
        """Gherkin: 成功 - 以 triggers 模式創建 Agent 並綁定 MCP Server"""
        req = CreateAgentV2Request(
            name="TriggerBot",
            system_prompt="自動觸發助手",
            model_id="gpt-4o",
            mode="triggers",
            mcp_server_ids=["mcp-001"],
        )

        result = await service.create_agent_v2(user_id="user-001", req=req)

        assert result.mode == "triggers"


# =============================================================================
# US2: MCP Validation Failures
# =============================================================================


class TestMcpValidationFailures:
    """Gherkin: [Precondition] 綁定的 MCP Servers 必須存在且為啟用狀態"""

    @pytest.mark.asyncio
    async def test_mcp_validation_nonexistent_mcp(
        self, service: AgentService, mock_mcp_repo: AsyncMock
    ) -> None:
        """Gherkin: 失敗 - 綁定不存在的 MCP Server"""
        mock_mcp_repo.find_by_ids.return_value = [
            {"id": "mcp-001", "name": "Slack", "status": "active"},
        ]
        req = CreateAgentV2Request(
            name="TestBot",
            model_id="gpt-4o",
            mcp_server_ids=["mcp-001", "mcp-999"],
        )

        with pytest.raises(ResourceNotFound, match="mcp-999"):
            await service.create_agent_v2(user_id="user-001", req=req)

    @pytest.mark.asyncio
    async def test_mcp_validation_inactive_mcp(
        self, service: AgentService, mock_mcp_repo: AsyncMock
    ) -> None:
        """Gherkin: 失敗 - 綁定已停用的 MCP Server"""
        mock_mcp_repo.find_by_ids.return_value = [
            {"id": "mcp-003", "name": "Jira", "status": "inactive"},
        ]
        req = CreateAgentV2Request(
            name="TestBot",
            model_id="gpt-4o",
            mcp_server_ids=["mcp-003"],
        )

        with pytest.raises(InvalidState, match="mcp-003"):
            await service.create_agent_v2(user_id="user-001", req=req)

    @pytest.mark.asyncio
    async def test_mcp_validation_duplicate_ids_rejected_at_schema(self) -> None:
        """Gherkin: 失敗 - 綁定重複的 MCP Server (schema-level validation)"""
        with pytest.raises(ValueError, match="duplicates"):
            CreateAgentV2Request(
                name="TestBot",
                model_id="gpt-4o",
                mcp_server_ids=["mcp-001", "mcp-001"],
            )


# =============================================================================
# US3: Atomicity
# =============================================================================


class TestAtomicity:
    """Gherkin: MCP Server 綁定失敗時應整體回滾，不留部分狀態"""

    @pytest.mark.asyncio
    async def test_atomicity_no_agent_created_on_mcp_failure(
        self, service: AgentService, mock_agent_repo: AsyncMock, mock_mcp_repo: AsyncMock
    ) -> None:
        """Gherkin: 原子性 - Agent 基本資料驗證通過但 MCP Server 驗證失敗時，整體回滾"""
        mock_mcp_repo.find_by_ids.return_value = []
        req = CreateAgentV2Request(
            name="RollbackBot",
            model_id="gpt-4o",
            mcp_server_ids=["mcp-999"],
        )

        with pytest.raises(ResourceNotFound):
            await service.create_agent_v2(user_id="user-001", req=req)

        mock_agent_repo.create_agent.assert_not_awaited()
        mock_agent_repo.create_agent_mcp_bindings.assert_not_awaited()
