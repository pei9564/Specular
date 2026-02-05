Feature: 創建與管理對話會話
  # 管理與 Agent 的對話 Context

  Rule: 創建與管理對話會話 的核心邏輯
    # 定義 創建與管理對話會話 的相關規則與行為

    Example: 創建新會話
      When 用戶發起新的對話
      Then 系統應建立一個 Conversation 記錄 (Session)
      And 該會話應關聯至指定的 Agent

    Example: 查詢會話歷史
      When 用戶查詢對話歷史
      Then 系統應回傳該用戶的所有 Conversation 列表
