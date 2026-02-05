# 釐清問題

當一個 Agent 的狀態變更為 `Retired` (已停用) 時，基於此 Agent 建立的既存對話主題 (Chat Topic) 應如何處理？

# 定位

Feature: `Agent設置.feature` Rule 4 (Lifecycle Rule)。
Feature: `Topic設置.feature`。

# 多選題

| 選項 | 描述 |
|--------|-------------|
| A | **立即失效**：現有的 Topic 嘗試發送訊息時，回傳「Agent 已停用」錯誤 |
| B | **僅限唯讀**：使用者仍可查看歷史，但無法新增訊息 |
| C | **繼續運作**：由於 Topic 已繼承配置，不受 Template Agent 停用影響 |
| D | **強制更新**：提示使用者必須切換至另一個 Active Agent 才能繼續 |
| Short | Format: Short answer (<=5 words) |

# 影響範圍

影響 Agent 生命週期管理的連鎖反應邏輯 (Cascade Impact)。

# 優先級

Medium
- 影響 Agent 停用後的系統行為定義。

---
# 解決記錄

- **回答**：B - 僅限唯讀：使用者仍可查看歷史，但無法新增訊息。
- **更新的規格檔**：spec/features/Agent設置.feature
- **變更內容**：在 `Agent設置.feature` 中新增一個 Example，明確定義當 Agent 停用 (Retired) 時，既存的 Topic 會進入唯讀模式，允許查詢歷史但拒絕新的訊息發送。
