Feature: 新增 LLM 模型配置
  # 管理員新增 LLM 供應商與具體模型配置

  Rule: 新增 LLM 模型配置 的核心邏輯
    # 定義 新增 LLM 模型配置 的相關規則與行為

    Example: 新增 OpenAI 模型配置
      Given 目前用戶為 "admin"
      When 提交新增模型請求
      Then 系統應儲存該配置
      And api_key 應被 Fernet 加密儲存

    Example: 新增 Azure OpenAI 模型配置
      Given 目前用戶為 "admin"
      When 提交新增模型請求
      Then 系統應儲存該配置

    Example: 一般用戶禁止新增
      Given 目前用戶為 "user"
      When 提交新增模型請求
      Then 系統應拒絕請求 (403 Forbidden)
