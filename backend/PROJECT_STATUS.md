# Backend 專案總覽

## ✅ 已完成

### 1. 專案基礎架構

- ✅ FastAPI 應用主入口 (`app/main.py`)
- ✅ 配置管理系統 (`app/config.py`)
- ✅ 依賴管理 (`requirements.txt`, `pyproject.toml`)
- ✅ Docker 配置 (`Dockerfile`)
- ✅ 環境變數範本 (`.env.example`)

### 2. 中間件系統

- ✅ 外部認證中間件 (`app/middleware/auth.py`)
  - 透過 `X-User-ID` 和 `X-User-Role` Headers 驗證
  - 自動注入使用者資訊到 `request.state`
- ✅ 請求日誌中間件 (`app/middleware/logging.py`)
  - 自動生成 Trace ID
  - 記錄請求時長和狀態
  - 異常捕獲與日誌記錄

### 3. API 路由框架

已建立所有 API 端點的基本框架：

- ✅ **Agents API** (`app/api/v1/agents.py`)
  - GET /v1/agents - 查詢 Agent 清單
  - POST /v1/agents - 建立 Agent
  - GET /v1/agents/{id} - 取得 Agent 詳情
  - PATCH /v1/agents/{id} - 更新 Agent
  - DELETE /v1/agents/{id} - 刪除 Agent（軟刪除）
  - POST /v1/agents/{id}/restore - 還原 Agent

- ✅ **LLMs API** (`app/api/v1/llms.py`)
  - GET /v1/llms - 查詢 LLM 清單
  - POST /v1/llms - 註冊 LLM
  - GET /v1/llms/{id} - 取得 LLM 詳情
  - PATCH /v1/llms/{id} - 更新 LLM

- ✅ **Tools API** (`app/api/v1/tools.py`)
  - GET /v1/tool-templates - 查詢工具模板
  - GET /v1/tool-templates/{id} - 取得模板詳情
  - DELETE /v1/tool-templates/{id} - 刪除模板
  - GET /v1/tool-instances - 查詢工具實例
  - POST /v1/tool-instances - 建立實例
  - GET /v1/tool-instances/{id} - 取得實例詳情
  - PATCH /v1/tool-instances/{id} - 更新實例
  - DELETE /v1/tool-instances/{id} - 刪除實例

- ✅ **Topics API** (`app/api/v1/topics.py`)
  - GET /v1/topics - 查詢 Topic 清單
  - POST /v1/topics - 建立 Topic
  - GET /v1/topics/{id} - 取得 Topic 詳情
  - PATCH /v1/topics/{id} - 更新 Topic
  - POST /v1/topics/{id}/clear - 重置對話歷史

- ✅ **Messages API** (`app/api/v1/messages.py`)
  - POST /v1/topics/{id}/messages - 發送訊息（SSE 串流）
  - POST /v1/checkpoints/{id}/approve - 批准 HITL 檢查點
  - POST /v1/checkpoints/{id}/reject - 拒絕 HITL 檢查點

- ✅ **Audit API** (`app/api/v1/audit.py`)
  - GET /v1/audit-logs - 查詢審計日誌（僅管理員）

- ✅ **System API** (`app/api/v1/system.py`)
  - GET /v1/health - 健康檢查

### 4. 數據模型

- ✅ Agent 模型 (`app/models/agent.py`)
  - CreateAgentRequest
  - UpdateAgentRequest
  - AgentSummary
  - Agent
  - ListAgentsResponse
- ✅ 錯誤模型 (`app/models/error.py`)
  - ErrorResponse
  - ErrorCode 常量

### 5. 測試

- ✅ 基本 API 測試 (`tests/test_api.py`)
  - 根路由測試
  - 健康檢查測試
  - 認證測試
  - 權限控制測試

### 6. 開發工具

- ✅ 啟動腳本
  - `start.sh` (Linux/Mac)
  - `start.ps1` (Windows)
- ✅ README 文檔
- ✅ .gitignore

## 🚧 待實作功能

### 1. 資料庫層

- [ ] SQLModel 模型定義
  - [ ] Agent 模型
  - [ ] LLM 模型
  - [ ] Tool 模型
  - [ ] Topic 模型
  - [ ] ChatMessage 模型
  - [ ] AuditLog 模型
- [ ] 資料庫連線管理
- [ ] 資料庫遷移腳本 (`init.sql`)

### 2. 業務邏輯層 (Services)

- [ ] AgentService
  - [ ] 建立 Agent
  - [ ] 查詢 Agent
  - [ ] 更新 Agent
  - [ ] 刪除/還原 Agent
  - [ ] 驗證 LLM 和 Tool 綁定
- [ ] LLMService
  - [ ] 註冊 LLM
  - [ ] 查詢 LLM（權限過濾）
  - [ ] 更新 LLM 狀態
- [ ] ToolService
  - [ ] 管理工具模板
  - [ ] 管理工具實例
  - [ ] Schema 驗證
- [ ] TopicService
  - [ ] 建立 Topic
  - [ ] 配置管理
  - [ ] Thread 管理
- [ ] MessageService
  - [ ] Context 組裝
  - [ ] STM 管理
  - [ ] 訊息持久化

### 3. LangGraph 整合

- [ ] Context 組裝策略
  - [ ] STM 窗口管理
  - [ ] Token 限制處理
  - [ ] 訊息截斷（FIFO）
- [ ] SSE 串流實作
  - [ ] AGUI 事件序列
  - [ ] RunStarted/Finished
  - [ ] TextMessage 生命週期
  - [ ] ToolCall 生命週期
  - [ ] RunError 處理
- [ ] HITL 檢查點
  - [ ] 敏感工具檢測
  - [ ] Approve/Reject 流程

### 4. 其他 Pydantic 模型

- [ ] LLM 模型
- [ ] Tool 模型
- [ ] Topic 模型
- [ ] Message 模型
- [ ] SSE 事件模型

### 5. 審計日誌

- [ ] 審計日誌寫入
- [ ] 審計日誌查詢
- [ ] 日誌韌性處理

### 6. 完整測試

- [ ] 單元測試
- [ ] 整合測試
- [ ] E2E 測試（基於 BDD feature 文件）

## 📋 下一步建議

### 優先級 1: 資料庫層

1. 定義 SQLModel 模型
2. 建立資料庫連線管理
3. 撰寫初始化 SQL 腳本

### 優先級 2: 核心業務邏輯

1. 實作 AgentService
2. 實作 LLMService
3. 實作 ToolService
4. 實作 TopicService

### 優先級 3: LangGraph 整合

1. Context 組裝策略
2. SSE 串流實作
3. HITL 檢查點

### 優先級 4: 測試與文檔

1. 完善單元測試
2. 撰寫整合測試
3. 補充 API 文檔

## 🎯 專案特色

1. **完整的 API 規範**: 基於 OpenAPI 3.0 標準
2. **外部認證整合**: 透過 HTTP Headers 信任上游 Gateway
3. **結構化日誌**: 使用 structlog 記錄所有請求
4. **權限控制**: 基於角色的訪問控制（RBAC）
5. **錯誤處理**: 統一的錯誤響應格式
6. **AGUI 協議**: 完整支援 Agent User Interaction Protocol
7. **模組化設計**: 清晰的分層架構

## 📚 參考文件

- OpenAPI 規範: `../spec/openapi.yaml`
- Feature 文件: `../spec/api/*.feature`
- 技術棧配置: `../spec/tech_stack.yaml`
