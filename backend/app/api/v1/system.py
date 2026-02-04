"""
System 系統維運 API
"""

from datetime import datetime

from fastapi import APIRouter

router = APIRouter()


@router.get("/health")
async def health_check():
    """
    健康檢查
    
    檢查系統健康狀態（不需要認證）
    """
    return {
        "status": "OK",
        "timestamp": datetime.utcnow().isoformat() + "Z",
    }
