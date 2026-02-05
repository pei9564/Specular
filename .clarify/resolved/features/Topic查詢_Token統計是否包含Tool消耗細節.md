# 釐清問題

在 `Topic查詢.feature` 中，當回傳的 Token 使用統計資訊 (Token Usage) 時，是否需要包含此次對話所使用的 Tool Instance 的 Token 消耗細節？

# 定位

Feature: `Topic查詢.feature` (Rule: 進入 Topic 時應同時獲取運行配置與對話歷史)
Entity: `ChatMessage` (Token Count)

# 多選題

| 選項 | 描述 |
|--------|-------------|
| A | 否，僅回傳總 Token 數，不區分 Tool |
| B | 是，需回傳每個 Tool Call 的 Token 消耗 |
| C | 是，僅回傳 Tool 類別的總 Token 消耗 |
| Short | Format: Short answer (<=5 words) |

# 影響範圍

- Feature: `Topic查詢` API 回傳結構
- 系統監控與計費精細度

# 優先級

Low

- 優化查詢資訊的豐富度，不影響核心流程

---

# 解決記錄

- **回答**：A - 否，僅回傳總 Token 數，不區分 Tool。
- **更新的規格檔**：spec/features/Topic查詢.feature
- **變更內容**：在 `Topic查詢.feature` 的 Example 中，Metadata 檢查點備註更新為「僅總量」，確認不需實作細分統計，簡化開發。
