# Spec Kit 2.0: AI-Native & Contract-Driven Workflow

本專案採用 **Spec-Driven Development (SDD)** 流程。透過 **Gherkin (規格)**、**DBML (資料結構)** 與 **ISA (指令集)** 的三位一體，實現從需求到「自動化測試代碼」的完整閉環。

## 📂 1. 目錄結構標準 (Directory Structure)

所有檔案必須遵守 **Domain-Driven** 結構，確保 AI 能精確載入上下文。

```text
Project Root
├── specs/
│   ├── db_schema/         # [Source of Truth] 資料庫結構 (.dbml)
│   └── features/          # [Gherkin Specs] 依 Domain 分類的功能規格 (.feature)
│       └── <Domain>/
│           ├── <Feature>.feature
│           ├── <Feature>.plan.md    # 由 /speckit.plan 生成的技術藍圖
│           └── <Feature>.tasks.md   # 由 /speckit.tasks 生成的執行清單
│
├── .specify/              # Spec Kit 配置與腳本
│   ├── config/isa.yml     # [ISA] 指令集映射表 (Gherkin -> Python Test)
│   └── templates/         # 核心模版 (Specify, Plan, Tasks, Checklist)
│
├── app/                   # 實作程式碼 (FastAPI / Pydantic)
└── tests/
    ├── unit/              # Service 單元測試
    └── steps/             # BDD 整合測試 (由 ISA 自動生成)

```

---

## ⚡ 2. 核心開發流 (The TDD Cycle)

### Step 1: `/speckit.specify` (需求與發想)

* **目標**：產出 Gherkin 規格。AI 會根據 `@dbml` 自動補完輸入驗證與 Edge Cases。
* **關鍵標籤**：`Type: COMMAND` (寫入型) 或 `Type: QUERY` (查詢型)。

### Step 2: `/speckit.clarify` (自動驗收)

* **目標**：AI 扮演 QA 角色，檢查 Feature 是否與 DBML 衝突，並移除冗餘的 `@auto_generated` 場景。

### Step 3: `/speckit.plan` (建築師藍圖)

* **目標**：定義 **API 契約**與 **Service 骨架**。
* **產出**：

1. **API Spec (YAML)**：定義 Endpoint。
2. **Pydantic Models**：與 DBML 對齊的資料結構。
3. **Service Skeleton**：帶有 `raise NotImplementedError` 的 Python 類別。

### Step 4: `/speckit.tasks` (工頭拆解)

* **目標**：生成 **Red-Green** 任務清單與自動化測試代碼。
* **自動化機制**：AI 讀取 `.specify/config/isa.yml`，將 Gherkin 步驟「翻譯」為 `pytest-bdd` 測試程式碼。

### Step 5: `/speckit.implement` (填肉實作)

* **目標**：依序執行任務。

1. 產生 Skeleton 檔案 -> **紅燈**。
2. 填入 Business Logic -> **綠燈**。

---

## 🛠️ 3. ISA (Instruction Set Architecture) 系統

為了讓 Gherkin 變成「可執行的代碼」，我們維護一份 `isa.yml`。

| Gherkin 語法範例 | ISA 類型 | 測試行為 |
| --- | --- | --- |
| `(UID={user_id}) 更新進度, call table:` | `API_CALL` | 自動執行 `client.post()` |
| `回應, with table:` | `API_ASSERT` | 驗證 Status Code 與 Response Body |
| `外部服務 {service} 回傳:` | `MOCK_SETUP` | 使用 `mocker.patch` 進行隔離 |

---

## 📝 4. 命名慣例與驗收標準

### Gherkin 命名格式 (Pattern)

* **Precondition**: `XX 必須/只能 YY` (驗證失敗、狀態衝突)。
* **Postcondition**: `XX 應該 ZZ` (狀態改變、副作用)。

### 驗收清單 (Checklist)

在 Merge 前，必須確保：

1. **[Contract]** 程式碼與 `plan.md` 的 API 定義 100% 一致。
2. **[Isolation]** 所有外部呼叫皆已被 Mock (Las Vegas Rule)。
3. **[Structure]** Router 保持薄層 (Thin)，邏輯皆在 Service 中 (Pure)。
4. **[Tests]** 單元測試覆蓋了 Service 的所有邏輯分支。

---

## 🏷️ 5. Tags 說明

* `@auto_generated`: AI 根據 DBML 自動推導的邏輯（請務必人工 Review）。
* `@happy_path`: 標準成功流程。
* `@edge_case`: 邊界測試 (如空值、極大值)。
* `@wip`: 開發中，CI 應跳過。
