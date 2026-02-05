# 釐清問題

`ChatMessage` 的 `content` 目前為 `text` (String)，是否應改為 `json` 或增加 `type` 欄位以處理非純文字內容（如 Tool Calls, Tool Results）？

# 定位

ERM: `Table ChatMessage` 的 `content` 屬性。

# 多選題

| 選項 | 描述 |
|--------|-------------|
| A | 保持 `text`，非文字內容轉為 JSON 字串存儲 |
| B | 改為 `json` 類型，原生支援結構化對話紀錄 |
| C | 增加 `message_type` 欄位 (text, tool_call, tool_result) |
| Short | Format: Short answer (<=5 words) |

# 影響範圍

影響對話歷史的讀取與寫入邏輯，特別是涉及工具使用的對話。

# 優先級

High
- 影響核心對話資料結構與 LLM 互動實作。

---
# 解決記錄

- **回答**：B - 將型別改為 JSON 格式，原生支援結構化的對話紀錄
- **更新的規格檔**：spec/erm.dbml
- **變更內容**：將 `ChatMessage.content` 的型別從 `text` 改為 `json`，並更新 note 說明；調整 `role` 說明以包含 `tool` 角色。
