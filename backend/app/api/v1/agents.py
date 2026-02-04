"""
Agent 管理 API
"""

from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, Request, status
from fastapi.responses import JSONResponse

from app.models.agent import (
    Agent,
    AgentSummary,
    CreateAgentRequest,
    ListAgentsResponse,
    UpdateAgentRequest,
)
from app.models.error import ErrorCode, ErrorResponse

router = APIRouter()


@router.get("/agents", response_model=ListAgentsResponse)
async def list_agents(
    request: Request,
    status_filter: str = Query("ACTIVE", alias="status", description="過濾 Agent 狀態"),
    limit: int = Query(20, ge=1, le=100, description="每頁筆數"),
    offset: int = Query(0, ge=0, description="偏移量"),
):
    """
    查詢 Agent 清單
    
    取得所有可用的 Agent 清單，自動過濾已刪除的 Agent
    """
    # TODO: 實作查詢邏輯
    # 目前返回空列表作為範例
    return ListAgentsResponse(
        data=[],
        total=0,
        limit=limit,
        offset=offset,
    )


@router.post("/agents", response_model=Agent, status_code=status.HTTP_201_CREATED)
async def create_agent(
    request: Request,
    body: CreateAgentRequest,
):
    """
    建立新的 Agent
    
    建立一個新的 AI Agent，可綁定 LLM 與工具
    """
    # 取得使用者資訊
    user_id = request.state.user_id
    user_role = request.state.user_role

    # TODO: 實作建立邏輯
    # 1. 驗證 LLM ID（如果提供）
    # 2. 驗證工具 ID
    # 3. 建立 Agent
    # 4. 發布事件

    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="功能尚未實作",
    )


@router.get("/agents/{id}", response_model=Agent)
async def get_agent_details(
    request: Request,
    id: str,
):
    """
    取得 Agent 詳細資訊
    
    取得指定 Agent 的完整配置，包含 System Prompt、LLM 與工具清單
    """
    # TODO: 實作查詢邏輯
    raise HTTPException(
        status_code=status.HTTP_404_NOT_FOUND,
        detail={
            "code": ErrorCode.AGENT_NOT_FOUND,
            "message": f"Agent {id} 不存在",
        },
    )


@router.patch("/agents/{id}", response_model=Agent)
async def update_agent(
    request: Request,
    id: str,
    body: UpdateAgentRequest,
):
    """
    更新 Agent 配置
    
    更新 Agent 的配置，包含 System Prompt、LLM 與工具
    """
    # TODO: 實作更新邏輯
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="功能尚未實作",
    )


@router.delete("/agents/{id}")
async def delete_agent(
    request: Request,
    id: str,
):
    """
    刪除 Agent (軟刪除)
    
    將 Agent 狀態變更為 DELETED，不進行物理刪除
    """
    # TODO: 實作軟刪除邏輯
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="功能尚未實作",
    )


@router.post("/agents/{id}/restore")
async def restore_agent(
    request: Request,
    id: str,
):
    """
    還原已刪除的 Agent
    
    將已刪除的 Agent 狀態還原為 ACTIVE（僅限管理員）
    """
    # 檢查權限
    user_role = request.state.user_role
    if user_role != "ADMIN":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={
                "code": ErrorCode.PERMISSION_DENIED,
                "message": "僅管理員可還原 Agent",
            },
        )

    # TODO: 實作還原邏輯
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="功能尚未實作",
    )
