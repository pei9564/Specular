# 釐清問題

Agent 狀態欄位目前僅定義了 `Active` 與 `Deleted`，是否應增加 `Inactive` (停用/隱藏) 狀態，以區分「暫時不可見」與「永久刪除」？

# 定位

ERM：`Agent.status` 屬性。
Feature：`Agent查詢.feature` 中的顯示過濾條件。

# 多選題

| 選項 | 描述 |
|--------|-------------|
| A | 保持現狀：僅 Active 與 Deleted，停用即視為刪除 |
| B | 增加 Inactive：可用於後台管理停用，前台不顯示但資料保留 |
| C | 增加 IsVisible 標籤：狀態保持 Active，但可由管理員設為不可見 |
| Short | 僅用 Active/Deleted |

# 影響範圍

影響 `Agent` 的生命週期管理、後台管理介面以及 `ListAvailableAgents` 的過濾邏輯。

# 優先級

Medium

- 影響邊界條件或測試完整性

---

# 解決記錄

- **回答**：A - 保持現狀：僅 Active 與 Deleted，停用即視為刪除
- **更新的規格檔**：spec/features/Agent查詢.feature
- **變更內容**：在 Agent 查詢範例中加入狀態過濾驗證，確保 Deleted 狀態的 Agent 不會出現在清單中。
