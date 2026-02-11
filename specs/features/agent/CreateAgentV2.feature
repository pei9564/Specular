# -------------------------------------------------------------------------
# SPEC-KIT SYSTEM INSTRUCTION (DO NOT REMOVE)
# -------------------------------------------------------------------------
# Role: Senior Product Architect & QA Lead
# Type: COMMAND (State Change)
# Context: @specs/db_schema/agent.dbml
# Base: 創建Agent.feature (V1)
# -------------------------------------------------------------------------
@wip
Feature: CreateAgentV2
  使用者可以透過一次操作創建 Agent 並同時綁定 MCP Servers，
  取代 V1 需要分步操作的流程，提升配置效率。

  Background:
    Given 系統中存在以下 LLM 模型:
      | model_id | provider  | status |
      | gpt-4o   | openai    | active |
      | claude-3 | anthropic | active |
    And 系統中存在以下 MCP Servers:
      | mcp_id  | name   | status   |
      | mcp-001 | Slack  | active   |
      | mcp-002 | GitHub | active   |
      | mcp-003 | Jira   | inactive |
    And 使用者 "user-001" 已登入且擁有 "create:agent" 權限
  # ===========================================================================
  # BLOCK A: COMMAND (Create) - 輸入驗證與狀態檢查
  # ===========================================================================
  # ---- V1 基礎規則 (繼承自 創建Agent.feature，此處不重複) ----
  # 名稱唯一性、格式驗證、LLM 模型驗證、權限檢查、配額限制
  # 上述規則在 V1 已完整定義，V2 僅新增以下擴展規則

  Rule: [Precondition] 綁定的 MCP Servers 必須存在且為啟用狀態

    @auto_generated
    Scenario: 失敗 - 綁定不存在的 MCP Server
      Given 系統中不存在 mcp_id 為 "mcp-999" 的 MCP Server
      When 使用者創建 Agent 並綁定 MCP Servers:
        | mcp_id  |
        | mcp-001 |
        | mcp-999 |
      Then 創建應失敗
      And 錯誤訊息應提示 "mcp-999" 不存在

    @auto_generated
    Scenario: 失敗 - 綁定已停用的 MCP Server
      When 使用者創建 Agent 並綁定 MCP Servers:
        | mcp_id  |
        | mcp-003 |
      Then 創建應失敗
      And 錯誤訊息應提示 "mcp-003" 目前為停用狀態，無法綁定

    @auto_generated
    Scenario: 失敗 - 綁定重複的 MCP Server
      When 使用者創建 Agent 並綁定 MCP Servers:
        | mcp_id  |
        | mcp-001 |
        | mcp-001 |
      Then 創建應失敗
      And 錯誤訊息應提示 MCP Server 不可重複綁定

  # ===========================================================================
  # BLOCK A: COMMAND (Create) - 成功執行後的狀態改變
  # ===========================================================================

  Rule: [Postcondition] 成功創建 Agent 應同時建立 MCP Server 關聯記錄

    Scenario: 成功 - 創建 Agent 並同時綁定 MCP Servers
      Given 系統中不存在名為 "McpBot" 的 Agent
      When 使用者創建 Agent:
        | field         | value            |
        | name          | McpBot           |
        | system_prompt | 你是一個全能助手 |
        | model_id      | gpt-4o           |
        | mode          | chat             |
      And 同時綁定 MCP Servers:
        | mcp_id  |
        | mcp-001 |
        | mcp-002 |
      Then Agent "McpBot" 應成功建立
      And 資料庫 Agents 表應包含:
        | field    | value    |
        | name     | McpBot   |
        | owner_id | user-001 |
        | status   | active   |
        | mode     | chat     |
        | model_id | gpt-4o   |
      And 資料庫 AgentMcpServers 表應包含 2 筆記錄，關聯至 "McpBot"

    Scenario: 成功 - 創建 Agent 不綁定任何 MCP Server（向下相容 V1）
      Given 系統中不存在名為 "SimpleBot" 的 Agent
      When 使用者創建 Agent:
        | field         | value            |
        | name          | SimpleBot        |
        | system_prompt | 你是一個簡單助手 |
        | model_id      | claude-3         |
        | mode          | chat             |
      And 未指定任何 MCP Servers
      Then Agent "SimpleBot" 應成功建立
      And 資料庫 AgentMcpServers 表不應有 "SimpleBot" 的關聯記錄

  Rule: [Postcondition] 綁定的 MCP Server 記錄應使用正確的預設值

    @auto_generated
    Scenario: 成功 - AgentMcpServers 的 enabled 預設為 true
      When 使用者創建 Agent "DefaultBot" 並綁定 mcp-001（未指定 enabled）
      Then AgentMcpServers 記錄的 enabled 欄位應為 true

  Rule: [Postcondition] MCP Server 綁定失敗時應整體回滾，不留部分狀態

    Scenario: 原子性 - Agent 基本資料驗證通過但 MCP Server 驗證失敗時，整體回滾
      When 使用者創建 Agent:
        | field    | value       |
        | name     | RollbackBot |
        | model_id | gpt-4o      |
      And 同時綁定 MCP Servers:
        | mcp_id  |
        | mcp-999 |
      Then 創建應失敗
      And 資料庫 Agents 表不應包含 "RollbackBot"
      And 資料庫 AgentMcpServers 表不應有 "RollbackBot" 的關聯記錄

  Rule: [Postcondition] 使用 triggers 模式創建的 Agent 應正確記錄 mode

    Scenario: 成功 - 以 triggers 模式創建 Agent 並綁定 MCP Server
      When 使用者創建 Agent:
        | field         | value        |
        | name          | TriggerBot   |
        | system_prompt | 自動觸發助手 |
        | model_id      | gpt-4o       |
        | mode          | triggers     |
      And 同時綁定 MCP Servers:
        | mcp_id  |
        | mcp-001 |
      Then Agent "TriggerBot" 應成功建立
      And 資料庫 Agents 表中 "TriggerBot" 的 mode 應為 "triggers"
      And 資料庫 AgentMcpServers 表應包含 1 筆記錄，關聯至 "TriggerBot"

  # Clarifications
  ### Session 2026-02-11
  # - Q: V2 應包含哪些擴展綁定？ → A: 僅 MCP Servers（不含 Skills 和 Knowledge Bases）
  # - Q: 每個 Agent 可綁定的 MCP Server 數量是否有上限？ → A: 無上限，可綁定所有可用的 active MCP Servers
