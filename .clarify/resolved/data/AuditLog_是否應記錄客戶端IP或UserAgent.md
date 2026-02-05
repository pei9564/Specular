# 釐清問題

除了 `trace_id` 與 `request_body`，`AuditLog` 是否也應記錄客戶端的網路環境資訊（如 IP 位址、User-Agent），以加強安全性檢查？

# 定位

ERM：`AuditLog` Table。

# 多選題

| 選項 | 描述 |
|--------|-------------|
| A | **不記錄**：僅專注於業務邏輯追蹤，網路環境資訊交由 Gateway (Nginx/Envoy) 日誌負責。 |
| B | **基本記錄**：新增 `ip_address` 與 `user_agent` 欄位。 |
| C | **僅記錄 IP**：出於隱私考量，僅記錄遮罩後的 IP (Masked IP)。 |
| Short | 交由 Gateway 負責 |

# 影響範圍

影響 Audit Log 資料表的大小，以及在應用程式層級進行 IP 限流或異常偵測的能力。

# 優先級

Medium

- 審計完整性考量

---

# 解決記錄

- **回答**：A - 不記錄：僅專注於應用程式層級的業務追蹤。網路環境資訊由基礎設施層負責。
- **更新的規格檔**：spec/erm.dbml
- **變更內容**：無欄位變動。維持現狀，並在開發時依賴 Gateway 日誌處理網路層審計。
