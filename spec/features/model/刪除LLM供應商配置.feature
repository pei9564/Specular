Feature: 刪除 LLM 供應商配置
  管理員刪除不再使用的配置

  Background:
    Given 系統中存在以下模型配置:
      | id        | provider_type | display_name | is_active | is_default |
      | model-001 | openai        | GPT-4o       | true      | true       |
      | model-002 | openai        | GPT-3.5      | true      | false      |
      | model-003 | anthropic     | Claude 3     | true      | false      |
      | model-004 | azure_openai  | Azure GPT    | false     | false      |
    And 系統中存在以下 Agent:
      | id        | name    | model_id  |
      | agent-001 | ChatBot | model-002 |
      | agent-002 | TaskBot | model-002 |
      | agent-003 | CodeBot | model-003 |
    And 使用者 "admin@example.com" 已登入（角色為 admin）
  # ============================================================
  # Rule: 刪除未使用的配置
  # ============================================================

  Rule: 管理員可以刪除未被 Agent 使用的模型配置

    Example: 成功 - 刪除未使用的配置
      Given 無 Agent 使用 model-004
      When 使用者發送 DELETE 請求至 "/api/admin/models/model-004"
      Then 請求應成功，回傳狀態碼 200
      And model_providers 表中應不存在 id 為 "model-004" 的記錄
      And 回傳結果應包含:
        | message | Model provider deleted successfully |
        | id      | model-004                           |

    Example: 失敗 - 模型不存在
      When 使用者發送 DELETE 請求至 "/api/admin/models/non-existent"
      Then 請求應失敗，回傳狀態碼 404
      And 錯誤訊息應為 "Model provider not found"
  # ============================================================
  # Rule: 被引用的模型保護
  # ============================================================

  Rule: 被 Agent 使用的模型需特別處理才能刪除

    Example: 失敗 - 無法直接刪除被使用的模型
      Given Agent "agent-001" 和 "agent-002" 使用 model-002
      When 使用者發送 DELETE 請求至 "/api/admin/models/model-002"
      Then 請求應失敗，回傳狀態碼 409
      And 錯誤訊息應為 "Cannot delete model provider: 2 agents are using this model"
      And 回傳應包含使用該模型的 Agent 列表:
        | agents | ["agent-001", "agent-002"] |

    Example: 成功 - 強制刪除並遷移 Agent
      Given Agent "agent-001" 和 "agent-002" 使用 model-002
      When 使用者發送 DELETE 請求至 "/api/admin/models/model-002":
        | force            | true      |
        | migrate_to_model | model-001 |
      Then 請求應成功
      And model_providers 表中應不存在 model-002
      And agents 表中 agent-001 和 agent-002 的 model_id 應更新為 "model-001"
      And 回傳結果應包含:
        | migrated_agents | 2 |

    Example: 成功 - 強制刪除並停用相關 Agent
      Given Agent "agent-001" 和 "agent-002" 使用 model-002
      When 使用者發送 DELETE 請求至 "/api/admin/models/model-002":
        | force          | true |
        | disable_agents | true |
      Then 請求應成功
      And model_providers 表中應不存在 model-002
      And agents 表中 agent-001 和 agent-002 的 status 應更新為 "disabled"
      And agents 表中該 Agent 的 disabled_reason 應為 "Model provider deleted"

    Example: 失敗 - 強制刪除但遷移目標不存在
      When 使用者發送 DELETE 請求至 "/api/admin/models/model-002":
        | force            | true         |
        | migrate_to_model | non-existent |
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "Migration target model 'non-existent' not found"

    Example: 失敗 - 遷移目標為非啟用狀態
      When 使用者發送 DELETE 請求至 "/api/admin/models/model-002":
        | force            | true      |
        | migrate_to_model | model-004 |
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "Migration target model 'model-004' is not active"
  # ============================================================
  # Rule: 預設模型保護
  # ============================================================

  Rule: 預設模型需先取消預設才能刪除

    Example: 失敗 - 無法刪除預設模型
      Given model-001 的 is_default 為 true
      When 使用者發送 DELETE 請求至 "/api/admin/models/model-001"
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "Cannot delete the default model. Please set another model as default first."
  # ============================================================
  # Rule: 軟刪除選項
  # ============================================================

  Rule: 支援軟刪除以便日後恢復

    Example: 成功 - 軟刪除模型配置
      When 使用者發送 DELETE 請求至 "/api/admin/models/model-004":
        | soft_delete | true |
      Then 請求應成功
      And model_providers 表中 model-004 應更新:
        | field      | value      |
        | is_deleted | true       |
        | deleted_at | (當前時間) |
        | deleted_by | admin-001  |
      And 該模型不應出現在任何列表查詢中

    Example: 成功 - 恢復軟刪除的模型
      Given model-004 已被軟刪除（is_deleted = true）
      When 使用者發送 POST 請求至 "/api/admin/models/model-004/restore"
      Then 請求應成功
      And model_providers 表中 model-004 應更新:
        | field      | value |
        | is_deleted | false |
        | deleted_at | null  |
        | deleted_by | null  |

    Example: 查詢已刪除的模型（管理功能）
      Given 有模型被軟刪除
      When 使用者發送 GET 請求至 "/api/admin/models":
        | include_deleted | true |
      Then 回傳結果應包含已軟刪除的模型
      And 已刪除模型應標示 is_deleted: true
  # ============================================================
  # Rule: 權限控制
  # ============================================================

  Rule: 只有管理員可以刪除模型配置

    Example: 失敗 - 一般用戶禁止刪除
      Given 使用者 "user@example.com" 已登入（角色為 user）
      When 使用者發送 DELETE 請求至 "/api/admin/models/model-004"
      Then 請求應失敗，回傳狀態碼 403
      And model_providers 表應維持不變
  # ============================================================
  # Rule: 關聯資料處理
  # ============================================================

  Rule: 刪除模型時應處理相關的統計和日誌資料

    Example: 保留歷史統計資料
      Given model-004 有以下 Token 使用記錄:
        | date       | tokens_used |
        | 2024-01-01 |       10000 |
        | 2024-01-02 |       15000 |
      When 使用者刪除 model-004
      Then token_usage 表中的相關記錄應保留
      And 記錄的 model_name 應保存為 "(已刪除) Azure GPT"
  # ============================================================
  # Rule: 審計日誌
  # ============================================================

  Rule: 刪除操作應記錄審計日誌

    Example: 記錄刪除操作
      When 管理員刪除模型配置 model-004
      Then audit_logs 表應新增一筆記錄:
        | field       | value                                                          |
        | action      | model_provider.delete                                          |
        | actor_id    | admin-001                                                      |
        | target_type | model_provider                                                 |
        | target_id   | model-004                                                      |
        | details     | {"display_name": "Azure GPT", "provider_type": "azure_openai"} |
        | created_at  | (當前時間)                                                     |

    Example: 記錄強制刪除並遷移
      When 管理員強制刪除並遷移 Agent
      Then audit_logs 記錄的 details 應包含:
        | force            | true                       |
        | migrated_agents  | ["agent-001", "agent-002"] |
        | migrate_to_model | model-001                  |
