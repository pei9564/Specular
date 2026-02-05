# 釐清問題

當 `Response_Stream_Aborted` (使用者中斷連線) 發生時，雖然該訊息不存入 `ChatMessage`，但 `AuditLog` 是否仍應記錄該次請求所生成的「部分內容」以及「Token 消耗」？

# 定位

Feature：`Stream生命週期.feature`, `系統維運.feature`。

# 多選題

| 選項 | 描述 |
|--------|-------------|
| A | **完全不記錄**：中斷即視同未發生， Audit Log 僅記錄 status=499。 |
| B | **記錄部分內容**：在 Audit Log 的 response_body 中保留已生成的文字片段，便於成本審計與問題排查。 |
| C | **僅記錄 Token 統計**：不記錄文字，僅記錄消耗的 Token 數。 |
| Short | 記錄部分內容與消耗 |

# 影響範圍

影響系統對於 LLM 成本統計的準確性，以及對異常連線的排查能力。

# 優先級

Low

- 維運與審計細節

---

# 解決記錄

- **回答**：B - 完整記錄 (Full Trace)：在 Audit Log 中保留已生成的文字片段與 Token 消耗。
- **更新的規格檔**：spec/features/Stream生命週期.feature
- **變更內容**：更新 Client Abort 案例，明確指出即便中斷也需在 Audit Log 記錄部分內容與 Token。
