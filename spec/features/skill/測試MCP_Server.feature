Feature: 測試 MCP Server
  # 驗證 MCP Server 連接有效性

  Rule: 測試 MCP Server 的核心邏輯
    # 定義 測試 MCP Server 的相關規則與行為

    Example: 測試連接成功
      When 用戶點擊 "Test Connection"
      Then 系統應嘗試連接 MCP Server
      And 若連接成功，回傳 "Connection Successful"

    Example: 測試連接失敗
      When MCP Server 無回應
      Then 系統應回傳連線錯誤訊息
