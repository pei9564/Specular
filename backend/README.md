# Specular AI - Backend

FastAPI 後端服務，提供 AI Agent 管理平台的核心 API。

## 技術棧

- **語言**: Python 3.11
- **框架**: FastAPI
- **Runtime**: Uvicorn (ASGI Server)
- **驗證**: Pydantic v2
- **資料庫**: PostgreSQL 15 (AsyncPG)
- **LLM 整合**: LangChain + LangGraph

## 專案結構

```
backend/
├── app/
│   ├── main.py              # FastAPI 應用入口
│   ├── config.py            # 配置管理
│   ├── middleware/          # 中間件（認證、日誌）
│   ├── models/              # Pydantic 模型
│   ├── api/v1/              # API 路由
│   │   ├── agents.py        # Agent 管理
│   │   ├── llms.py          # LLM 管理
│   │   ├── tools.py         # Tool 管理
│   │   ├── topics.py        # Topic 管理
│   │   ├── messages.py      # 訊息與串流
│   │   ├── audit.py         # 審計日誌
│   │   └── system.py        # 系統維運
│   └── services/            # 業務邏輯（待實作）
├── tests/                   # 測試
├── requirements.txt         # 依賴
├── pyproject.toml          # 專案配置
├── Dockerfile              # Docker 配置
└── README.md               # 本文件
```

## 快速開始

### 1. 安裝依賴

```bash
pip install -r requirements.txt
```

### 2. 配置環境變數

複製 `.env.example` 為 `.env` 並修改配置：

```bash
cp .env.example .env
```

### 3. 啟動開發伺服器

```bash
# 方式 1: 直接執行
python -m app.main

# 方式 2: 使用 uvicorn
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### 4. 訪問 API 文檔

- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Docker 部署

```bash
# 建立映像
docker build -t specular-ai-backend .

# 執行容器
docker run -p 8000:8000 --env-file .env specular-ai-backend
```

## API 規範

完整的 API 規範請參考：`../spec/openapi.yaml`

### 核心功能

- **Agent 管理**: 建立、查詢、更新與刪除 AI Agent
- **LLM 管理**: 管理與配置各種 LLM 模型
- **工具管理**: 管理工具模板與工具實例
- **對話管理**: Topic 與 Thread 的完整生命週期管理
- **串流對話**: 基於 SSE 的即時串流對話（AGUI 協議）
- **審計追蹤**: 完整的請求記錄與可追蹤性

### 認證方式

系統採用外部認證整合，透過信任的 HTTP Headers 識別使用者身份：

- `X-User-ID`: 使用者唯一識別碼（必要）
- `X-User-Role`: 使用者角色（USER 或 ADMIN）

## 開發指南

### 程式碼風格

使用 Ruff 和 Black 進行程式碼檢查和格式化：

```bash
# 檢查程式碼
ruff check .

# 格式化程式碼
black .
```

### 執行測試

```bash
pytest
```

## 待實作功能

目前 API 路由已建立基本框架，以下功能需要進一步實作：

1. **資料庫層**
   - SQLModel 模型定義
   - 資料庫連線管理
   - CRUD 操作

2. **業務邏輯層**
   - Agent 服務
   - LLM 服務
   - Tool 服務
   - Topic 服務

3. **LangGraph 整合**
   - Context 組裝策略
   - SSE 串流實作
   - HITL 檢查點

4. **測試**
   - 單元測試
   - 整合測試
   - E2E 測試

## 授權

MIT License
