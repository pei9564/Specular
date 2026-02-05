# 釐清問題

`Agent查詢.feature` 中提到的 `capabilities` 標籤已在 ERM 修改中移除，查詢結果是否應改為顯示該 Agent 所綁定的 `Tool` 清單及其描述？

# 定位

Feature: `Agent查詢.feature` Rule 1 / Example 1。
ERM: `Table Tool` (已移除 capabilities)。

# 多選題

| 選項 | 描述 |
|--------|-------------|
| A | 是，將 API 回傳欄位改為 `tools` 列出所有綁定工具名稱 |
| B | 仍然保留虛擬的 `capabilities` 欄位，由後端根據 Tool 描述動態生成 |
| C | 改為顯示 Agent 的 `description` 摘要即可 |
| Short | Format: Short answer (<=5 words) |

# 影響範圍

影響 Agent 列表介面的顯示內容與 API 回傳格式，確保與最新資料模型一致。

# 優先級

High
- 修正規格間的不一致 (Consistency Error)。

---
# 解決記錄

- **回答**：A - 是，將 API 回傳欄位改為 `tools` 列出所有綁定工具名稱。
- **更新的規格檔**：spec/features/Agent查詢.feature
- **變更內容**：將 `Agent查詢.feature` 中關於 `capabilities` 的斷言更新為 `tools`，並註明應列出綁定的工具名稱，以符合更新後的資料模型。
