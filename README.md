# Spec Kit 2.0: AI-Native & Contract-Driven Workflow

本專案採用 **Spec-Driven Development (SDD)** 流程。透過 **Gherkin (規格)**、**DBML (資料結構)** 與 **ISA (指令集)** 的三位一體，實現從需求到「自動化測試代碼」的完整閉環。

## 📂 1. 目錄結構標準 (Directory Structure)

所有檔案必須遵守 **Domain-Driven** 結構，確保 AI 能精確載入上下文。

```text
Project Root
├── .claude/commands/      # [Shared] Spec Kit slash commands (tracked in git)
├── .specify/              # Spec Kit 配置與腳本
│   ├── config/isa.yml     # [ISA] 指令集映射表 (Gherkin -> Python Test)
│   └── templates/         # 核心模版 (Specify, Plan, Tasks, Checklist)
│
├── specs/
│   ├── db_schema/         # [Source of Truth] 資料庫結構 (.dbml)
│   └── features/          # [Gherkin Specs] 依 Domain 分類的功能規格 (.feature)
│       └── <Domain>/
│           ├── <Feature>.feature
│           ├── <Feature>.plan.md    # 由 /speckit.plan 生成的技術藍圖
│           ├── <Feature>.tasks.md   # 由 /speckit.tasks 生成的執行清單
│           └── review.md            # 由 /speckit.review 生成的審查報告
│
├── app/                   # 實作程式碼 (FastAPI / Pydantic)
└── tests/
    ├── conftest.py        # 共用 Mock Fixtures (mock repos)
    ├── unit/              # Service 單元測試
    └── integration/       # BDD 整合測試 (pytest-bdd)
        └── conftest.py    # 共用 BDD 基礎設施 (context, app, table_to_dicts)
```

---

## ⚡ 2. 核心開發流 (The TDD Cycle)

### Step 1: `/speckit.specify` — 需求規格

產出 Gherkin 規格。AI 會根據 DBML 自動補完輸入驗證與 Edge Cases。

### Step 2: `/speckit.clarify` — 自動驗收

AI 扮演 QA 角色，檢查 Feature 是否與 DBML 衝突，提出澄清問題。

### Step 3: `/speckit.plan` — 建築師藍圖

定義 API 契約、Pydantic Models、Service Skeleton、ISA Mapping。

### Step 4: `/speckit.tasks` — 工頭拆解

生成 Phase-based 任務清單 (Skeleton → Unit Tests → BDD → Logic → Cleanup)。

### Step 5: `/speckit.implement` — 填肉實作

依序執行任務，TDD 紅燈→綠燈。完成後可 handoff 至 `/speckit.review`。

### Step 6: `/speckit.review` — 審查報告

生成 `review.md`，彙整測試結果、BDD 覆蓋率、任務完成度、檔案變更。

---

## 🚀 3. 快速上手：完整範例 (Full Walkthrough)

以下以 **CreateAgentV2** 功能為例，展示從零到完成的完整流程。

### Step 1: 撰寫規格

```
/speckit.specify
Type: COMMAND
Feature: agent/CreateAgent
Domain: agent

Requirement: 使用者可以透過一次操作創建 Agent 並同時綁定 MCP Servers
Context: @specs/db_schema/agent.dbml
```

產出: `specs/features/agent/CreateAgent.feature`

### Step 2: 澄清規格

```
/speckit.clarify @specs/features/agent/CreateAgent.feature
```

AI 會提出最多 5 個澄清問題，答案會回寫到 `.feature` 的 Clarifications 區塊。

### Step 3: 產生技術藍圖

```
/speckit.plan @specs/features/agent/CreateAgent.feature
```

產出: `specs/features/agent/CreateAgent.plan.md`

- Section 1: API Specification (endpoint, status codes)
- Section 2: Pydantic Data Models
- Section 3: Service Architecture (skeleton)
- Section 4: Mocking Strategy
- Section 5: ISA Mapping

### Step 4: 拆解任務

