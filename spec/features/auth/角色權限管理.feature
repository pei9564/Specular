Feature: 角色權限管理
  # 定義不同角色的權限邊界

  Rule: 角色權限管理 的核心邏輯
    # 定義 角色權限管理 的相關規則與行為

    Example: User 角色權限檢查
      Given 目前登入用戶的角色為 "user"
      When 該用戶嘗試使用 Agent 功能
      Then 系統應允許請求
      When 該用戶嘗試管理 LLM 模型
      Then 系統應拒絕請求 (403 Forbidden)
      When 該用戶嘗試查詢全系統用戶列表
      Then 系統應拒絕請求 (403 Forbidden)

    Example: Admin 角色權限檢查
      Given 目前登入用戶的角色為 "admin"
      When 該用戶嘗試使用 Agent 功能
      Then 系統應允許請求
      When 該用戶嘗試管理 LLM 模型
      Then 系統應允許請求
      When 該用戶嘗試查詢全系統用戶列表
      Then 系統應允許請求
