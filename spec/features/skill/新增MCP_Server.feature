Feature: 新增 MCP Server
  # 管理外部 MCP Server 連接

  Rule: 新增 MCP Server 的核心邏輯
    # 定義 新增 MCP Server 的相關規則與行為

    Example: 新增 SSE 類型 MCP Server
      When 用戶新增 MCP Server
      Then 系統應儲存該 MCP 連接配置

    Example: 配置預設參數
      When 用戶新增 MCP Server 且帶有 preset_kwargs
      Then 系統應儲存這些參數供後續調用使用
