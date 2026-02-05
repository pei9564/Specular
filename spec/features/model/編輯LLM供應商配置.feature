Feature: 編輯 LLM 供應商配置
  管理員編輯現有的 LLM 配置

  Background:
    Given 系統中存在以下模型配置:
      | id        | provider_type | display_name | model_name    | is_active | is_default | created_at          |
      | model-001 | openai        | GPT-4o       | gpt-4o        | true      | true       | 2024-01-01 00:00:00 |
      | model-002 | openai        | GPT-3.5      | gpt-3.5-turbo | true      | false      | 2024-01-01 00:00:00 |
      | model-003 | anthropic     | Claude 3     | claude-3-opus | true      | false      | 2024-01-02 00:00:00 |
      | model-004 | azure_openai  | Azure GPT    | gpt-4         | false     | false      | 2024-01-03 00:00:00 |
    And 系統中存在以下用戶:
      | id        | email             | role  |
      | admin-001 | admin@example.com | admin |
      | user-001  | user@example.com  | user  |
    And 使用者 "admin@example.com" 已登入
  # ============================================================
  # Rule: 更新基本資訊
  # ============================================================

  Rule: 管理員可以更新模型配置的基本資訊

    Example: 成功 - 更新 display_name
      When 使用者發送 PATCH 請求至 "/api/admin/models/model-001":
        | display_name | GPT-4o (Production) |
      Then 請求應成功，回傳狀態碼 200
      And model_providers 表中 model-001 應更新:
        | field        | old_value | new_value           |
        | display_name | GPT-4o    | GPT-4o (Production) |
        | updated_at   | (原時間)  | (當前時間)          |
        | updated_by   | null      | admin-001           |

    Example: 成功 - 更新多個欄位
      When 使用者發送 PATCH 請求至 "/api/admin/models/model-001":
        | display_name | Updated GPT-4                 |
        | base_url     | https://new-proxy.example.com |
      Then 請求應成功
      And model_providers 表應同時更新 display_name 和 base_url

    Example: 失敗 - display_name 與其他配置衝突
      When 使用者發送 PATCH 請求至 "/api/admin/models/model-001":
        | display_name | Claude 3 |
      Then 請求應失敗，回傳狀態碼 409
      And 錯誤訊息應為 "A model with display_name 'Claude 3' already exists"

    Example: 失敗 - 模型不存在
      When 使用者發送 PATCH 請求至 "/api/admin/models/non-existent":
        | display_name | New Name |
      Then 請求應失敗，回傳狀態碼 404
      And 錯誤訊息應為 "Model provider not found"
  # ============================================================
  # Rule: 更新 API Key
  # ============================================================

  Rule: 更新 API Key 時應重新加密儲存

    Example: 成功 - 更新 API Key
      Given model-001 的 api_key_encrypted 為 (舊加密值)
      When 使用者發送 PATCH 請求至 "/api/admin/models/model-001":
        | api_key | sk-new-api-key-67890 |
      Then 請求應成功
      And model_providers 表中 model-001 的 api_key_encrypted 應更新為新的加密值
      And 使用 ENCRYPTION_KEY 解密後應得到 "sk-new-api-key-67890"
      And 回傳結果應包含:
        | has_api_key | true |
      And 回傳結果不應包含 api_key

    Example: 成功 - 更新 Key 並測試連線
      When 使用者發送 PATCH 請求至 "/api/admin/models/model-001":
        | api_key         | sk-new-valid-key |
        | test_connection | true             |
      Then 系統應先測試新 Key 的連線
      And 連線成功後才更新配置
      And 回傳應包含 connection_test: "passed"

    Example: 失敗 - 新 Key 連線測試失敗
      When 使用者發送 PATCH 請求至 "/api/admin/models/model-001":
        | api_key         | sk-invalid-key |
        | test_connection | true           |
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "Connection test failed with new API key"
      And model_providers 的 api_key_encrypted 應維持不變
  # ============================================================
  # Rule: 設定預設模型
  # ============================================================

  Rule: 系統只能有一個預設模型

    Example: 成功 - 設定新的預設模型
      Given model-001 的 is_default 為 true
      And model-002 的 is_default 為 false
      When 使用者發送 PATCH 請求至 "/api/admin/models/model-002":
        | is_default | true |
      Then 請求應成功
      And model_providers 表應更新:
        | id        | is_default |
        | model-001 | false      |
        | model-002 | true       |
      And 回傳結果應包含:
        | id         | model-002 |
        | is_default | true      |

    Example: 成功 - 取消預設（系統無預設模型）
      Given model-001 的 is_default 為 true
      When 使用者發送 PATCH 請求至 "/api/admin/models/model-001":
        | is_default | false |
      Then 請求應成功
      And model_providers 表中應無 is_default 為 true 的記錄

    Example: 失敗 - 無法將停用的模型設為預設
      Given model-004 的 is_active 為 false
      When 使用者發送 PATCH 請求至 "/api/admin/models/model-004":
        | is_default | true |
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "Cannot set inactive model as default"
  # ============================================================
  # Rule: 啟用/停用模型
  # ============================================================

  Rule: 管理員可以啟用或停用模型配置

    Example: 成功 - 停用模型
      Given model-002 的 is_active 為 true
      When 使用者發送 PATCH 請求至 "/api/admin/models/model-002":
        | is_active | false |
      Then 請求應成功
      And model_providers 表中 model-002 的 is_active 應為 false
      And 該模型不應出現在一般用戶的可用列表中

    Example: 成功 - 重新啟用模型
      Given model-004 的 is_active 為 false
      When 使用者發送 PATCH 請求至 "/api/admin/models/model-004":
        | is_active | true |
      Then 請求應成功
      And model_providers 表中 model-004 的 is_active 應為 true

    Example: 警告 - 停用有 Agent 使用的模型
      Given 系統中存在 Agent 使用 model-002:
        | agent_id  | model_id  |
        | agent-001 | model-002 |
        | agent-002 | model-002 |
      When 使用者發送 PATCH 請求至 "/api/admin/models/model-002":
        | is_active | false |
      Then 請求應成功
      And 回傳應包含警告:
        | warning         | 2 agents are using this model and may be affected |
        | affected_agents | ["agent-001", "agent-002"]                        |

    Example: 失敗 - 停用預設模型需先取消預設
      Given model-001 的 is_default 為 true
      When 使用者發送 PATCH 請求至 "/api/admin/models/model-001":
        | is_active | false |
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "Cannot deactivate the default model. Please set another model as default first."
  # ============================================================
  # Rule: 更新供應商特定配置
  # ============================================================

  Rule: 可以更新供應商特定的配置欄位

    Example: 成功 - 更新 Azure OpenAI 的 deployment_name
      Given model-004 為 azure_openai 類型
      When 使用者發送 PATCH 請求至 "/api/admin/models/model-004":
        | deployment_name | new-deployment     |
        | api_version     | 2024-05-01-preview |
      Then 請求應成功
      And model_providers 表應更新:
        | field           | new_value          |
        | deployment_name | new-deployment     |
        | api_version     | 2024-05-01-preview |
  # ============================================================
  # Rule: 權限控制
  # ============================================================

  Rule: 只有管理員可以編輯模型配置

    Example: 失敗 - 一般用戶禁止編輯
      Given 使用者 "user@example.com" 已登入（角色為 user）
      When 使用者發送 PATCH 請求至 "/api/admin/models/model-001":
        | display_name | Hacked Name |
      Then 請求應失敗，回傳狀態碼 403
      And model_providers 表中 model-001 應維持不變
  # ============================================================
  # Rule: 變更歷史
  # ============================================================

  Rule: 重要配置變更應記錄歷史

    Example: 記錄配置變更歷史
      When 管理員更新模型配置
      Then model_provider_changes 表應新增一筆記錄:
        | field             | value                                                  |
        | model_provider_id | model-001                                              |
        | changed_by        | admin-001                                              |
        | change_type       | update                                                 |
        | changes           | {"display_name": {"old": "GPT-4o", "new": "New Name"}} |
        | created_at        | (當前時間)                                             |

    Example: API Key 變更不記錄明文
      When 管理員更新 API Key
      Then model_provider_changes 記錄的 changes 應為:
        | api_key | {"changed": true} |
      And 不應包含舊或新的 API Key 值
  # ============================================================
  # Rule: 審計日誌
  # ============================================================

  Rule: 編輯操作應記錄審計日誌

    Example: 記錄編輯操作
      When 管理員編輯模型配置
      Then audit_logs 表應新增一筆記錄:
        | field       | value                 |
        | action      | model_provider.update |
        | actor_id    | admin-001             |
        | target_type | model_provider        |
        | target_id   | model-001             |
