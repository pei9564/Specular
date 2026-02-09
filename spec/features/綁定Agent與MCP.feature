Feature: 綁定 Agent 與 MCP
  連接 MCP Server 賦予 Agent 外部工具能力

  Background:
    Given Agent "MathBot" (agent-001) 與 Agent "CodeBot" (agent-002) 存在
    And MCP Server "WeatherService" (mcp-001) 與 "DatabaseTool" (mcp-002) 存在
    And 使用者 "user-001" 為 MathBot 與 WeatherService 的擁有者

  Rule: 使用者可以將 MCP Server 綁定到自己的 Agent

    Example: 成功 - 綁定單一 MCP Server
      Given Agent "agent-001" 尚未綁定任何 MCP
      When 使用者將 "WeatherService" 綁定至 "agent-001"
      Then agent_mcp_bindings 表應新增關聯記錄
      And Agent "agent-001" 應能存取 WeatherService 的工具

    Example: 成功 - 綁定多個 MCP Server
      When 使用者同時綁定 "WeatherService" 與 "DatabaseTool" 至 "agent-001"
      Then agent_mcp_bindings 表應新增兩筆關聯記錄

    Example: 成功 - 綁定公開的 MCP Server
      Given "EmailService" (mcp-003) 是公開的 MCP Server
      When 使用者將 "EmailService" 綁定至 "agent-001"
      Then 綁定應成功

    Example: 失敗 - 無法綁定 private MCP Server（非擁有者）
      Given "PrivateTool" 是他人擁有的 private MCP Server
      When 使用者嘗試綁定 "PrivateTool"
      Then 綁定應失敗並提示權限不足

    Example: 失敗 - 無法綁定狀態異常的 MCP Server
      Given "BrokenService" 狀態為 error
      When 使用者嘗試綁定 "BrokenService"
      Then 綁定應失敗

    Example: 失敗 - 非 Agent 擁有者無法綁定
      When 使用者嘗試將 MCP 綁定至他人的 Agent "CodeBot"
      Then 綁定應失敗並提示權限不足

  Rule: 系統應正確處理重複綁定的情況

    Example: 冪等性 - 重複綁定
      Given Agent 已綁定該 MCP Server
      When 使用者再次執行綁定
      Then 綁定操作應視為成功
      And 資料庫不應產生重複記錄
      And 回傳結果應提示已綁定

  Rule: 使用者可以解除 Agent 與 MCP Server 的綁定

    Example: 成功 - 解除綁定
      Given Agent 已綁定 MCP "WeatherService"
      When 使用者解除該綁定
      Then agent_mcp_bindings 表應移除對應記錄
      And Agent 應無法再存取該 MCP 的工具

    Example: 成功 - 解除所有綁定
      Given Agent 綁定了多個 MCP
      When 使用者選擇解除該 Agent 的所有綁定
      Then 所有 agent_mcp_bindings 記錄應被移除

  Rule: 可以查詢 Agent 目前綁定的 MCP Server

    Example: 成功 - 查詢綁定列表
      When 使用者查詢 Agent 的 MCP 綁定
      Then 應回傳所有已綁定的 MCP Server 資訊（包含工具列表與狀態）

  Rule: 系統對綁定數量有上限限制

    Example: 失敗 - 超過綁定上限
      Given Agent 已達到 MCP 綁定數量上限
      When 使用者嘗試綁定新的 MCP
      Then 綁定應失敗並提示配額已滿

  Rule: 當多個 MCP Server 有相同名稱的工具時需處理衝突

    Example: 警告 - 工具名稱衝突
      Given 已綁定的 MCP 中有重名的工具
      When 使用者進行綁定
      Then 綁定應成功但回傳衝突警告
      And 系統應明確規範工具調用的優先順序（例如後綁定者優先）
