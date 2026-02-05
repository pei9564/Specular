# 釐清問題

當前端瀏覽器異常關閉或主動斷連 (Client-side Abort) 時，後端是否應立即中止與上游 LLM 的串流請求？

# 定位

Feature: `Stream生命週期.feature`。

# 多選題

| 選項 | 描述 |
|--------|-------------|
| A | 是，立即中止請求以節省 Token 成本與後端資源 |
| B | 否，讓後端完整跑完並存入資料庫，僅中斷前端推送 |
| C | 依據對話長度決定：短對話跑完，長對話中止 |
| Short | Format: Short answer (<=5 words) |

# 影響範圍

影響 Stream API 的實作細節（Signal Handling）與成本考量。

# 優先級

Medium
- 影響資源利用率與邊界情況的系統行為描述。

---
# 解決記錄

- **回答**：A - 是，立即中止請求以節省 Token 成本與後端資源。
- **更新的規格檔**：spec/features/Stream生命週期.feature
- **變更內容**：新增一條 Rule 章節與 Example，明確定義當前端主動中斷（Client Abort）時，後端必須立即中斷與上游 LLM 的連線，且不將未完成的回應存入資料庫。
