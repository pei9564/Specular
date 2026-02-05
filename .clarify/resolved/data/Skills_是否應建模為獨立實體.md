# 釐清問題

Skills 與 MCP Servers 是否應建模為獨立實體以便管理與重複使用？

# 定位

ERM: Skills, McpServers

# 多選題

| 選項 | 描述 |
|--------|-------------|
| A | 是，新增 Skills 與 McpServers 表，以便管理全域可用的工具庫 |
| B | 否，將工具定義直接存於 Agent 的 config 中，不共用 |
| C | 僅新增 Skills 表，MCP 視為外部組態不存入資料庫 |
| Short | |

# 影響範圍

- ERM: 新增 Skills, McpServers 表
- Features: 綁定Agent與Skills, 綁定Agent與MCP, 測試MCP_Server

# 優先級

High

---
# 解決記錄

- **回答**：A - 是，新增 Skills 與 McpServers 兩個獨立實體表...
- **更新的規格檔**：spec/erm.dbml
- **變更內容**：新增 Skills, McpServers 實體及 AgentSkills, AgentMcpServers 關聯表
