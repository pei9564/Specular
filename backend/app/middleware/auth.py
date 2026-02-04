"""
外部認證中間件
透過信任的 HTTP Headers 識別使用者身份
"""

from typing import Optional

from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import JSONResponse


class ExternalAuthMiddleware(BaseHTTPMiddleware):
    """外部認證中間件"""

    # 不需要認證的路徑
    EXCLUDED_PATHS = ["/", "/health", "/docs", "/redoc", "/openapi.json"]

    async def dispatch(self, request: Request, call_next):
        """處理請求"""
        # 跳過不需要認證的路徑
        if request.url.path in self.EXCLUDED_PATHS:
            return await call_next(request)

        # 從 Header 取得使用者資訊
        user_id = request.headers.get("X-User-ID")
        user_role = request.headers.get("X-User-Role", "USER")

        # 驗證必要的 Header
        if not user_id:
            return JSONResponse(
                status_code=401,
                content={
                    "code": "UNAUTHORIZED",
                    "message": "缺少必要的身份驗證資訊",
                    "details": {"missingHeader": "X-User-ID"},
                },
            )

        # 驗證 User ID 格式
        if not user_id.strip():
            return JSONResponse(
                status_code=401,
                content={
                    "code": "INVALID_USER_ID",
                    "message": "使用者 ID 格式異常",
                },
            )

        # 將使用者資訊注入到 request.state
        request.state.user_id = user_id
        request.state.user_role = user_role

        # 繼續處理請求
        response = await call_next(request)
        return response
