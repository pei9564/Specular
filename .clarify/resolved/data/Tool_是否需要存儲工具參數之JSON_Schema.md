# 釐清問題

`Tool` 實體目前僅包含 `capabilities`，是否需要額外欄位存儲工具的具體參數定義（如 JSON Schema），以便 Agent 在生成 Tool Calls 時參考？

# 定位

ERM: `Table Tool`。
Feature: `Tool查詢.feature`。

# 多選題

| 選項 | 描述 |
|--------|-------------|
| A | 是，需要包含 `parameters` (json) 欄位存儲 JSON Schema |
| B | 否，工具參數定義寫死在後端代碼中，不存資料庫 |
| C | 僅存儲 API Endpoint，由後端動態取得 Schema |
| Short | Format: Short answer (<=5 words) |

# 影響範圍

影響 Agent 定義時的工具提示準確性，以及 `Tool` 資料表的 schema。

# 優先級

High
- 阻礙核心功能 (Agent 使用工具) 的資料建模。

---
# 解決記錄

- **回答**：A - 增加 `parameters` (json) 欄位；額外要求移除 `capabilities` 並新增 `description` 欄位。
- **更新的規格檔**：spec/erm.dbml, spec/features/Tool查詢.feature
- **變更內容**：
    1. 在 `Tool` 表移除 `capabilities` 欄位。
    2. 新增 `description` (varchar) 供 LLM 與使用者辨識。
    3. 新增 `parameters` (json) 存儲 JSON Schema 定義。
    4. 同步更新 `Tool查詢.feature` 中的清單表格。
