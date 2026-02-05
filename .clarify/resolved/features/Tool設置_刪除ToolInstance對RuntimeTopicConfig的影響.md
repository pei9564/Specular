# 釐清問題

當 Tool Instance 刪除時，若被 `ChatTopic` 的運行配置 (Runtime Config) 引用（除了 `AgentTool` 綁定外的直接引用），該 Tool Instance 是否可被刪除？或是需要進行資源檢查？

# 定位

Feature: `Tool設置.feature` (Rule: 更新與刪除工具實例)
Feature: `Topic設置.feature` (Rule: 初始化策略 / 運行時變更)

# 多選題

| 選項 | 描述 |
|--------|-------------|
| A | 允許刪除，Topic 的 Runtime Config 中的 Tool 參考將失效 (Nullify) |
| B | 不允許刪除，必須先解除所有 Topic 的引用 (Resource In Use) |
| C | 允許刪除，保留歷史，但無法再被新的 Agent 或 Topic 引用 (Semi-Retired) |
| Short | Format: Short answer (<=5 words) |

# 影響範圍

- Feature: `Tool設置` 的刪除驗證邏輯
- Feature: `Topic設置` 的參照完整性

# 優先級

Medium

- 影響資源刪除的邊界行為，可能導致運行時錯誤

---

# 解決記錄

- **回答**：Short - 無法 runtime override，Topic 跟 Tool 的關係是透過 Agent。如果要使用別的 Tool，必須更新所綁定的 Agent。
- **更新的規格檔**：spec/features/Topic設置.feature
- **變更內容**：無，因為這確認了現有設計（Topic 不直接持有 Tool 列表）是正確的，不需要額外的參照檢查邏輯。參照檢查僅需針對 AgentTool 關聯即可。
