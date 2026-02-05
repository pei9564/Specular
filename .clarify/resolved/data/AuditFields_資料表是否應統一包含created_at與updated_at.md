# 釐清問題

為了滿足審計與排錯需求，系統中所有的配置實體（Agent, ToolInstance, LLM）以及紀錄（Topic, Session）是否應統一包含 `created_at` 與 `updated_at` 欄位？

# 定位

ERM：全域資料模型。

# 多選題

| 選項 | 描述 |
|--------|-------------|
| A | **最小化設計**：僅在必要表（如 Log, Topic）加上 `created_at`，不使用 `updated_at`。 |
| B | **標準化設計**：所有配置表均包含 `created_at` 與 `updated_at`。 |
| C | **含 User 資訊**：除了時間戳，也記錄 `updated_by`。 |
| Short | 採標準化設計 (Time only) |

# 影響範圍

影響 DB Schema 的統一性，以及管理介面顯示「最後更新時間」的能力。

# 優先級

Low

- 屬性完整性優化

---

# 解決記錄

- **回答**：B - 標準化設計 (Time only)：所有資料表均統一包含 created_at 與 updated_at 時間戳記。
- **更新的規格檔**：spec/erm.dbml
- **變更內容**：已為 ERM 中所有的 Table 補上 created_at 與 updated_at 欄位定義。
