# 釐清問題

`AuditLog` 目前透過 `trace_id` 追蹤請求，是否需要直接關聯 `ChatSession` 以便快速檢索特定對話的完整通訊細節？

# 定位

ERM: `Table AuditLog` 與 `Table ChatSession` 的關係。

# 多選題

| 選項 | 描述 |
|--------|-------------|
| A | 是，在 `AuditLog` 增加 `session_id` 外鍵 |
| B | 是，在 `AuditLog` 增加 `topic_id` 外鍵 |
| C | 否，僅透過 `trace_id` 或 `user_id` 交叉查詢即可 |
| Short | Format: Short answer (<=5 words) |

# 影響範圍

影響日誌檢視功能的查詢效率與資料庫架構設計。

# 優先級

Medium
- 影響系統可觀測性與除錯便利性.

---
# 解決記錄

- **回答**：A - 是，在 `AuditLog` 增加 `session_id` 外鍵。
- **更新的規格檔**：spec/erm.dbml
- **變更內容**：在 `AuditLog` 實體中新增 `session_id` 欄位，並建立指向 `ChatSession.session_id` 的外鍵關聯，以強化系統的可追蹤性。
