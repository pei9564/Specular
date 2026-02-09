Feature: 新增 LLM 供應商配置
  管理員新增 LLM 供應商與具體模型配置

  Background:
    Given 系統支援以下 LLM 供應商類型:
      | provider_type | description      |
      | openai        | OpenAI           |
      | azure_openai  | Azure OpenAI     |
      | anthropic     | Anthropic Claude |
      | dashscope     | 阿里雲 DashScope |
      | ollama        | Ollama (本地)    |
    And 使用者 "admin@example.com" 已登入（角色為 admin）

  Rule: 管理員可以新增 OpenAI 供應商配置

    Example: 成功 - 新增 OpenAI 配置
      When 管理員新增 LLM 配置:
        | field         | value        |
        | provider_type | openai       |
        | display_name  | OpenAI GPT-4 |
        | model_name    | gpt-4o       |
        | api_key       | (Valid Key)  |
      Then 配置應成功儲存
      And model_providers 表應新增一筆記錄:
        | field         | value                     |
        | provider_type | openai                    |
        | display_name  | OpenAI GPT-4              |
        | model_name    | gpt-4o                    |
        | base_url      | https://api.openai.com/v1 |
      And API Key 應加密儲存，不以明文顯示

    Example: 成功 - 自訂 base_url
      When 管理員新增 OpenAI 配置並指定 base_url 為 "https://my-proxy.example.com"
      Then model_providers 記錄的 base_url 應為 "https://my-proxy.example.com"

  Rule: 管理員可以新增 Azure OpenAI 供應商配置

    Example: 成功 - 新增 Azure OpenAI 配置
      When 管理員新增 Azure OpenAI 配置:
        | field           | value                                |
        | display_name    | Azure GPT-4                          |
        | endpoint        | https://my-resource.openai.azure.com |
        | deployment_name | my-gpt4-deployment                   |
      Then 配置應成功儲存
      And model_providers 表應新增對應記錄

    Example: 失敗 - Azure OpenAI 缺少必要欄位
      When 管理員新增 Azure OpenAI 配置但缺少 endpoint
      Then 新增應失敗
      And 錯誤訊息應提示缺少必要欄位

  Rule: 管理員可以新增 Anthropic Claude 配置

    Example: 成功 - 新增 Anthropic 配置
      When 管理員新增 Anthropic 配置:
        | display_name | Claude 3 Opus |
        | model_name   | claude-3-opus |
      Then 配置應成功儲存
      And base_url 應預設為 "https://api.anthropic.com"

  Rule: 管理員可以新增阿里雲 DashScope 配置

    Example: 成功 - 新增 DashScope 配置
      When 管理員新增 DashScope 配置:
        | display_name | 通義千問 |
        | model_name   | qwen-max |
      Then 配置應成功儲存

  Rule: 管理員可以新增本地 Ollama 配置

    Example: 成功 - 新增 Ollama 配置（無需 API Key）
      When 管理員新增 Ollama 配置:
        | display_name | Local Llama 3          |
        | model_name   | llama3:8b              |
        | base_url     | http://localhost:11434 |
      Then 配置應成功儲存
      And api_key_encrypted 欄位應為空

  Rule: API Key 必須使用 Fernet 加密儲存

    Example: API Key 加密驗證
      When 新增配置並提供 API Key "sk-secret-key-12345"
      Then 資料庫中該欄位應為加密後的字串
      And 解密後應與原 Key 一致
      And 資料庫不應存在明文 Key

  Rule: 系統應驗證必要欄位和格式

    Example: 失敗 - 缺少 provider_type
      When 新增配置時未指定 provider_type
      Then 新增應失敗

    Example: 失敗 - 不支援的 provider_type
      When 新增配置時指定無效的 provider_type
      Then 新增應失敗

    Example: 失敗 - display_name 重複
      Given 已存在 display_name 為 "My GPT" 的配置
      When 嘗試新增 display_name 為 "My GPT" 的新配置
      Then 新增應失敗並提示名稱重複

  Rule: 只有管理員可以新增模型配置

    Example: 失敗 - 一般用戶禁止新增
      Given 使用者 "user@example.com" 已登入（角色為 user）
      When 該使用者嘗試新增 LLM 配置
      Then 新增應失敗
      And 錯誤訊息應提示權限不足

  Rule: 新增配置時可選擇自動測試連線

    Example: 成功 - 新增並測試連線通過
      When 新增配置並勾選「測試連線」
      Then 系統應先進行連線測試
      And 連線成功後才儲存配置

    Example: 失敗 - 新增但連線測試失敗
      When 新增配置並勾選「測試連線」
      But 提供的 API Key 無效導致連線失敗
      Then 配置不應儲存
      And 系統應回傳連線失敗錯誤

  Rule: 新增操作應記錄審計日誌

    Example: 記錄新增操作
      When 管理員成功新增模型配置
      Then audit_logs 表應新增一筆記錄:
        | field       | value                 |
        | action      | model_provider.create |
        | target_type | model_provider        |
      And 日誌內容不應包含 API Key
