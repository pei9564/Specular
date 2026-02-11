"""Agent service — business logic for Agent operations."""

import uuid
from datetime import datetime, timezone

from app.exceptions import DuplicateResource, InvalidState, ResourceNotFound
from app.repositories.agent_repository import AgentRepository
from app.repositories.mcp_repository import McpRepository
from app.schemas.agent import (
    BoundMcpServerSchema,
    CreateAgentV2Request,
    CreateAgentV2Response,
    ModelConfigSchema,
    MemoryConfigSchema,
)


class AgentService:
    """Service for Agent CRUD operations with MCP binding support."""

    def __init__(
        self,
        agent_repo: AgentRepository,
        mcp_repo: McpRepository,
    ) -> None:
        self.agent_repo = agent_repo
        self.mcp_repo = mcp_repo

    async def create_agent_v2(
        self, user_id: str, req: CreateAgentV2Request
    ) -> CreateAgentV2Response:
        """
        Create Agent with optional MCP Server bindings (atomic).

        Fail-fast: all validation runs BEFORE any DB writes (atomicity guarantee).
        """
        # 1. Name uniqueness check (among active agents)
        existing = await self.agent_repo.find_active_by_name(req.name)
        if existing is not None:
            raise DuplicateResource(
                f"Agent with name '{req.name}' already exists"
            )

        # 2. MCP validation (fail-fast, before any DB writes)
        mcp_records: list[dict] = []
        if req.mcp_server_ids:
            mcp_records = await self._validate_mcp_servers(req.mcp_server_ids)

        # 3. Apply defaults
        llm_config = (
            req.llm_config.model_dump() if req.llm_config
            else ModelConfigSchema().model_dump()
        )
        memory_config = (
            req.memory_config.model_dump() if req.memory_config
            else MemoryConfigSchema().model_dump()
        )

        now = datetime.now(timezone.utc).isoformat()
        agent_data = {
            "id": str(uuid.uuid4()),
            "name": req.name,
            "owner_id": user_id,
            "status": "active",
            "mode": req.mode,
            "model_id": req.model_id,
            "system_prompt": req.system_prompt,
            "llm_config": llm_config,
            "memory_config": memory_config,
            "created_at": now,
            "updated_at": now,
        }

        # 4. DB writes (all validation passed)
        created_agent = await self.agent_repo.create_agent(agent_data)

        # 5. Bind MCP Servers (if any)
        bound_mcp_servers: list[BoundMcpServerSchema] = []
        if req.mcp_server_ids:
            await self.agent_repo.create_agent_mcp_bindings(
                created_agent["id"], req.mcp_server_ids
            )
            bound_mcp_servers = [
                BoundMcpServerSchema(
                    mcp_id=mcp["id"],
                    name=mcp["name"],
                    enabled=True,
                )
                for mcp in mcp_records
            ]

        # 6. Build response
        return CreateAgentV2Response(
            id=created_agent["id"],
            name=created_agent["name"],
            owner_id=created_agent["owner_id"],
            status=created_agent["status"],
            mode=created_agent["mode"],
            model_id=created_agent["model_id"],
            system_prompt=created_agent.get("system_prompt"),
            llm_config=created_agent["llm_config"],
            memory_config=created_agent["memory_config"],
            mcp_servers=bound_mcp_servers,
            created_at=created_agent["created_at"],
        )

    async def _validate_mcp_servers(self, mcp_ids: list[str]) -> list[dict]:
        """Validate all MCP Server IDs exist and are active."""
        found = await self.mcp_repo.find_by_ids(mcp_ids)
        found_ids = {mcp["id"] for mcp in found}

        # Check all requested IDs were found
        for mcp_id in mcp_ids:
            if mcp_id not in found_ids:
                raise ResourceNotFound(
                    f"MCP Server '{mcp_id}' not found",
                    details={"mcp_id": mcp_id},
                )

        # Check all found MCP Servers are active
        for mcp in found:
            if mcp["status"] != "active":
                raise InvalidState(
                    f"MCP Server '{mcp['id']}' is currently '{mcp['status']}' and cannot be bound",
                    details={"mcp_id": mcp["id"], "status": mcp["status"]},
                )

        return found
