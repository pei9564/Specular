Feature: 刪除 LLM 模型配置
  # 管理員刪除不再使用的配置

  Rule: 刪除 LLM 模型配置 的核心邏輯
    # 定義 刪除 LLM 模型配置 的相關規則與行為

    Example: 刪除模型配置
      Given 目前用戶為 "admin"
      When 請求刪除指定的模型配置 ID
      Then 系統應從資料庫移除該記錄

    Example: 被引用的模型不可刪除 (可選安全措施)
      Given 某個模型配置正被 Agent 使用
      When 請求刪除該配置
      Then 系統應發出警告或阻止刪除
