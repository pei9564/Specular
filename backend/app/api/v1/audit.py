"""
Audit 審計日誌 API
"""

from fastapi import APIRouter, HTTPException, Query, Request, status

router = APIRouter()


@router.get("/audit-logs")
async def search_audit_logs(
    request: Request,
    trace_id: str = Query(None, alias="traceId"),
    user_id: str = Query(None, alias="userId"),
    start_date: str = Query(None, alias="startDate"),
    end_date: str = Query(None, alias="endDate"),
):
    """
    查詢審計日誌（僅限管理員）
    """
    # 檢查權限
    user_role = request.state.user_role
    if user_role != "ADMIN":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={
                "code": "PERMISSION_DENIED",
                "message": "僅管理員可查詢審計日誌",
            },
        )

    # TODO: 實作查詢邏輯
    return {"data": [], "total": 0}
