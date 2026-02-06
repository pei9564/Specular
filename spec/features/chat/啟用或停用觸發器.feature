Feature: 啟用或停用觸發器
  控制 Agent 觸發器的活躍狀態

  Background:
    Given 系統中存在以下 Agent:
      | id        | name     | owner_id | mode     |
      | agent-001 | TaskBot  | user-001 | triggers |
      | agent-002 | OtherBot | user-002 | triggers |
    And Agent "agent-001" 有以下觸發器:
      | id      | type     | name           | status | next_run_at         |
      | trg-001 | schedule | Daily Report   | active | 2024-01-16 09:00:00 |
      | trg-002 | webhook  | GitHub Hook    | active | null                |
      | trg-003 | schedule | Weekly Summary | paused | null                |
    And 使用者 "user-001" 已登入
  # ============================================================
  # Rule: 停用觸發器
  # ============================================================

  Rule: 用戶可以暫停觸發器的執行

    Example: 成功 - 停用排程觸發器
      Given 觸發器 "trg-001" 的 status 為 "active"
      # API: PATCH /api/v1/agents/{id}/triggers/{trigger_id}
      When 使用者發送 PATCH 請求至 "/api/v1/agents/agent-001/triggers/trg-001":
        | status | paused |
      Then 請求應成功，回傳狀態碼 200
      And triggers 表中 trg-001 應更新:
        | field       | old_value           | new_value  |
        | status      | active              | paused     |
        | paused_at   | null                | (當前時間) |
        | paused_by   | null                | user-001   |
        | next_run_at | 2024-01-16 09:00:00 | null       |
        | updated_at  | (原時間)            | (當前時間) |
      And 回傳結果應包含:
        | field   | value                       |
        | id      | trg-001                     |
        | status  | paused                      |
        | message | Trigger paused successfully |

    Example: 停用後排程不應執行
      Given 觸發器 "trg-001" 的 status 為 "paused"
      And 原定執行時間為 "2024-01-16 09:00:00"
      When 系統時間到達 "2024-01-16 09:00:00"
      Then 觸發器不應執行
      And trigger_executions 表不應有新增記錄

    Example: 成功 - 停用 Webhook 觸發器
      Given 觸發器 "trg-002" 為 Webhook 類型，status 為 "active"
      # API: PATCH /api/v1/agents/{id}/triggers/{trigger_id}
      When 使用者發送 PATCH 請求至 "/api/v1/agents/agent-001/triggers/trg-002":
        | status | paused |
      Then 請求應成功
      And triggers 表中 trg-002 的 status 應為 "paused"

    Example: Webhook 停用後拒絕外部請求
      Given 觸發器 "trg-002" 的 status 為 "paused"
      When 外部系統呼叫該觸發器的 webhook URL
      Then 請求應失敗，回傳狀態碼 503
      And 錯誤訊息應為 "Trigger is currently paused"
  # ============================================================
  # Rule: 啟用觸發器
  # ============================================================

  Rule: 用戶可以重新啟用已暫停的觸發器

    Example: 成功 - 重新啟用排程觸發器
      Given 觸發器 "trg-003" 的 status 為 "paused"
      And 觸發器 "trg-003" 的 cron 為 "0 0 * * 0"（每週日）
      # API: PATCH /api/v1/agents/{id}/triggers/{trigger_id}
      When 使用者發送 PATCH 請求至 "/api/v1/agents/agent-001/triggers/trg-003":
        | status | active |
      Then 請求應成功，回傳狀態碼 200
      And triggers 表中 trg-003 應更新:
        | field       | old_value | new_value             |
        | status      | paused    | active                |
        | paused_at   | (時間)    | null                  |
        | paused_by   | user-001  | null                  |
        | next_run_at | null      | (下個週日 00:00 時間) |
      And 回傳結果應包含:
        | field       | value                  |
        | status      | active                 |
        | next_run_at | (計算後的下次執行時間) |

    Example: 成功 - 重新啟用 Webhook 觸發器
      Given 觸發器 "trg-002" 的 status 為 "paused"
      # API: PATCH /api/v1/agents/{id}/triggers/{trigger_id}
      When 使用者發送 PATCH 請求至 "/api/v1/agents/agent-001/triggers/trg-002":
        | status | active |
      Then 請求應成功
      And 觸發器應能正常接收 webhook 請求

    Example: 啟用後立即執行一次（可選）
      Given 觸發器 "trg-003" 的 status 為 "paused"
      # API: PATCH /api/v1/agents/{id}/triggers/{trigger_id}
      When 使用者發送 PATCH 請求至 "/api/v1/agents/agent-001/triggers/trg-003":
        | status  | active |
        | run_now | true   |
      Then 觸發器應立即執行一次
      And trigger_executions 表應新增一筆記錄:
        | trigger_id | trg-003    |
        | type       | manual     |
        | started_at | (當前時間) |
  # ============================================================
  # Rule: 批次操作
  # ============================================================

  Rule: 支援批次啟用或停用多個觸發器

    Example: 成功 - 批次停用
      # API: PATCH /api/v1/agents/{id}/triggers/batch
      When 使用者發送 PATCH 請求至 "/api/v1/agents/agent-001/triggers/batch":
        | ids    | ["trg-001", "trg-002"] |
        | status | paused                 |
      Then 請求應成功
      And trg-001 和 trg-002 的 status 應為 "paused"
      And 回傳結果應包含:
        | field         | value |
        | updated_count |     2 |

    Example: 成功 - 停用 Agent 的所有觸發器
      # API: PATCH /api/v1/agents/{id}/triggers/batch
      When 使用者發送 PATCH 請求至 "/api/v1/agents/agent-001/triggers/batch":
        | status | paused |
      Then Agent "agent-001" 的所有觸發器應被停用
      And 回傳應包含更新的觸發器數量
  # ============================================================
  # Rule: 權限控制
  # ============================================================

  Rule: 只有觸發器擁有者可以變更狀態

    Example: 失敗 - 變更他人的觸發器狀態
      Given Agent "agent-002" 有觸發器 "trg-other"
      # API: PATCH /api/v1/agents/{id}/triggers/{trigger_id}
      When 使用者 "user-001" 發送 PATCH 請求至 "/api/v1/agents/agent-002/triggers/trg-other":
        | status | paused |
      Then 請求應失敗，回傳狀態碼 403
      And 錯誤訊息應為 "You do not have permission to modify this trigger"

    Example: 失敗 - 觸發器不存在
      # API: PATCH /api/v1/agents/{id}/triggers/{trigger_id}
      When 使用者發送 PATCH 請求至 "/api/v1/agents/agent-001/triggers/non-existent":
        | status | paused |
      Then 請求應失敗，回傳狀態碼 404
      And 錯誤訊息應為 "Trigger not found"

    Example: 成功 - 管理員可變更任何觸發器
      Given 使用者 "admin@example.com" 已登入（角色為 admin）
      # API: PATCH /api/v1/agents/{id}/triggers/{trigger_id}
      When 使用者發送 PATCH 請求至 "/api/v1/agents/agent-001/triggers/trg-001":
        | status | paused |
      Then 請求應成功
  # ============================================================
  # Rule: 狀態驗證
  # ============================================================

  Rule: 只允許有效的狀態轉換

    Example: 失敗 - 無效的狀態值
      # API: PATCH /api/v1/agents/{id}/triggers/{trigger_id}
      When 使用者發送 PATCH 請求至 "/api/v1/agents/agent-001/triggers/trg-001":
        | status | invalid |
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "Invalid status. Allowed values: 'active', 'paused'"

    Example: 冪等性 - 重複設定相同狀態
      Given 觸發器 "trg-001" 的 status 已經是 "active"
      # API: PATCH /api/v1/agents/{id}/triggers/{trigger_id}
      When 使用者發送 PATCH 請求至 "/api/v1/agents/agent-001/triggers/trg-001":
        | status | active |
      Then 請求應成功，回傳狀態碼 200
      And 回傳應標示 "no_change": true

    Example: 失敗 - 無法啟用錯誤狀態的觸發器
      Given 觸發器 "trg-001" 的 status 為 "error"
      # API: PATCH /api/v1/agents/{id}/triggers/{trigger_id}
      When 使用者發送 PATCH 請求至 "/api/v1/agents/agent-001/triggers/trg-001":
        | status | active |
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "Cannot activate trigger in error state. Please fix the configuration first."
  # ============================================================
  # Rule: 審計日誌
  # ============================================================

  Rule: 狀態變更應記錄審計日誌

    Example: 記錄停用操作
      When 使用者停用觸發器 "trg-001"
      Then audit_logs 表應新增一筆記錄:
        | field       | value                                         |
        | action      | trigger.pause                                 |
        | actor_id    | user-001                                      |
        | target_type | trigger                                       |
        | target_id   | trg-001                                       |
        | details     | {"previous_status": "active", "reason": null} |
        | created_at  | (當前時間)                                    |

    Example: 記錄啟用操作
      When 使用者啟用觸發器 "trg-003"
      Then audit_logs 表應新增一筆記錄:
        | field     | value                                               |
        | action    | trigger.activate                                    |
        | target_id | trg-003                                             |
        | details   | {"previous_status": "paused", "next_run_at": "..."} |

    Example: 包含停用原因
      # API: PATCH /api/v1/agents/{id}/triggers/{trigger_id}
      When 使用者發送 PATCH 請求至 "/api/v1/agents/agent-001/triggers/trg-001":
        | status | paused           |
        | reason | 維護中，暫時停用 |
      Then triggers 表應記錄 pause_reason
      And audit_logs 的 details 應包含 reason
