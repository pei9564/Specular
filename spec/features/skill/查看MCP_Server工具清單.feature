Feature: 查看 MCP Server 工具清單
  # 查看已連接 MCP Server 提供的工具函數

  Rule: 查看 MCP Server 工具清單 的核心邏輯
    # 定義 查看 MCP Server 工具清單 的相關規則與行為

    Example: 列出可用工具
      Given MCP Server 連接正常
      When 用戶請求查看工具列表
      Then 系統應向 MCP Server 查詢可用工具 (ListTools)
      And 回傳工具名稱與描述列表
