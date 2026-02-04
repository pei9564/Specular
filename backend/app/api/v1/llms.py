"""
LLM 管理 API
"""

from fastapi import APIRouter, HTTPException, Query, Request, status

router = APIRouter()


@router.get("/llms")
async def list_llms(
    request: Request,
    status_filter: str = Query("ACTIVE", alias="status"),
):
    """查詢可用的 LLM 模型"""
    # TODO: 實作查詢邏輯
    return {"data": [], "total": 0}


@router.post("/llms", status_code=status.HTTP_201_CREATED)
async def register_llm(request: Request):
    """註冊新的 LLM 模型（僅限管理員）"""
    # TODO: 實作註冊邏輯
    raise HTTPException(status_code=status.HTTP_501_NOT_IMPLEMENTED)


@router.get("/llms/{id}")
async def get_llm_details(request: Request, id: str):
    """取得 LLM 模型詳情"""
    # TODO: 實作查詢邏輯
    raise HTTPException(status_code=status.HTTP_404_NOT_FOUND)


@router.patch("/llms/{id}")
async def update_llm(request: Request, id: str):
    """更新 LLM 模型配置（僅限管理員）"""
    # TODO: 實作更新邏輯
    raise HTTPException(status_code=status.HTTP_501_NOT_IMPLEMENTED)
