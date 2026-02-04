"""
請求日誌中間件
記錄所有 API 請求的上下文與異常堆疊
"""

import time
import uuid
from typing import Callable

from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware
import structlog

logger = structlog.get_logger()


class RequestLoggingMiddleware(BaseHTTPMiddleware):
    """請求日誌中間件"""

    # 不記錄的路徑（避免雜訊）
    EXCLUDED_PATHS = ["/health", "/metrics", "/favicon.ico"]

    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        """處理請求並記錄日誌"""
        # 跳過不需要記錄的路徑
        if request.url.path in self.EXCLUDED_PATHS:
            return await call_next(request)

        # 生成 Trace ID
        trace_id = request.headers.get("Trace-ID", str(uuid.uuid4()))
        request.state.trace_id = trace_id

        # 取得使用者資訊
        user_id = getattr(request.state, "user_id", None)

        # 記錄請求開始時間
        start_time = time.time()

        try:
            # 執行請求
            response = await call_next(request)

            # 計算請求時長
            duration_ms = int((time.time() - start_time) * 1000)

            # 記錄成功的請求
            logger.info(
                "request_completed",
                trace_id=trace_id,
                user_id=user_id,
                method=request.method,
                path=request.url.path,
                status_code=response.status_code,
                duration_ms=duration_ms,
            )

            # 將 Trace ID 加入回應 Header
            response.headers["X-Trace-ID"] = trace_id

            return response

        except Exception as exc:
            # 計算請求時長
            duration_ms = int((time.time() - start_time) * 1000)

            # 記錄異常
            logger.error(
                "request_failed",
                trace_id=trace_id,
                user_id=user_id,
                method=request.method,
                path=request.url.path,
                duration_ms=duration_ms,
                error_type=type(exc).__name__,
                error_message=str(exc),
                exc_info=True,
            )

            # 重新拋出異常，讓全域異常處理器處理
            raise
