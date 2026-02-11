"""Pydantic schemas for Agent domain (V2 with MCP binding)."""

import re
from typing import Optional

from pydantic import BaseModel, Field, field_validator


class ModelConfigSchema(BaseModel):
    """LLM model parameter configuration."""

    temperature: float = Field(default=0.7, ge=0.0, le=2.0)
    max_tokens: int = Field(default=4096, ge=1)


class MemoryConfigSchema(BaseModel):
    """Agent memory configuration."""

    type: str = Field(default="in_memory")
    retention_days: int = Field(default=30, ge=1)

    @field_validator("type")
    @classmethod
    def validate_memory_type(cls, v: str) -> str:
        if v not in ("in_memory", "database"):
            raise ValueError("Memory type must be 'in_memory' or 'database'")
        return v


class CreateAgentV2Request(BaseModel):
    """V2: Agent creation with optional MCP Server binding."""

    name: str = Field(..., max_length=64)
    system_prompt: Optional[str] = None
    model_id: str
    mode: str = Field(default="chat")
    llm_config: Optional[ModelConfigSchema] = None
    memory_config: Optional[MemoryConfigSchema] = None
    mcp_server_ids: list[str] = Field(default_factory=list)

    @field_validator("name")
    @classmethod
    def validate_name_format(cls, v: str) -> str:
        if not re.match(r"^[a-zA-Z0-9_-]+$", v):
            raise ValueError(
                "Name must contain only alphanumeric characters, underscores, and hyphens"
            )
        return v

    @field_validator("mode")
    @classmethod
    def validate_mode(cls, v: str) -> str:
        if v not in ("chat", "triggers"):
            raise ValueError("Mode must be 'chat' or 'triggers'")
        return v

    @field_validator("mcp_server_ids")
    @classmethod
    def validate_no_duplicate_mcp_ids(cls, v: list[str]) -> list[str]:
        if len(v) != len(set(v)):
            raise ValueError("MCP Server IDs must not contain duplicates")
        return v


class BoundMcpServerSchema(BaseModel):
    """Represents an MCP Server bound to an Agent."""

    mcp_id: str
    name: str
    enabled: bool = True


class CreateAgentV2Response(BaseModel):
    """Response after successful Agent creation."""

    id: str
    name: str
    owner_id: str
    status: str
    mode: str
    model_id: str
    system_prompt: Optional[str]
    llm_config: dict
    memory_config: dict
    mcp_servers: list[BoundMcpServerSchema]
    created_at: str
