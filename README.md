這是一份更新後的 **Spec Kit 開發指南 (README)**，我已經將我們剛剛整合的 **「Auto-Generate (自動發想)」** 機制與 **「Command/Query 分流」** 邏輯完全寫入標準作業程序中。

這份文件現在不僅是操作手冊，更是引導團隊如何利用 AI「主動補完邏輯」的說明書。

---

# Spec Kit Development Workflow (AI-Native + CQRS)

本專案採用 **Spec-Driven Development (SDD)** 流程。我們利用 Spec Kit 的自訂模版，結合 **CQRS** 架構與 **DBML** 資料庫定義，實現高度自動化的測試案例生成。

## 📂 1. 目錄結構標準 (Directory Structure)

所有規格與 Schema 必須嚴格遵守 **Domain-Driven** 結構，以便 AI 載入 Context。

```text
spec/
├── db_schema/                  # [Single Source of Truth] 資料庫結構定義
│   ├── identity.dbml           # User, Auth 相關 (定義了 Unique, Not Null 等限制)
│   ├── ecommerce.dbml          # Order, Product 相關
│   └── _relationships.dbml     # 跨領域關聯
│
└── features/                   # [Gherkin Specs] 功能規格
    ├── Identity/               # Domain Folder
    │   ├── ChangePassword.feature    # (Command)
    │   └── GetUserProfile.feature    # (Query)
    │
    └── Ecommerce/              # Domain Folder
        └── ...

```

---

## ⚡ 2. 黃金法則 (The Golden Rules)

在使用 Spec Kit (Claude) 時，**必須**養成以下習慣以觸發自動化邏輯：

1. **明確定義類型**：開頭宣告 **"Type: COMMAND"** 或 **"Type: QUERY"**。
2. **帶入資料庫 Context**：指令結尾必須附上 **DBML 檔案路徑** (使用 `@` 符號)。AI 會讀取 DBML 中的 `NOT NULL`、`UNIQUE` 等限制，**自動生成 Edge Cases**。

---

## 🛠️ 3. 開發工作流 (Step-by-Step)

### Step 1: 建立規格 (`/speckit.specify`)

利用 AI 的 **Auto-Generate Mode**。你只需要提供「一句話需求」，AI 會根據 DBML 幫你補完 80% 的驗證邏輯。

#### 🅰️ 場景 A：建立 Command (修改型)

* **AI 行為**：自動生成輸入驗證、狀態衝突檢查、資料庫寫入驗證。
* **Prompt 範本**：

```text
/speckit.specify
Type: COMMAND
Feature: [FeatureName]
Domain: [DomainFolder]

Requirement: [簡述需求，例如：使用者可以修改 Email]
Context: @spec/db_schema/[domain].dbml

```

> **AI 自動推導範例**：
> 如果 `dbml` 定義 `email` 為 `unique`，AI 會自動生成 Scenario: *"當 Email 已存在時，操作應失敗"*。

#### 🅱️ 場景 B：建立 Query (查詢型)

* **AI 行為**：自動生成權限檢查、資料過濾邏輯、回傳結構驗證。
* **Prompt 範本**：

```text
/speckit.specify
Type: QUERY
Feature: [FeatureName]
Domain: [DomainFolder]

Requirement: [簡述需求，例如：使用者查詢自己的訂單列表]
Context: @spec/db_schema/[domain].dbml

```

---

### Step 2: 澄清與審查 (`/speckit.clarify`)

此階段重點在於 **「驗收 AI 自動生成的邏輯」**。

* **檢查重點**：

1. 尋找標記為 `@auto_generated` 的 Scenarios。
2. 確認 AI 推導的 Edge Case (如 `NotNull` 檢查) 是否符合業務需求？
3. 刪除過度設計或不必要的 Scenarios。

**Prompt 範本**：

```text
/speckit.clarify @spec/features/[Domain]/[Feature].feature
"Review the @auto_generated scenarios against the DBML: @spec/db_schema/[domain].dbml.
1. Are the inferred validation rules correct?
2. Did we miss any domain-specific business logic?"

```

---

### Step 3: 技術規劃 (`/speckit.plan`)

確保實作計畫符合 **Python 微服務** 與 **Las Vegas Rule**。

**Prompt 範本**：

```text
/speckit.plan
Based on @spec/features/[Domain]/[Feature].feature

Requirements:
1. Define Pydantic models for the payload/response.
2. Follow "Las Vegas Rule": Define how to MOCK external services (e.g., Email, Payment).
3. Map Gherkin steps to specific Service Layer methods.

```

---

## 📝 4. Gherkin 命名慣例 (Naming Conventions)

AI 會根據 Template 自動套用以下中文命名格式，Review 時請確保一致性：

| 功能類型 | Rule 類別 | 命名格式 (Pattern) | 測試重點 |
| --- | --- | --- | --- |
| **COMMAND** | **Precondition** | `XX 必須/只能 YY` | **驗證失敗** (Validation Failures, State Conflicts) |
| **COMMAND** | **Postcondition** | `XX 應該 ZZ` | **狀態改變** (State Changes, Side Effects) |
| **QUERY** | **Precondition** | `XX 必須/只能 YY` | **權限拒絕** (Auth Scope, Invalid Params) |
| **QUERY** | **Success** | `成功查詢應 XX` | **資料正確性** (Data Completeness, Format) |

---

## 🏷️ 5. Tags 說明

* `@wip`: Work In Progress，尚未完成實作的功能。
* `@auto_generated`: 由 AI 根據 DBML 或通用邏輯自動推導出的 Scenario，需人工 Review。
* `@happy_path`: 正常流程。
* `@edge_case`: 邊界測試 (如空值、極大值)。
