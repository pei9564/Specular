# 釐清問題

Agent 的 mode 欄位具體支援哪些模式？

# 定位

ERM: Agents.mode

# 多選題

| 選項 | 描述 |
|--------|-------------|
| A | Chat, Task |
| B | Chat, Task, Workflow |
| C | Chat, Completion, Job |
| Short | List accepted values (e.g. Chat, Task) |

# 影響範圍

- ERM: Agents.mode 定義
- Features: 創建Agent (驗證規則), 觸發事件並調用Runtime (Task 模式行為)

# 優先級

High

---
# 解決記錄

- **回答**：A - Chat, Task
- **更新的規格檔**：spec/erm.dbml
- **變更內容**：更新 Agents.mode 的 note 說明為 'chat, triggers'
