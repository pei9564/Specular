Feature: 綁定 Agent 與 MCP
  # 連接 MCP Server 賦予 Agent 外部工具能力

  Rule: 綁定 Agent 與 MCP 的核心邏輯
    # 定義 綁定 Agent 與 MCP 的相關規則與行為

    Example: 綁定 MCP 連接
      Given 系統中已配置 MCP Server "WeatherService"
      When 用戶在 Agent 配置中勾選該 MCP Server
      Then 系統應建立綁定關係
      And Agent 執行時應能調用該 Server 提供的工具
