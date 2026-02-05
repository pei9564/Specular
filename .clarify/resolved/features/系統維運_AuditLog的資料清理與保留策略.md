# 釐清問題

隨時間累積的 `AuditLog` 與 `ChatMessage` 資料量可能極大，系統是否應定義自動清理或存檔策略？

# 定位

Feature：`系統維運.feature` (Logging Resilience)。

# 多選題

| 選項 | 描述 |
|--------|-------------|
| A | 永久保留：不進行自動清理 |
| B | 滾動保留：僅保留最近 90 天，舊資料自動刪除 |
| C | 封存策略：舊資料移至冷儲存 (如 S3/Blob) |
| Short | 採 90 天滾動保留 |

# 影響範圍

影響資料庫維運成本、營運儲存策略以及系統效能。

# 優先級

Medium

- 影響維運策略與長期穩定性

---

# 解決記錄

- **回答**：AuditLog: B (90天滾動), ChatMessage: A (永久保留)
- **更新的規格檔**：spec/features/系統維運.feature, spec/erm.dbml
- **變更內容**：在系統維運 Feature 中定義自動清理規則，並同步更新資料庫中 AuditLog 與 ChatMessage 的保留政策說明。
