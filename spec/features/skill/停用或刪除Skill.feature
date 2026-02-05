Feature: 停用或刪除 Skill
  # 管理與維護已上傳的 Skill

  Rule: 停用或刪除 Skill 的核心邏輯
    # 定義 停用或刪除 Skill 的相關規則與行為

    Example: 停用 Skill
      Given 目前用戶為 "admin"
      When 請求停用某個 Skill
      Then 該 Skill 狀態應變為 "disabled"
      And 無法被新的 Agent 選用

    Example: 刪除 Skill
      Given 目前用戶為 "admin"
      When 請求刪除某個 Skill
      And 該 Skill 未被任何 Agent 使用
      Then 系統應將其標記為刪除 (Soft Delete)

    Example: 保護被使用的 Skill
      Given 某個 Skill 正被 Agent 使用中
      When 請求刪除該 Skill
      Then 系統應拒絕請求並提示 "Skill is in use"
