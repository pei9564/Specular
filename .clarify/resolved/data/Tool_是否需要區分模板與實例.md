# 釐清問題

使用者希望能基於同一個「工具模板 (Tool Template)」(例如：網頁爬蟲) 建立多個不同配置的「工具實例 (Tool Instance)」(例如：PTT 爬蟲、Yahoo 新聞爬蟲)，並各有獨立名稱。這暗示目前的資料模型需要進行重構。

# 定位

ERM: `Table Tool`
Feature: `Tool查詢.feature`

# 選項

| 選項 | 描述 |
|--------|-------------|
| A | **分離模板與實例 (Template/Instance)**：<br>1. 將現有 `Tool` 改為 `ToolTemplate` (定義代碼與參數 Schema)。<br>2. 新增 `ToolInstance` 表 (定義名稱與預設參數值)。<br>3. Agent 僅能綁定 `ToolInstance`。 |
| B | **僅在 Agent 層級配置 (Agent-Level Config)**：<br>維持 `Tool` 單一層級。在 `AgentTool` 關聯表中增加 `config` 欄位。<br>缺點：無法建立可被多個 Agent 共用的 "PTT Tool"，每次綁定都要重設參數。 |
| C | **混合模式**：<br>保留 `Tool` 為通用定義。允許建立 `CustomTool` 繼承並覆寫參數。<br>實作上與 A 類似，但強調繼承關係。 |
| Short | Format: Short answer (<=5 words) |

# 影響範圍

- **ERM**: 需大規模重構 Tool 相關表格。
- **Feature**: `Tool查詢` 需區分為「查詢可用模板」與「查詢已建立工具」。
- **API**: 需新增「建立工具實例」的管理功能。

# 優先級

High

- 核心資料結構變更，影響 Agent 與 Tool 的綁定邏輯。

---

# 解決記錄

- **回答**：A - 分離模板與實例 (Template/Instance)。
- **更新的規格檔**：`spec/erm.dbml`, `spec/features/Tool查詢.feature`, `spec/features/Agent設置.feature`
- **變更內容**：
  1. **ERM**: 將 `Tool` 表拆分為 `ToolTemplate` (定義 Schema) 與 `ToolInstance` (定義 Config)，並更新 `AgentTool` 關聯。
  2. **Tool查詢**: 區分二階段查詢，先查 Template 建立 Instance，再查 Instance 供 Agent 綁定。
  3. **Agent設置**: 範例更新為使用 `tool_calc_v1` (Instance ID) 而非通用名稱。
