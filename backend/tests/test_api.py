"""
測試 FastAPI 應用基本功能
"""

import pytest
from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_root_endpoint():
    """測試根路由"""
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["name"] == "Specular AI"
    assert data["status"] == "running"


def test_health_check():
    """測試健康檢查"""
    response = client.get("/v1/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "OK"
    assert "timestamp" in data


def test_list_agents_without_auth():
    """測試未認證時訪問 Agent 列表"""
    response = client.get("/v1/agents")
    assert response.status_code == 401
    data = response.json()
    assert data["code"] == "UNAUTHORIZED"


def test_list_agents_with_auth():
    """測試已認證時訪問 Agent 列表"""
    headers = {
        "X-User-ID": "test_user_001",
        "X-User-Role": "USER",
    }
    response = client.get("/v1/agents", headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert "data" in data
    assert "total" in data


def test_invalid_user_id():
    """測試無效的使用者 ID"""
    headers = {
        "X-User-ID": "",  # 空字串
        "X-User-Role": "USER",
    }
    response = client.get("/v1/agents", headers=headers)
    assert response.status_code == 401
    data = response.json()
    assert data["code"] == "INVALID_USER_ID"


def test_admin_only_endpoint():
    """測試僅管理員可訪問的端點"""
    # 一般使用者
    headers = {
        "X-User-ID": "test_user_001",
        "X-User-Role": "USER",
    }
    response = client.post("/v1/agents/ag_001/restore", headers=headers)
    assert response.status_code == 403
    data = response.json()
    assert data["code"] == "PERMISSION_DENIED"

    # 管理員
    admin_headers = {
        "X-User-ID": "admin_001",
        "X-User-Role": "ADMIN",
    }
    response = client.post("/v1/agents/ag_001/restore", headers=admin_headers)
    # 目前返回 501（未實作），但權限檢查通過
    assert response.status_code == 501
