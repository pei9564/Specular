"""
Agent 相關的 Pydantic 模型
"""

from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, Field, field_validator


# ==================== Request Models ====================
class CreateAgentRequest(BaseModel):
    """建立 Agent 請求"""

    name: str = Field(..., min_length=1, max_length=100, description="Agent 名稱")
    system_prompt: Optional[str] = Field(
        None,
        description="系統提示詞，若不提供將使用預設值",
    )
    llm_id: Optional[str] = Field(None, description="綁定的 LLM ID，可為 null（通用 Agent）")
    tool_ids: List[str] = Field(default_factory=list, description="綁定的工具實例 ID 清單")

    @field_validator("name")
    @classmethod
    def validate_name(cls, v: str) -> str:
        """驗證名稱"""
        if not v.strip():
            raise ValueError("Agent 名稱不可為空")
        return v.strip()


class UpdateAgentRequest(BaseModel):
    """更新 Agent 請求"""

    name: Optional[str] = Field(None, min_length=1, max_length=100)
    system_prompt: Optional[str] = None
    llm_id: Optional[str] = None
    tool_ids: Optional[List[str]] = None


# ==================== Response Models ====================
class AgentSummary(BaseModel):
    """Agent 摘要（列表用）"""

    id: str
    name: str
    llm_model: Optional[str] = None
    tools: List[str] = Field(default_factory=list)
    description: Optional[str] = None
    has_tools: bool = False

    model_config = {"from_attributes": True}


class Agent(BaseModel):
    """Agent 完整資訊"""

    id: str
    name: str
    status: str = Field(description="ACTIVE 或 DELETED")
    system_prompt: str
    llm_id: Optional[str] = None
    llm_model: Optional[str] = None
    llm_context_window: Optional[int] = None
    tool_ids: List[str] = Field(default_factory=list)
    tools: List[str] = Field(default_factory=list)
    user_id: str
    created_at: datetime
    updated_at: Optional[datetime] = None
    deleted_at: Optional[datetime] = None

    model_config = {"from_attributes": True}


class ListAgentsResponse(BaseModel):
    """查詢 Agent 清單響應"""

    data: List[AgentSummary]
    total: int
    limit: int
    offset: int
