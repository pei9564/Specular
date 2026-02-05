# 釐清問題

`ChatMessage.content` 目前定義為 JSON 型別，為了處理純文字、Tool Calls 與 Tool Results，其內部的具體結構規範為何？

# 定位

ERM：`ChatMessage.content` 屬性。
Feature：`Context組裝策略.feature` 與對話流程。

# 多選題

| 選項 | 描述 |
|--------|-------------|
| A | 遵循 OpenAI API 格式：使用 `content`, `tool_calls` 等欄位 |
| B | 統一包裝格式：`{ "type": "text/tool", "data": ... }` |
| C | LangChain 原始序列化格式：存入 `MessageDict` |
| Short | 採 OpenAI 格式 |

# 影響範圍

影響前後端資料交換介面定義、渲染邏輯以及 LangGraph State 的初始化轉換。

# 優先級

High

- 阻礙核心功能定義或資料建模

---

# 解決記錄

- **回答**：A - 遵循 OpenAI API 格式：使用 OpenAI 標準的 `content` 與 `tool_calls` 欄位
- **更新的規格檔**：spec/erm.dbml
- **變更內容**：更新 ChatMessage.content 屬性註解，明確指出其遵循 OpenAI 格式。
