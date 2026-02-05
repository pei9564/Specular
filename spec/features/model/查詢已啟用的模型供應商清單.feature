Feature: 查詢已啟用的模型供應商清單
  # 用戶查詢可供選擇的 LLM 模型清單

  Rule: 查詢已啟用的模型供應商清單 的核心邏輯
    # 定義 查詢已啟用的模型供應商清單 的相關規則與行為

    Example: 一般用戶查詢可用列表
      Given 目前用戶為 "user"
      When 查詢可用模型列表
      Then 系統應回傳所有 is_active = true 的配置
      And 列表內容不應包含 api_key
      And 列表應包含 display_name 與 model_name

    Example: 管理員查詢所有列表
      Given 目前用戶為 "admin"
      When 查詢模型列表
      Then 系統應回傳所有配置 (包含 is_active = false)
      And 系統應回傳 has_api_key 狀態而非真實 Key
