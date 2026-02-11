"""Agent router — thin delegation to AgentService."""

from fastapi import APIRouter, Depends, Request
from fastapi.responses import JSONResponse

from app.exceptions import AppException
from app.repositories.agent_repository import AgentRepository
from app.repositories.mcp_repository import McpRepository
from app.schemas.agent import CreateAgentV2Request, CreateAgentV2Response
from app.services.agent_service import AgentService

router = APIRouter(prefix="/api/agents", tags=["agent"])


def get_agent_service() -> AgentService:
    """Dependency provider for AgentService."""
    return AgentService(
        agent_repo=AgentRepository(),
        mcp_repo=McpRepository(),
    )


@router.post("", response_model=CreateAgentV2Response, status_code=201)
async def create_agent_v2(
    req: CreateAgentV2Request,
    request: Request,
    service: AgentService = Depends(get_agent_service),
) -> CreateAgentV2Response:
    """Create Agent with optional MCP Server bindings (V2)."""
    user_id: str = request.state.user_id
    return await service.create_agent_v2(user_id=user_id, req=req)


async def app_exception_handler(request: Request, exc: AppException) -> JSONResponse:
    """Map AppException subclasses to HTTP responses.

    Register on FastAPI app: app.add_exception_handler(AppException, app_exception_handler)
    """
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "error_code": exc.error_code,
            "message": exc.message,
            "details": exc.details,
        },
    )
