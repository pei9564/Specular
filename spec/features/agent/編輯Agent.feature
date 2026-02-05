Feature: 編輯 Agent
  # 修改現有 Agent 的配置

  Rule: 編輯 Agent 的核心邏輯
    # 定義 編輯 Agent 的相關規則與行為

    Example: 更新 System Prompt
      When 用戶修改 Agent 的 System Prompt
      Then 新的提示詞應立即生效於下一次對話中 (或重建後)

    Example: 變更記憶類型
      When 用戶將 Memory Type 從 "in_memory" 改為 "database"
      Then 系統應更新配置
      And 後續對話應被持久化
