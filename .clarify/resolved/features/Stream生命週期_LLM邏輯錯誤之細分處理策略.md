# 釐清問題

當上游 LLM 服務返回特定錯誤（非連線中斷，而是邏輯錯誤）時，系統的反應策略為何？

# 定位

Feature: `Stream生命週期.feature`。
Feature: `系統警示.feature`。

# 多選題

| 選項 | 描述 |
|--------|-------------|
| A | **內容審查攔截 (Content Filter)**：回傳特定系統訊息「內容違反安全政策」 |
| B | **配額超限 (Quota Exceeded)**：提示「系統資源忙碌，請稍後再試」且不扣除 Token 次數 |
| C | **模型超載 (Token Limit)**：當單次 Prompt 過長導致模型拒絕時，提示「訊息過長」 |
| D | **以上皆是**：針對不同錯誤類型回傳細分錯誤訊息 |
| Short | Format: Short answer (<=5 words) |

# 影響範圍

影響使用者體驗 (UX) 與串流錯誤處理的細粒度。

# 優先級

Medium
- 補足 LLM 特定異常情境的處理邏輯。

---
# 解決記錄

- **回答**：D - 以上皆是：針對不同錯誤類型回傳細分錯誤訊息。
- **更新的規格檔**：spec/features/Stream生命週期.feature
- **變更內容**：在 `Stream生命週期.feature` 中新增一個 Rule，定義針對內容攔截 (Content Filter)、Token 超限 (Context Limit) 與配額超限 (Quota Exceeded) 時的具體錯誤訊息內容，提升使用者體驗。
