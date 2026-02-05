# 釐清問題

當 `Agent.llm_id` 與 `ChatTopic.current_llm_id` 均未指定（均為 `null`）時，系統是否應具備全局預設模型 (System Default Model) 作為備援？

# 定位

ERM：`Agent.llm_id`, `ChatTopic.current_llm_id`。
Feature：`Topic設置.feature` (Initialization logic)。

# 多選題

| 選項 | 描述 |
|--------|-------------|
| A | **不允許空值**：在建立 Topic 或 Agent 時強制要求至少擇一指定，否則回傳錯誤。 |
| B | **備援預設模型**：若均未指定，自動使用系統配置中的 `DEFAULT_LLM_ID` (如 `gpt-4o-mini`)。 |
| C | **動態查詢**：由系統根據使用者的 Role 或可用模型清單，自動分配權限內最高優先級的模型。 |
| Short | 指定備援預設模型 |

# 影響範圍

影響 Session 初始化時的 Graph 建構穩定性，以及系統預設值的配置策略。

# 優先級

High

- 阻礙對話啟動流程的健壯性設計

---

# 解決記錄

- **回答**：A - 不允許空值：在建立 Topic 或 Agent 時強制要求至少擇一指定，否則回傳錯誤。
- **更新的規格檔**：spec/features/Topic設置.feature, spec/erm.dbml
- **變更內容**：在 Topic 設置 Feature 中新增驗證案例，若 Agent 或 Topic 參數均未提供 LLM 則報錯。並在 ERM 中註記此相依性。
