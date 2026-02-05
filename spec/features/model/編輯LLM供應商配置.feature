Feature: 編輯 LLM 模型配置
  # 管理員編輯現有的 LLM 配置

  Rule: 編輯 LLM 模型配置 的核心邏輯
    # 定義 編輯 LLM 模型配置 的相關規則與行為

    Example: 更新模型 API Key
      Given 目前用戶為 "admin"
      When 更新指定模型的 api_key
      Then 新的 Key 應被加密儲存

    Example: 設定系統預設模型
      Given 目前用戶為 "admin"
      When 將某個模型配置設為 is_default = true
      Then 該模型應成為系統預設
      And 其他模型的 is_default 應自動設為 false (若系統邏輯唯一)

    Example: 停用模型配置
      Given 目前用戶為 "admin"
      When 將 is_active 設為 false
      Then 該模型不應出現在一般用戶的可用列表中
