Feature: 刪除對話會話
  移除不再需要的對話

  Background:
    Given 系統中存在以下會話:
      | id       | user_id  | agent_id  | title    | status   | message_count |
      | conv-001 | user-001 | agent-001 | Chat 1   | active   |            10 |
      | conv-002 | user-001 | agent-001 | Chat 2   | active   |             5 |
      | conv-003 | user-001 | agent-001 | Archived | archived |            20 |
      | conv-004 | user-002 | agent-001 | Other    | active   |             8 |
    And 會話 "conv-001" 有以下訊息:
      | id   | role      | content |
      | m-01 | user      | Hello   |
      | m-02 | assistant | Hi!     |
    And 訊息 "m-02" 有以下工具調用記錄:
      | id    | tool_name | status  |
      | tc-01 | calculate | success |
    And 使用者 "user-001" 已登入
  # ============================================================
  # Rule: 軟刪除會話
  # ============================================================

  Rule: 刪除會話預設使用軟刪除（標記為 deleted）

    Example: 成功 - 軟刪除會話
      # API: DELETE /api/v1/agents/{id}/conversations/{conv_id}
      When 使用者發送 DELETE 請求至 "/api/v1/agents/agent-001/conversations/conv-001"
      Then 請求應成功，回傳狀態碼 200
      And conversations 表中 conv-001 應更新:
        | field      | old_value | new_value  |
        | status     | active    | deleted    |
        | deleted_at | null      | (當前時間) |
      And 回傳結果應包含:
        | field   | value                             |
        | message | Conversation deleted successfully |
        | id      | conv-001                          |

    Example: 軟刪除後會話不出現在列表
      Given 會話 "conv-001" 已被軟刪除（status = deleted）
      # API: GET /api/v1/agents/{id}/conversations
      When 使用者發送 GET 請求至 "/api/v1/agents/agent-001/conversations"
      Then 回傳結果不應包含 "conv-001"

    Example: 軟刪除後訊息仍保留在資料庫
      Given 使用者刪除會話 "conv-001"
      Then messages 表中 conversation_id 為 "conv-001" 的記錄應仍存在
      And 記錄數量應為 2
  # ============================================================
  # Rule: 硬刪除會話
  # ============================================================

  Rule: 可選擇永久刪除會話及其所有資料

    Example: 成功 - 硬刪除會話
      # API: DELETE /api/v1/agents/{id}/conversations/{conv_id}
      When 使用者發送 DELETE 請求至 "/api/v1/agents/agent-001/conversations/conv-001":
        | permanent | true |
      Then 請求應成功，回傳狀態碼 200
      And conversations 表中應不存在 id 為 "conv-001" 的記錄
      And messages 表中應不存在 conversation_id 為 "conv-001" 的記錄
      And tool_calls 表中應不存在 message_id 為 "m-02" 的記錄

    Example: 硬刪除需要二次確認
      # API: DELETE /api/v1/agents/{id}/conversations/{conv_id}
      When 使用者發送 DELETE 請求至 "/api/v1/agents/agent-001/conversations/conv-001":
        | permanent | true  |
        | confirm   | false |
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "Permanent deletion requires confirmation. Set confirm=true to proceed."

    Example: 成功 - 硬刪除並確認
      # API: DELETE /api/v1/agents/{id}/conversations/{conv_id}
      When 使用者發送 DELETE 請求至 "/api/v1/agents/agent-001/conversations/conv-001":
        | permanent | true |
        | confirm   | true |
      Then 請求應成功
      And 所有相關資料應被永久刪除
  # ============================================================
  # Rule: 批次刪除
  # ============================================================

  Rule: 支援批次刪除多個會話

    Example: 成功 - 批次軟刪除
      # API: POST /api/v1/agents/{id}/conversations/batch-delete
      When 使用者發送 POST 請求至 "/api/v1/agents/agent-001/conversations/batch-delete":
        | ids | ["conv-001", "conv-002"] |
      Then 請求應成功，回傳狀態碼 200
      And conversations 表中 conv-001 和 conv-002 的 status 應為 "deleted"
      And 回傳結果應包含:
        | field         | value |
        | deleted_count |     2 |

    Example: 批次刪除部分失敗
      # API: POST /api/v1/agents/{id}/conversations/batch-delete
      When 使用者發送 POST 請求至 "/api/v1/agents/agent-001/conversations/batch-delete":
        | ids | ["conv-001", "conv-004", "non-existent"] |
      Then 請求應成功（部分成功），回傳狀態碼 207
      And 回傳結果應包含:
        | field         | value |
        | deleted_count |     1 |
        | failed_count  |     2 |
      And failed 陣列應包含:
        | id           | reason                 |
        | conv-004     | Permission denied      |
        | non-existent | Conversation not found |
  # ============================================================
  # Rule: 權限控制
  # ============================================================

  Rule: 用戶只能刪除自己的會話

    Example: 失敗 - 刪除他人會話
      # API: DELETE /api/v1/agents/{id}/conversations/{conv_id}
      When 使用者 "user-001" 發送 DELETE 請求至 "/api/v1/agents/agent-001/conversations/conv-004"
      Then 請求應失敗，回傳狀態碼 403
      And 錯誤訊息應為 "You do not have permission to delete this conversation"
      And conversations 表中 conv-004 應維持不變

    Example: 失敗 - 會話不存在
      # API: DELETE /api/v1/agents/{id}/conversations/{conv_id}
      When 使用者發送 DELETE 請求至 "/api/v1/agents/agent-001/conversations/non-existent"
      Then 請求應失敗，回傳狀態碼 404
      And 錯誤訊息應為 "Conversation not found"

    Example: 成功 - 管理員可刪除任何會話
      Given 使用者 "admin@example.com" 已登入（角色為 admin）
      # API: DELETE /api/v1/agents/{id}/conversations/{conv_id}
      When 使用者發送 DELETE 請求至 "/api/v1/agents/agent-001/conversations/conv-004"
      Then 請求應成功
      And conversations 表中 conv-004 的 status 應為 "deleted"
  # ============================================================
  # Rule: 刪除已封存會話
  # ============================================================

  Rule: 已封存的會話也可以被刪除

    Example: 成功 - 刪除已封存會話
      # API: DELETE /api/v1/agents/{id}/conversations/{conv_id}
      When 使用者發送 DELETE 請求至 "/api/v1/agents/agent-001/conversations/conv-003"
      Then 請求應成功
      And conversations 表中 conv-003 的 status 應為 "deleted"
  # ============================================================
  # Rule: 恢復已刪除會話
  # ============================================================

  Rule: 軟刪除的會話可以被恢復

    Example: 成功 - 恢復已刪除會話
      Given 會話 "conv-001" 已被軟刪除（status = deleted）
      # API: POST /api/v1/agents/{id}/conversations/{conv_id}/restore
      When 使用者發送 POST 請求至 "/api/v1/agents/agent-001/conversations/conv-001/restore"
      Then 請求應成功，回傳狀態碼 200
      And conversations 表中 conv-001 應更新:
        | field      | old_value | new_value |
        | status     | deleted   | active    |
        | deleted_at | (時間)    | null      |
      And 會話應重新出現在列表中

    Example: 失敗 - 恢復已永久刪除的會話
      Given 會話 "conv-001" 已被永久刪除
      # API: POST /api/v1/agents/{id}/conversations/{conv_id}/restore
      When 使用者發送 POST 請求至 "/api/v1/agents/agent-001/conversations/conv-001/restore"
      Then 請求應失敗，回傳狀態碼 404
      And 錯誤訊息應為 "Conversation not found"

    Example: 查詢已刪除會話（用於恢復）
      Given 會話 "conv-001" 已被軟刪除
      # API: GET /api/v1/agents/{id}/conversations
      When 使用者發送 GET 請求至 "/api/v1/agents/agent-001/conversations":
        | include_deleted | true |
      Then 回傳結果應包含 "conv-001"
      And conv-001 的 status 應為 "deleted"
  # ============================================================
  # Rule: 自動清理
  # ============================================================

  Rule: 系統應定期清理長期未使用的已刪除會話

    Example: 自動永久刪除超過保留期限的會話
      Given 會話 "conv-001" 在 31 天前被軟刪除
      And 系統設定 deleted_conversation_retention_days 為 30
      When 系統執行定期清理任務
      Then conversations 表中應不存在 "conv-001"
      And 相關的 messages 和 tool_calls 也應被刪除
  # ============================================================
  # Rule: 審計日誌
  # ============================================================

  Rule: 刪除操作應記錄審計日誌

    Example: 記錄軟刪除操作
      When 使用者刪除會話 "conv-001"
      Then audit_logs 表應新增一筆記錄:
        | field       | value                                 |
        | action      | conversation.delete                   |
        | actor_id    | user-001                              |
        | target_type | conversation                          |
        | target_id   | conv-001                              |
        | details     | {"type": "soft", "message_count": 10} |
        | created_at  | (當前時間)                            |

    Example: 記錄硬刪除操作
      When 使用者永久刪除會話 "conv-001"
      Then audit_logs 表應新增一筆記錄:
        | field   | value                                                        |
        | action  | conversation.delete.permanent                                |
        | details | {"type": "hard", "message_count": 10, "tool_calls_count": 1} |

    Example: 記錄恢復操作
      When 使用者恢復已刪除會話 "conv-001"
      Then audit_logs 表應新增一筆記錄:
        | field  | value                |
        | action | conversation.restore |
