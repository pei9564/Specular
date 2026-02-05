Feature: 查詢可用的 Skills 列表
  # 列出系統中已註冊且有效的 Skill

  Rule: 查詢可用的 Skills 列表 的核心邏輯
    # 定義 查詢可用的 Skills 列表 的相關規則與行為

    Example: 查詢 Skill 列表
      When 用戶請求 Skill 列表
      Then 系統應回傳所有已註冊的 Skill
      And 包含名稱、描述與相容性標籤 (用作 Agent 綁定選擇)
