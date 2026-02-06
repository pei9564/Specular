Feature: 新增 LLM 供應商配置
  管理員新增 LLM 供應商與具體模型配置

  Background:
    Given 系統支援以下 LLM 供應商類型:
      | provider_type | description      | required_fields                    |
      | openai        | OpenAI           | api_key                            |
      | azure_openai  | Azure OpenAI     | api_key, endpoint, deployment_name |
      | anthropic     | Anthropic Claude | api_key                            |
      | dashscope     | 阿里雲 DashScope | api_key                            |
      | ollama        | Ollama (本地)    | base_url                           |
    And 系統中存在以下用戶:
      | id        | email             | role  |
      | admin-001 | admin@example.com | admin |
      | user-001  | user@example.com  | user  |
  # ============================================================
  # Rule: 新增 OpenAI 配置
  # ============================================================

  Rule: 管理員可以新增 OpenAI 供應商配置

    Example: 成功 - 新增 OpenAI 配置
      Given 使用者 "admin@example.com" 已登入（角色為 admin）
      When 使用者發送 POST 請求至 "/api/v1/llm-models":
        | field         | value               |
        | provider_type | openai              |
        | display_name  | OpenAI GPT-4        |
        | model_name    | gpt-4o              |
        | api_key       | sk-1234567890abcdef |
        | is_active     | true                |
      Then 請求應成功，回傳狀態碼 201
      And model_providers 表應新增一筆記錄:
        | field             | value                     |
        | id                | (自動生成 UUID)           |
        | provider_type     | openai                    |
        | display_name      | OpenAI GPT-4              |
        | model_name        | gpt-4o                    |
        | api_key_encrypted | (Fernet 加密後的值)       |
        | base_url          | https://api.openai.com/v1 |
        | is_active         | true                      |
        | is_default        | false                     |
        | created_at        | (當前時間)                |
        | created_by        | admin-001                 |
      And 資料庫中不應存在明文 api_key "sk-1234567890abcdef"
      And 回傳結果應包含:
        | field        | value         |
        | id           | (新配置 UUID) |
        | display_name | OpenAI GPT-4  |
        | has_api_key  | true          |
      And 回傳結果不應包含 api_key 或 api_key_encrypted

    Example: 成功 - 自訂 base_url
      Given 使用者 "admin@example.com" 已登入
      When 使用者發送 POST 請求至 "/api/v1/llm-models":
        | provider_type | openai                       |
        | model_name    | gpt-4o                       |
        | api_key       | sk-xxx                       |
        | base_url      | https://my-proxy.example.com |
      Then 請求應成功
      And model_providers 記錄的 base_url 應為 "https://my-proxy.example.com"
  # ============================================================
  # Rule: 新增 Azure OpenAI 配置
  # ============================================================

  Rule: 管理員可以新增 Azure OpenAI 供應商配置

    Example: 成功 - 新增 Azure OpenAI 配置
      Given 使用者 "admin@example.com" 已登入
      When 使用者發送 POST 請求至 "/api/v1/llm-models":
        | field           | value                                |
        | provider_type   | azure_openai                         |
        | display_name    | Azure GPT-4                          |
        | model_name      | gpt-4                                |
        | api_key         | azure-api-key-12345                  |
        | endpoint        | https://my-resource.openai.azure.com |
        | deployment_name | my-gpt4-deployment                   |
        | api_version     |                   2024-02-15-preview |
      Then 請求應成功，回傳狀態碼 201
      And model_providers 表應新增一筆記錄:
        | field           | value                                |
        | provider_type   | azure_openai                         |
        | endpoint        | https://my-resource.openai.azure.com |
        | deployment_name | my-gpt4-deployment                   |
        | api_version     |                   2024-02-15-preview |

    Example: 失敗 - Azure OpenAI 缺少必要欄位
      When 使用者發送 POST 請求至 "/api/v1/llm-models":
        | provider_type | azure_openai |
        | model_name    | gpt-4        |
        | api_key       | xxx          |
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "Missing required fields for azure_openai: endpoint, deployment_name"
  # ============================================================
  # Rule: 新增 Anthropic 配置
  # ============================================================

  Rule: 管理員可以新增 Anthropic Claude 配置

    Example: 成功 - 新增 Anthropic 配置
      Given 使用者 "admin@example.com" 已登入
      When 使用者發送 POST 請求至 "/api/v1/llm-models":
        | provider_type | anthropic              |
        | display_name  | Claude 3 Opus          |
        | model_name    | claude-3-opus-20240229 |
        | api_key       | sk-ant-xxxx            |
      Then 請求應成功
      And model_providers 記錄的 base_url 應為 "https://api.anthropic.com"
  # ============================================================
  # Rule: 新增 DashScope 配置
  # ============================================================

  Rule: 管理員可以新增阿里雲 DashScope 配置

    Example: 成功 - 新增 DashScope 配置
      Given 使用者 "admin@example.com" 已登入
      When 使用者發送 POST 請求至 "/api/v1/llm-models":
        | provider_type | dashscope        |
        | display_name  | 通義千問         |
        | model_name    | qwen-max         |
        | api_key       | sk-dashscope-xxx |
      Then 請求應成功
      And model_providers 記錄應正確儲存
  # ============================================================
  # Rule: 新增 Ollama 配置
  # ============================================================

  Rule: 管理員可以新增本地 Ollama 配置

    Example: 成功 - 新增 Ollama 配置（無需 API Key）
      Given 使用者 "admin@example.com" 已登入
      When 使用者發送 POST 請求至 "/api/v1/llm-models":
        | provider_type | ollama                 |
        | display_name  | Local Llama 3          |
        | model_name    | llama3:8b              |
        | base_url      | http://localhost:11434 |
      Then 請求應成功
      And model_providers 記錄的 api_key_encrypted 應為 null
  # ============================================================
  # Rule: API Key 加密
  # ============================================================

  Rule: API Key 必須使用 Fernet 加密儲存

    Example: API Key 加密驗證
      When 使用者新增模型配置，api_key 為 "sk-secret-key-12345"
      Then model_providers 的 api_key_encrypted 應為 Fernet 加密值
      And 使用系統 ENCRYPTION_KEY 解密後應得到 "sk-secret-key-12345"
      And 直接查詢資料庫不應看到明文 "sk-secret-key-12345"
  # ============================================================
  # Rule: 欄位驗證
  # ============================================================

  Rule: 系統應驗證必要欄位和格式

    Example: 失敗 - 缺少 provider_type
      Given 使用者 "admin@example.com" 已登入
      When 使用者發送 POST 請求至 "/api/v1/llm-models":
        | model_name | gpt-4o |
        | api_key    | xxx    |
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "provider_type is required"

    Example: 失敗 - 不支援的 provider_type
      When 使用者發送 POST 請求至 "/api/v1/llm-models":
        | provider_type | unknown_provider |
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "Unsupported provider_type: 'unknown_provider'. Supported: openai, azure_openai, anthropic, dashscope, ollama"

    Example: 失敗 - 缺少 model_name
      When 使用者發送 POST 請求至 "/api/v1/llm-models":
        | provider_type | openai |
        | api_key       | xxx    |
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "model_name is required"

    Example: 失敗 - display_name 重複
      Given model_providers 表已存在 display_name 為 "My GPT" 的記錄
      When 使用者發送 POST 請求至 "/api/v1/llm-models":
        | provider_type | openai |
        | display_name  | My GPT |
        | model_name    | gpt-4o |
        | api_key       | xxx    |
      Then 請求應失敗，回傳狀態碼 409
      And 錯誤訊息應為 "A model with display_name 'My GPT' already exists"
  # ============================================================
  # Rule: 權限控制
  # ============================================================

  Rule: 只有管理員可以新增模型配置

    Example: 失敗 - 一般用戶禁止新增
      Given 使用者 "user@example.com" 已登入（角色為 user）
      When 使用者發送 POST 請求至 "/api/v1/llm-models":
        | provider_type | openai |
        | model_name    | gpt-4o |
        | api_key       | xxx    |
      Then 請求應失敗，回傳狀態碼 403
      And 錯誤訊息應為 "Admin access required"
      And model_providers 表應無新增記錄
  # ============================================================
  # Rule: 新增時自動測試連線
  # ============================================================

  Rule: 新增配置時可選擇自動測試連線

    Example: 成功 - 新增並測試連線通過
      When 使用者發送 POST 請求至 "/api/v1/llm-models":
        | provider_type   | openai       |
        | model_name      | gpt-4o       |
        | api_key         | sk-valid-key |
        | test_connection | true         |
      Then 系統應先測試 API 連線
      And 連線成功後才儲存配置
      And 回傳結果應包含:
        | connection_test | passed |

    Example: 失敗 - 新增但連線測試失敗
      When 使用者發送 POST 請求至 "/api/v1/llm-models":
        | provider_type   | openai         |
        | model_name      | gpt-4o         |
        | api_key         | sk-invalid-key |
        | test_connection | true           |
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "Connection test failed: Invalid API key"
      And model_providers 表應無新增記錄

    Example: 成功 - 跳過連線測試
      When 使用者發送 POST 請求至 "/api/v1/llm-models":
        | provider_type   | openai          |
        | model_name      | gpt-4o          |
        | api_key         | sk-untested-key |
        | test_connection | false           |
      Then 請求應成功
      And 配置應儲存（即使 Key 可能無效）
      And 回傳結果應包含:
        | connection_test | skipped |
  # ============================================================
  # Rule: 審計日誌
  # ============================================================

  Rule: 新增操作應記錄審計日誌

    Example: 記錄新增操作
      When 管理員新增模型配置
      Then audit_logs 表應新增一筆記錄:
        | field       | value                                               |
        | action      | model_provider.create                               |
        | actor_id    | admin-001                                           |
        | target_type | model_provider                                      |
        | target_id   | (新配置 ID)                                         |
        | details     | {"provider_type": "openai", "model_name": "gpt-4o"} |
        | created_at  | (當前時間)                                          |
      And audit_logs 的 details 不應包含 api_key
