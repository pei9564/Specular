# 釐清問題

當歷史訊息總 Token 數超過模型上限時，具體的截斷策略為何？

# 定位

Feature: `Context組裝策略.feature` Rule 1 / Example 3。

# 多選題

| 選項 | 描述 |
|--------|-------------|
| A | FIFO：由舊到新逐條刪除歷史訊息，直到滿足 Token 限制 |
| B | 綜合評分：保留最有價值的訊息 (如 User 提問)，刪除 Assistant 冗長回答 |
| C | 滑動視窗：固定只取最後 N 則訊息，即使 Token 還有剩也不多取 |
| D | 直接出錯：不自動截斷，提示使用者手動清除對話 (Clear Topic) |
| Short | Format: Short answer (<=5 words) |

# 影響範圍

影響 `Context組裝策略` 的核心演算法實作與測試案例設計。

# 優先級

High
- 阻礙長對話場景下的系統穩定性定義。

---
# 解決記錄

- **回答**：C (固定視窗) + A (超過時由舊到新刪除)。
- **更新的規格檔**：spec/features/Context組裝策略.feature
- **變更內容**：明確定義截斷策略為：首先應用 STM (Short Term Memory) 的訊息視窗限制，若該視窗內訊息總量仍超過模型 Token 上限，則採取 FIFO (First-In-First-Out) 策略從最舊的訊息開始截斷，並確保 System Prompt 永遠保留。