```
/speckit.tasks @specs/features/agent/CreateAgent.plan.md
```

產出: `specs/features/agent/CreateAgent.tasks.md`

- Phase 1: Skeletons (schemas, services, routers)
- Phase 2: Unit Tests (RED state)
- Phase 3: BDD Integration Tests (MANDATORY)
- Phase 3.5: **Verify RED** — run tests, confirm all FAIL (TDD gate)
- Phase 4: Logic Implementation (GREEN state, pass count must match RED count)
- Phase 5: Refactor & Cleanup

### Step 5: 執行實作

```
/speckit.implement @specs/features/agent/CreateAgent.tasks.md
```

AI 會逐 Phase 執行任務，在 Docker 中跑測試，直到全綠。

### Step 6: 產生審查報告

```
/speckit.review
```

產出: `specs/features/agent/review.md`  +  `reports/test-report.html`

---

## 🛠️ 4. ISA (Instruction Set Architecture) 系統

為了讓 Gherkin 變成「可執行的代碼」，我們維護一份 `.specify/config/isa.yml`。

| ISA 類型 | Context | 說明 | 定義位置 |
| --- | --- | --- | --- |
| `MOCK_SETUP` | Given | 解析 Gherkin Background data table → `context["background_*"]` | `tests/integration/conftest.py` (共用) |
| `API_CALL` | When | 解析 data table → `context["payload"]` (不發送請求) | 各 feature test file |
| `API_TRIGGER` | Then (internal) | `ensure_called()` — 觸發 HTTP 請求，快取至 `context["response"]` | `tests/integration/conftest.py` (共用) |
| `API_ASSERT` | Then | 驗證 Status Code 與 Response Body | 各 feature test file |
| `DB_ASSERT` | Then | 驗證 Mock Repository 呼叫模式 | 各 feature test file |

### Context Flow (資料流)

```
Given → context["background_mcp"] = table_to_dicts(datatable)
When  → context["payload"]["field"] = value  (from data table)
When  → context["payload"]["mcp_server_ids"] = [ids]  (from data table)
Then  → ensure_called() fires POST /api/agents → context["response"]
Then  → assert context["response"].status_code == 201
```

---

## 📝 5. 命名慣例與驗收標準

### Gherkin 命名格式 (Pattern)

- **Precondition**: `XX 必須/只能 YY` (驗證失敗、狀態衝突)。
- **Postcondition**: `XX 應該 ZZ` (狀態改變、副作用)。

### 驗收清單 (Checklist)

在 Merge 前，必須確保：

1. **[Contract]** 程式碼與 `plan.md` 的 API 定義 100% 一致。
2. **[Isolation]** 所有外部呼叫皆已被 Mock (Las Vegas Rule)。
3. **[Structure]** Router 保持薄層 (Thin)，邏輯皆在 Service 中 (Pure)。
4. **[Tests]** 單元測試覆蓋了 Service 的所有邏輯分支。
5. **[BDD]** 每個 Gherkin Scenario 都有對應的 `@scenario()` 整合測試。
6. **[Report]** `review.md` 已產生且為最新狀態。

---

## 🏷️ 6. Tags 說明

- `@auto_generated`: AI 根據 DBML 自動推導的邏輯（請務必人工 Review）。
- `@happy_path`: 標準成功流程。
- `@edge_case`: 邊界測試 (如空值、極大值)。
- `@wip`: 開發中，CI 應跳過。

---

## 🧪 7. 測試與執行規範 (Testing Environment)

本專案強制要求在 **Docker** 環境中進行測試。

### 常用指令

```bash
# 執行完整測試
docker compose run --rm test

# 執行特定單元測試
docker compose run --rm test pytest tests/unit/test_agent_service.py -v

# 執行 BDD 整合測試
docker compose run --rm test pytest tests/integration/ -v

# 產生測試報告 (HTML + JUnit XML)
docker compose run --rm report

# 型別檢查
docker compose run --rm lint
```
