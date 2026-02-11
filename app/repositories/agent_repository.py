"""Data access for Agents and AgentMcpServers tables."""

from typing import Optional


class AgentRepository:
    """Repository for Agent-related database operations."""

    async def find_active_by_name(self, name: str) -> Optional[dict]:
        """Find active (non-deleted) agent by name."""
        raise NotImplementedError

    async def count_by_owner(self, owner_id: str) -> int:
        """Count active agents owned by user (for quota check)."""
        raise NotImplementedError

    async def create_agent(self, agent_data: dict) -> dict:
        """Insert new Agent record. Returns created record with id."""
        raise NotImplementedError

    async def create_agent_mcp_bindings(
        self, agent_id: str, mcp_ids: list[str]
    ) -> list[dict]:
        """Insert AgentMcpServers records. All enabled=true by default."""
        raise NotImplementedError
