"""
FastAPI 應用主入口
"""

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.config import get_settings
from app.middleware.auth import ExternalAuthMiddleware
from app.middleware.logging import RequestLoggingMiddleware

# 導入路由
from app.api.v1 import agents, llms, tools, topics, messages, audit, system

settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """應用生命週期管理"""
    # 啟動時執行
    print(f"🚀 Starting {settings.app_name} v{settings.app_version}")
    print(f"📝 Environment: {settings.environment}")
    print(f"🔍 Debug mode: {settings.debug}")

    yield

    # 關閉時執行
    print("👋 Shutting down application")


# 建立 FastAPI 應用
app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    description="完整的 AI Agent 管理平台 API，基於 AGUI (Agent User Interaction Protocol) 協議",
    lifespan=lifespan,
    docs_url="/docs" if settings.debug else None,
    redoc_url="/redoc" if settings.debug else None,
)

# CORS 中間件
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 自定義中間件
app.add_middleware(ExternalAuthMiddleware)
app.add_middleware(RequestLoggingMiddleware)

# 註冊路由
app.include_router(agents.router, prefix="/v1", tags=["Agents"])
app.include_router(llms.router, prefix="/v1", tags=["LLMs"])
app.include_router(tools.router, prefix="/v1", tags=["Tools"])
app.include_router(topics.router, prefix="/v1", tags=["Topics"])
app.include_router(messages.router, prefix="/v1", tags=["Messages"])
app.include_router(audit.router, prefix="/v1", tags=["Audit"])
app.include_router(system.router, prefix="/v1", tags=["System"])


# 根路由
@app.get("/")
async def root():
    """根路由"""
    return {
        "name": settings.app_name,
        "version": settings.app_version,
        "status": "running",
        "docs": "/docs" if settings.debug else "disabled",
    }


# 全域異常處理器
@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    """全域異常處理"""
    return JSONResponse(
        status_code=500,
        content={
            "code": "INTERNAL_SERVER_ERROR",
            "message": "系統發生錯誤",
            "details": str(exc) if settings.debug else None,
        },
    )


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.debug,
        log_level=settings.log_level.lower(),
    )
