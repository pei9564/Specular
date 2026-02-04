"""
Topic 管理 API
"""

from fastapi import APIRouter, HTTPException, Query, Request, status

router = APIRouter()


@router.get("/topics")
async def list_topics(
    request: Request,
    limit: int = Query(20, ge=1, le=100),
    cursor: str = Query(None),
):
    """查詢對話主題清單"""
    return {"topics": [], "nextCursor": None, "hasMore": False}


@router.post("/topics", status_code=status.HTTP_201_CREATED)
async def create_topic(request: Request):
    """建立新的對話主題"""
    raise HTTPException(status_code=status.HTTP_501_NOT_IMPLEMENTED)


@router.get("/topics/{id}")
async def get_topic_details(request: Request, id: str):
    """取得 Topic 詳細資訊"""
    raise HTTPException(status_code=status.HTTP_404_NOT_FOUND)


@router.patch("/topics/{id}")
async def update_topic_config(request: Request, id: str):
    """更新 Topic 配置"""
    raise HTTPException(status_code=status.HTTP_501_NOT_IMPLEMENTED)


@router.post("/topics/{id}/clear")
async def clear_topic(request: Request, id: str):
    """重置對話歷史"""
    raise HTTPException(status_code=status.HTTP_501_NOT_IMPLEMENTED)
