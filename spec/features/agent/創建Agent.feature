Feature: 創建 Agent
  # 使用低程式碼界面配置並創建 Agent

  Rule: 創建 Agent 的核心邏輯
    # 定義 創建 Agent 的相關規則與行為

    Example: 創建基本 Agent
      When 用戶提交 Agent 創建請求
      Then 系統應成功創建 Agent

    Example: 配置模型參數
      When 創建 Agent 時設定 model_config
      Then 系統應驗證模型 ID 是否存在
      And 儲存模型配置

    Example: 配置記憶模組 (Memory)
      When 創建 Agent 時設定 memory_config type 為 "database"
      Then 系統應啟用資料庫持久化記憶
