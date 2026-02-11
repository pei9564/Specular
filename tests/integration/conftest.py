"""Shared BDD integration test infrastructure.

This module provides reusable fixtures and helpers for all pytest-bdd integration
tests. Feature-specific test files should ONLY contain:
  1. @scenario() decorators
  2. Feature-specific When/Then step definitions

Everything else — datatable parsing, context flow, app factory, common Given steps,
and the lazy API trigger — lives here.

ISA Pattern Mapping:
  MOCK_SETUP  → Given steps (this file: auth, background entities)
  API_CALL    → When steps (feature files: build context["payload"] from datatables)
  API_TRIGGER → _ensure_called() bridges When → Then by firing the HTTP request
  API_ASSERT  → Then steps (feature files: assert status + body from context["response"])
  DB_ASSERT   → Then steps (feature files: assert mock repo call patterns)

Context Flow (Given → When → Then):
  context["payload"]        ← When steps accumulate from Gherkin data tables
  context["response"]       ← _ensure_called() fires once, caches httpx Response
  context["background_*"]   ← Given steps store background entity data for mock config
"""

from __future__ import annotations

from typing import Any
from unittest.mock import AsyncMock

import pytest
from fastapi import FastAPI, Request
from fastapi.testclient import TestClient
from pytest_bdd import given, parsers

from app.exceptions import AppException
from app.routers.agent_router import app_exception_handler, router
from app.services.agent_service import AgentService


# ===========================================================================
# Data Table Helper
# ===========================================================================
def table_to_dicts(datatable: list[list[str]]) -> list[dict[str, str]]:
    """Convert pytest-bdd datatable (list of lists) to a list of dicts.

    In pytest-bdd 8.x, step functions receive datatable as DataTable.raw(),
    which is list[list[str]]: datatable[0] = header row, datatable[1:] = data rows.

    Usage in step definitions::

        @when("使用者創建 Agent:")
        def when_create(datatable, context):
            for row in table_to_dicts(datatable):
                context["payload"][row["field"]] = row["value"]
    """
    headers = datatable[0]
    return [dict(zip(headers, row)) for row in datatable[1:]]


# ===========================================================================
# Context Fixture — state carrier for Given → When → Then
# ===========================================================================
@pytest.fixture
def context() -> dict[str, Any]:
    """Shared mutable state for the Given → When → Then flow.

    Standard keys (always present):
      - payload:   dict — accumulated by API_CALL When steps from data tables
      - response:  httpx.Response | None — set once by _ensure_called()

    Feature-specific keys (added by Given steps as needed):
      - background_mcp:  list[dict] — MCP Server background data
      - background_llm:  list[dict] — LLM model background data
      - (future features add their own background_* keys)
    """
    return {
        "payload": {},
        "response": None,
    }


# ===========================================================================
# App Factory + Client
# ===========================================================================
@pytest.fixture
def app(mock_agent_repo: AsyncMock, mock_mcp_repo: AsyncMock) -> FastAPI:
    """Create a FastAPI app with mocked dependencies for integration testing.

    - Registers AppException → JSON error handler
    - Injects user_id via middleware (default: "user-001")
    - Overrides service DI with mock repos from tests/conftest.py
    """
    from app.routers.agent_router import get_agent_service

    test_app = FastAPI()
    test_app.add_exception_handler(AppException, app_exception_handler)  # type: ignore[arg-type]

    service = AgentService(agent_repo=mock_agent_repo, mcp_repo=mock_mcp_repo)

    @test_app.middleware("http")
    async def inject_user_id(request: Request, call_next):  # type: ignore[no-untyped-def]
        request.state.user_id = "user-001"
        response = await call_next(request)
        return response

    test_app.include_router(router)
    test_app.dependency_overrides[get_agent_service] = lambda: service
    return test_app


@pytest.fixture
def client(app: FastAPI) -> TestClient:
    """HTTP test client bound to the mocked FastAPI app."""
    return TestClient(app)


# ===========================================================================
# Lazy API Trigger (API_TRIGGER)
# ===========================================================================
def ensure_called(
    context: dict[str, Any],
    client: TestClient,
    mock_mcp_repo: AsyncMock,
) -> None:
    """Fire the API request once after all When steps complete, cache in context.

    ISA: API_TRIGGER — bridges API_CALL (When) → API_ASSERT/DB_ASSERT (Then).

    This is called by Then steps. It's idempotent: fires only once per scenario.
    MCP mock is configured here (not in When steps) because the full payload
    (including mcp_server_ids) is only complete after all When steps have run.

    Mock configuration logic:
      1. Read context["payload"]["mcp_server_ids"] (if any)
      2. Match against context["background_mcp"] (populated by Given step)
      3. Configure mock_mcp_repo.find_by_ids return value
      4. Fire POST /api/agents with context["payload"]
      5. Store response in context["response"]
    """
    if context["response"] is not None:
        return

    # Configure MCP mock from background data + requested IDs
    requested_ids = context["payload"].get("mcp_server_ids", [])
    background_mcp = context.get("background_mcp", [])
    if requested_ids and background_mcp:
        found = [m for m in background_mcp if m["mcp_id"] in requested_ids]
        mock_mcp_repo.find_by_ids.return_value = [
            {"id": m["mcp_id"], "name": m["name"], "status": m["status"]}
            for m in found
        ]

    # Fire API request
    resp = client.post(
        "/api/agents",
        json=context["payload"],
        headers={"X-User-ID": "user-001"},
    )
    context["response"] = resp


# ===========================================================================
# MOCK_SETUP — Common Given steps (reusable across features)
# ===========================================================================
@given("系統中存在以下 LLM 模型:")
def given_llm_models() -> None:
    """Background LLM models — validated by service, mocked at repo level."""


@given("系統中存在以下 MCP Servers:")
def given_mcp_servers(datatable: Any, context: dict[str, Any]) -> None:
    """Background MCP servers — parse data table into context for mock config."""
    context["background_mcp"] = table_to_dicts(datatable)


@given(parsers.parse('使用者 "{user_id}" 已登入且擁有 "{permission}" 權限'))
def given_user_logged_in(user_id: str, permission: str) -> None:
    """User auth — handled by middleware mock in app fixture."""


@given(parsers.parse('系統中不存在 mcp_id 為 "{mcp_id}" 的 MCP Server'))
def given_mcp_not_exists(mcp_id: str) -> None:
    """Precondition: mcp_id absent — background data already excludes it."""


@given(parsers.parse('系統中不存在名為 "{name}" 的 Agent'))
def given_no_agent_named(name: str, mock_agent_repo: AsyncMock) -> None:
    """Precondition: no active agent with this name."""
    mock_agent_repo.find_active_by_name.return_value = None
