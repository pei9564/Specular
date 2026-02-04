"""
Tool 管理 API
"""

from fastapi import APIRouter, HTTPException, Query, Request, status

router = APIRouter()


@router.get("/tool-templates")
async def list_tool_templates(request: Request):
    """查詢工具模板清單"""
    return {"data": [], "total": 0}


@router.get("/tool-templates/{id}")
async def get_tool_template_details(request: Request, id: str):
    """取得工具模板詳情"""
    raise HTTPException(status_code=status.HTTP_404_NOT_FOUND)


@router.delete("/tool-templates/{id}")
async def delete_tool_template(request: Request, id: str):
    """刪除工具模板（僅限管理員）"""
    raise HTTPException(status_code=status.HTTP_501_NOT_IMPLEMENTED)


@router.get("/tool-instances")
async def list_tool_instances(
    request: Request,
    template_id: str = Query(None, alias="templateId"),
):
    """查詢工具實例清單"""
    return {"data": [], "total": 0}


@router.post("/tool-instances", status_code=status.HTTP_201_CREATED)
async def create_tool_instance(request: Request):
    """建立工具實例"""
    raise HTTPException(status_code=status.HTTP_501_NOT_IMPLEMENTED)


@router.get("/tool-instances/{id}")
async def get_tool_instance_details(request: Request, id: str):
    """取得工具實例詳情"""
    raise HTTPException(status_code=status.HTTP_404_NOT_FOUND)


@router.patch("/tool-instances/{id}")
async def update_tool_instance(request: Request, id: str):
    """更新工具實例配置"""
    raise HTTPException(status_code=status.HTTP_501_NOT_IMPLEMENTED)


@router.delete("/tool-instances/{id}")
async def delete_tool_instance(request: Request, id: str):
    """刪除工具實例"""
    raise HTTPException(status_code=status.HTTP_501_NOT_IMPLEMENTED)
