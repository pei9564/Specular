# 釐清問題

當一個 `ToolTemplate` (模板) 被刪除時，已基於該模板建立的所有 `ToolInstance` (實例) 應如何處理？

# 定位

Feature：`Tool設置.feature` (層聯刪除規則)。

# 多選題

| 選項 | 描述 |
|--------|-------------|
| A | 阻止刪除：若存在實例，則不允許刪除模板 |
| B | 層聯刪除 (Cascade)：一併刪除所有關聯的實例 (會影響 Agent 綁定) |
| C | 孤立保留：保留實例資料，但標記模板已遺失 (容易造成 Runtime Error) |
| Short | 阻止刪除模板 |

# 影響範圍

影響工具管理功能的健全性與資料完整性約束。

# 優先級

Medium

- 涉及資料一致性與層聯風險

---

# 解決記錄

- **回答**：B - 層聯刪除 (Cascade)：一併刪除所有關聯的實例 (會影響 Agent 綁定)
- **更新的規格檔**：spec/features/Tool設置.feature, spec/erm.dbml
- **變更內容**：在 Tool設置.feature 中新增模板刪除規則，並在 erm.dbml 中註記 template_id 為層聯刪除。
