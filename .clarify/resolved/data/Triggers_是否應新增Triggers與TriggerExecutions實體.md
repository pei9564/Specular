# 釐清問題

觸發器 (Triggers) 與執行記錄 (TriggerExecutions) 是否應新增為獨立實體？

# 定位

ERM: Triggers, TriggerExecutions

# 多選題

| 選項 | 描述 |
|--------|-------------|
| A | 是，新增 Triggers 與 TriggerExecutions 表，並包含狀態、排程與執行結果等欄位 |
| B | 否，將觸發器設定存於 Agent 的 config JSON 中，不記錄執行歷史 |
| C | 僅新增 Triggers 表，執行記錄寫入一般的 Runs 表 |
| Short | |

# 影響範圍

- ERM: 新增 Triggers, TriggerExecutions 表
- Features: 設定Agent觸發器, 觸發事件並調用Runtime, 查詢觸發器執行歷史

# 優先級

High

---
# 解決記錄

- **回答**：A - 是，新增 Triggers 與 TriggerExecutions 表...
- **更新的規格檔**：spec/erm.dbml
- **變更內容**：新增 Triggers 與 TriggerExecutions 實體以及相關關聯
