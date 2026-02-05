# 釐清問題

`ChatTopic.stm_window` 控制短期記憶視窗（LangGraph 裁減歷史訊息的個數），該屬性是否有系統層級的最大值限制？

# 定位

ERM：`ChatTopic.stm_window` 屬性。
Feature：`Context組裝策略.feature` 中的組裝邏輯。

# 多選題

| 選項 | 描述 |
|--------|-------------|
| A | 硬性上限：最大 50 則 (為了效能) |
| B | 動態上限：不設限，僅受模型 Token Window 限制 |
| C | 分層上限：一般使用者 20，Admin 100 |
| Short | 不設硬性上限 |

# 影響範圍

影響使用者在更新 Topic 配置時的參數驗證規則。

# 優先級

Medium

- 影響邊界條件與驗證規則

---

# 解決記錄

- **回答**：Short - 上限 15
- **更新的規格檔**：spec/erm.dbml, spec/features/Topic設置.feature
- **變更內容**：在資料庫備註與 Feature 驗證規則中增加 stm_window 最大值為 15 的限制。
