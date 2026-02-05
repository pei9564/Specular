# 釐清問題

當使用者的權限從 `Admin` 降級為 `Standard` 時，若該使用者原本擁有使用 `Admin-Only` 模型建立的對話主題 (Topic)，該對話應如何處理？

# 定位

Feature: `Topic設置.feature` Rule 3 (Security Rule)。

# 多選題

| 選項 | 描述 |
|--------|-------------|
| A | **拒絕訪問**：使用者無法再進入該 Topic 介面，提示權限不足 |
| B | **強制降級**：仍可進入，但系統強制將模型切換為該使用者可用的 Public 模型 |
| C | **唯讀模式**：可看歷史，但發送訊息時會提示權限錯誤 |
| Short | Format: Short answer (<=5 words) |

# 影響範圍

影響權限系統與 Topic 運行時配置的安全性檢查邏輯。

# 優先級

Medium
- 影響邊界權限異動時的系統穩健性。

---
# 解決記錄

- **回答**：B - 強制降級：仍可進入，但系統強制將模型切換為該使用者可用的 Public 模型。
- **更新的規格檔**：spec/features/Topic設置.feature
- **變更內容**：在 `Topic設置.feature` 中新增一個 Example，明確定義當使用者權限降級（Admin -> Standard）後，嘗試在原本綁定 Admin-Only 模型的 Topic 發送訊息時，系統應自動將模型切換為 Public 預設模型並提示使用者，以確保對話可用性與安全性。
