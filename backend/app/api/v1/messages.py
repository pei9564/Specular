"""
Message & Stream API
處理訊息發送與 SSE 串流
"""

from fastapi import APIRouter, HTTPException, Request, status
from fastapi.responses import StreamingResponse

router = APIRouter()


@router.post("/topics/{id}/messages")
async def submit_chat_message(request: Request, id: str):
    """
    發送訊息（觸發串流推論）
    
    發送使用者訊息並觸發 AI 推論。
    回應為 Server-Sent Events (SSE) 串流，遵循 AGUI 協議。
    """
    # TODO: 實作 SSE 串流邏輯
    # 1. 驗證 Topic 存在
    # 2. 組裝 Context（STM 管理）
    # 3. 觸發 LangGraph 推論
    # 4. 串流返回事件
    
    raise HTTPException(status_code=status.HTTP_501_NOT_IMPLEMENTED)


@router.post("/checkpoints/{id}/approve")
async def approve_checkpoint(request: Request, id: str):
    """批准 HITL 檢查點"""
    raise HTTPException(status_code=status.HTTP_501_NOT_IMPLEMENTED)


@router.post("/checkpoints/{id}/reject")
async def reject_checkpoint(request: Request, id: str):
    """拒絕 HITL 檢查點"""
    raise HTTPException(status_code=status.HTTP_501_NOT_IMPLEMENTED)
