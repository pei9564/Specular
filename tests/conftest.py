"""Shared test fixtures for unit and integration tests.

Single source of truth for mock repositories — prevents drift between test layers.
"""

from __future__ import annotations

from typing import Any
from unittest.mock import AsyncMock

import pytest

from app.repositories.agent_repository import AgentRepository
from app.repositories.mcp_repository import McpRepository


@pytest.fixture
def mock_agent_repo() -> AsyncMock:
    """Mock AgentRepository with safe defaults (no existing agents, zero quota)."""
    repo = AsyncMock(spec=AgentRepository)
    repo.find_active_by_name.return_value = None
    repo.count_by_owner.return_value = 0

    async def _create_agent(agent_data: dict[str, Any]) -> dict[str, Any]:
        return agent_data

    repo.create_agent.side_effect = _create_agent
    repo.create_agent_mcp_bindings.return_value = []
    return repo


@pytest.fixture
def mock_mcp_repo() -> AsyncMock:
    """Mock McpRepository with empty default (no MCP servers found)."""
    repo = AsyncMock(spec=McpRepository)
    repo.find_by_ids.return_value = []
    return repo
