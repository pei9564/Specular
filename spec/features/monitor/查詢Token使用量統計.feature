Feature: 查詢 Token 使用量統計
  # 追蹤 Token 消耗量

  Rule: 查詢 Token 使用量統計 的核心邏輯
    # 定義 查詢 Token 使用量統計 的相關規則與行為

    Example: 查看 Token 統計
      When 管理員查詢 Token 使用量
      Then 系統應顯示各 Agent 或各模型供應商的 Token 消耗總量
