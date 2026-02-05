Feature: 查詢已啟用的模型供應商清單
  用戶查詢可供選擇的 LLM 模型清單

  Background:
    Given 系統中存在以下模型配置:
      | id        | provider_type | display_name  | model_name    | is_active | is_default | base_url                       |
      | model-001 | openai        | GPT-4o        | gpt-4o        | true      | true       | https://api.openai.com/v1      |
      | model-002 | openai        | GPT-3.5 Turbo | gpt-3.5-turbo | true      | false      | https://api.openai.com/v1      |
      | model-003 | anthropic     | Claude 3 Opus | claude-3-opus | true      | false      | https://api.anthropic.com      |
      | model-004 | azure_openai  | Azure GPT-4   | gpt-4         | false     | false      | https://xxx.openai.azure.com   |
      | model-005 | dashscope     | 通義千問      | qwen-max      | true      | false      | https://dashscope.aliyuncs.com |
      | model-006 | ollama        | Local Llama   | llama3:8b     | true      | false      | http://localhost:11434         |
    And 系統中存在以下用戶:
      | id        | email             | role  |
      | admin-001 | admin@example.com | admin |
      | user-001  | user@example.com  | user  |
  # ============================================================
  # Rule: 一般用戶查詢
  # ============================================================

  Rule: 一般用戶只能查詢已啟用的模型

    Example: 成功 - 一般用戶查詢可用模型列表
      Given 使用者 "user@example.com" 已登入（角色為 user）
      When 使用者發送 GET 請求至 "/api/models"
      Then 請求應成功，回傳狀態碼 200
      And 回傳結果應只包含 is_active 為 true 的模型:
        | id        | display_name  | provider_type | is_default |
        | model-001 | GPT-4o        | openai        | true       |
        | model-002 | GPT-3.5 Turbo | openai        | false      |
        | model-003 | Claude 3 Opus | anthropic     | false      |
        | model-005 | 通義千問      | dashscope     | false      |
        | model-006 | Local Llama   | ollama        | false      |
      And 回傳結果不應包含 model-004（is_active = false）

    Example: 回傳欄位不包含敏感資訊
      Given 使用者 "user@example.com" 已登入
      When 使用者發送 GET 請求至 "/api/models"
      Then 每筆模型應包含以下欄位:
        | field         | type    | description    |
        | id            | string  | 模型配置 UUID  |
        | display_name  | string  | 顯示名稱       |
        | model_name    | string  | 模型 ID        |
        | provider_type | string  | 供應商類型     |
        | is_default    | boolean | 是否為預設模型 |
      And 每筆模型不應包含以下欄位:
        | field             |
        | api_key           |
        | api_key_encrypted |
        | base_url          |
        | endpoint          |
        | deployment_name   |
  # ============================================================
  # Rule: 管理員查詢
  # ============================================================

  Rule: 管理員可以查詢所有模型配置

    Example: 成功 - 管理員查詢所有模型
      Given 使用者 "admin@example.com" 已登入（角色為 admin）
      When 使用者發送 GET 請求至 "/api/admin/models"
      Then 請求應成功
      And 回傳結果應包含所有模型（含 is_active = false）:
        | id        | display_name  | is_active |
        | model-001 | GPT-4o        | true      |
        | model-002 | GPT-3.5 Turbo | true      |
        | model-003 | Claude 3 Opus | true      |
        | model-004 | Azure GPT-4   | false     |
        | model-005 | 通義千問      | true      |
        | model-006 | Local Llama   | true      |

    Example: 管理員查詢包含額外管理資訊
      Given 使用者 "admin@example.com" 已登入
      When 使用者發送 GET 請求至 "/api/admin/models"
      Then 每筆模型應包含管理欄位:
        | field            | type     | description        |
        | id               | string   | 模型配置 UUID      |
        | display_name     | string   | 顯示名稱           |
        | model_name       | string   | 模型 ID            |
        | provider_type    | string   | 供應商類型         |
        | base_url         | string   | API 端點 URL       |
        | is_active        | boolean  | 是否啟用           |
        | is_default       | boolean  | 是否為預設         |
        | has_api_key      | boolean  | 是否已設定 API Key |
        | created_at       | datetime | 建立時間           |
        | created_by       | string   | 建立者 ID          |
        | updated_at       | datetime | 最後更新時間       |
        | last_tested_at   | datetime | 最後連線測試時間   |
        | last_test_status | string   | 最後測試結果       |
      And 不應包含 api_key 或 api_key_encrypted

    Example: 管理員查詢包含使用統計
      When 使用者發送 GET 請求至 "/api/admin/models":
        | include_stats | true |
      Then 每筆模型應包含使用統計:
        | field         | description           |
        | agent_count   | 使用此模型的 Agent 數 |
        | total_tokens  | 總 Token 使用量       |
        | request_count | 總請求次數            |
  # ============================================================
  # Rule: 篩選功能
  # ============================================================

  Rule: 支援依條件篩選模型

    Example: 依供應商類型篩選
      Given 使用者 "user@example.com" 已登入
      When 使用者發送 GET 請求至 "/api/models":
        | provider_type | openai |
      Then 回傳結果應只包含 provider_type 為 "openai" 的模型:
        | display_name  |
        | GPT-4o        |
        | GPT-3.5 Turbo |

    Example: 依多個供應商類型篩選
      When 使用者發送 GET 請求至 "/api/models":
        | provider_type | openai,anthropic |
      Then 回傳結果應包含 openai 和 anthropic 的模型

    Example: 搜尋模型名稱
      When 使用者發送 GET 請求至 "/api/models":
        | search | GPT |
      Then 回傳結果應包含 display_name 或 model_name 含有 "GPT" 的模型

    Example: 管理員篩選啟用狀態
      Given 使用者 "admin@example.com" 已登入
      When 使用者發送 GET 請求至 "/api/admin/models":
        | is_active | false |
      Then 回傳結果應只包含:
        | id        | is_active |
        | model-004 | false     |
  # ============================================================
  # Rule: 排序功能
  # ============================================================

  Rule: 支援依不同欄位排序

    Example: 預設排序（預設模型優先）
      When 使用者發送 GET 請求至 "/api/models"
      Then 回傳結果的第一筆應為 is_default = true 的模型
      And 其餘按 display_name 字母順序排列

    Example: 依 display_name 排序
      When 使用者發送 GET 請求至 "/api/models":
        | sort_by | display_name |
        | order   | asc          |
      Then 回傳結果應依 display_name 升序排列

    Example: 管理員依建立時間排序
      Given 使用者 "admin@example.com" 已登入
      When 使用者發送 GET 請求至 "/api/admin/models":
        | sort_by | created_at |
        | order   | desc       |
      Then 回傳結果應依建立時間降序排列
  # ============================================================
  # Rule: 單一模型查詢
  # ============================================================

  Rule: 可以查詢單一模型的詳細資訊

    Example: 成功 - 一般用戶查詢單一模型
      Given 使用者 "user@example.com" 已登入
      When 使用者發送 GET 請求至 "/api/models/model-001"
      Then 請求應成功
      And 回傳結果應包含模型基本資訊
      And 不應包含敏感欄位

    Example: 失敗 - 一般用戶查詢未啟用的模型
      Given 使用者 "user@example.com" 已登入
      When 使用者發送 GET 請求至 "/api/models/model-004"
      Then 請求應失敗，回傳狀態碼 404
      And 錯誤訊息應為 "Model not found"

    Example: 成功 - 管理員查詢任何模型
      Given 使用者 "admin@example.com" 已登入
      When 使用者發送 GET 請求至 "/api/admin/models/model-004"
      Then 請求應成功
      And 回傳結果應包含完整管理資訊
  # ============================================================
  # Rule: 供應商類型列表
  # ============================================================

  Rule: 提供支援的供應商類型列表

    Example: 查詢支援的供應商類型
      When 使用者發送 GET 請求至 "/api/models/providers"
      Then 請求應成功
      And 回傳結果應包含:
        | provider_type | display_name   | required_fields                    |
        | openai        | OpenAI         | api_key                            |
        | azure_openai  | Azure OpenAI   | api_key, endpoint, deployment_name |
        | anthropic     | Anthropic      | api_key                            |
        | dashscope     | DashScope      | api_key                            |
        | ollama        | Ollama (Local) | base_url                           |
  # ============================================================
  # Rule: 預設模型
  # ============================================================

  Rule: 系統提供預設模型資訊

    Example: 查詢系統預設模型
      When 使用者發送 GET 請求至 "/api/models/default"
      Then 請求應成功
      And 回傳結果應為 is_default = true 的模型:
        | id           | model-001 |
        | display_name | GPT-4o    |

    Example: 無預設模型時的處理
      Given 系統中無 is_default = true 的模型
      When 使用者發送 GET 請求至 "/api/models/default"
      Then 請求應成功
      And 回傳結果應為 null 或第一個啟用的模型
