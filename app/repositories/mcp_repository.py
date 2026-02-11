"""Data access for McpServers table (read-only for Agent domain)."""

from typing import Optional


class McpRepository:
    """Repository for MCP Server lookups."""

    async def find_by_id(self, mcp_id: str) -> Optional[dict]:
        """Find MCP Server by ID."""
        raise NotImplementedError

    async def find_by_ids(self, mcp_ids: list[str]) -> list[dict]:
        """Find multiple MCP Servers by IDs. Returns list of found records."""
        raise NotImplementedError
