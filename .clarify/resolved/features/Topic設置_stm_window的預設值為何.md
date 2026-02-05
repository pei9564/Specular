# 釐清問題

當使用者建立一個新的 `ChatTopic` 且未明確指定 `stm_window` (短期記憶視窗) 時，系統預設應套用多少個訊息數量？

# 定位

ERM：`ChatTopic.stm_window`。
Feature：`Topic設置.feature` (預設值)。

# 多選題

| 選項 | 描述 |
|--------|-------------|
| A | **One-shot (0)**：預設不帶入歷史，僅單次問答。 |
| B | **常用預設 (5-10)**：預設保留最近 10 則對話（目前 stm_window 上限為 15）。 |
| C | **最大值 (15)**：預設給予該 Agent 支援的最大上下文寬度。 |
| Short | 預設視窗大小為 10 |

# 影響範圍

影響初次建立話題時的使用者體驗，以及對話的預設連貫性。

# 優先級

Medium

- 影響 Topic 初始化行為

---

# 解決記錄

- **回答**：B - 常用預設 (10)：預設保留最近 10 則對話。
- **更新的規格檔**：spec/erm.dbml, spec/features/Topic設置.feature
- **變更內容**：在 ERM 中為 stm_window 加上 default: 10 註解，並在 Topic 設置 Feature 中明確指出初始化時的預設值。
