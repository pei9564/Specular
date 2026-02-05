Feature: 查詢觸發器執行歷史
  查看 Trigger 的執行結果與日誌

  Background:
    Given 系統中存在以下 Agent:
      | id        | name     | owner_id |
      | agent-001 | TaskBot  | user-001 |
      | agent-002 | OtherBot | user-002 |
    And Agent "agent-001" 有以下觸發器:
      | id      | name         |
      | trg-001 | Daily Report |
      | trg-002 | API Hook     |
    And 觸發器 "trg-001" 有以下執行記錄:
      | id       | status    | started_at          | finished_at         | duration_ms | tokens_used |
      | exec-001 | completed | 2024-01-15 09:00:00 | 2024-01-15 09:00:30 |       30000 |        1500 |
      | exec-002 | completed | 2024-01-14 09:00:00 | 2024-01-14 09:00:25 |       25000 |        1200 |
      | exec-003 | failed    | 2024-01-13 09:00:00 | 2024-01-13 09:00:10 |       10000 |         500 |
      | exec-004 | running   | 2024-01-16 09:00:00 | null                | null        | null        |
    And 使用者 "user-001" 已登入
  # ============================================================
  # Rule: 查詢執行歷史列表
  # ============================================================

  Rule: 用戶可以查詢觸發器的執行歷史

    Example: 成功 - 查詢特定觸發器的執行歷史
      When 使用者發送 GET 請求至 "/api/triggers/trg-001/executions"
      Then 請求應成功，回傳狀態碼 200
      And 回傳結果應包含:
        | field | value |
        | total |     4 |
      And data 陣列應依 started_at 降序排列（最新的在前）
      And 每筆執行記錄應包含:
        | field        | type     | description                     |
        | id           | string   | 執行記錄 UUID                   |
        | trigger_id   | string   | 觸發器 ID                       |
        | status       | string   | completed/failed/running/queued |
        | trigger_type | string   | schedule/webhook/event          |
        | input        | string   | 輸入內容                        |
        | started_at   | datetime | 開始時間                        |
        | finished_at  | datetime | 結束時間（可為 null）           |
        | duration_ms  | number   | 執行時長毫秒                    |
        | tokens_used  | number   | Token 使用量                    |

    Example: 成功 - 查詢 Agent 的所有觸發器執行歷史
      When 使用者發送 GET 請求至 "/api/agents/agent-001/executions"
      Then 請求應成功
      And 回傳結果應包含 Agent 下所有觸發器的執行記錄
      And 每筆記錄應包含 trigger_name 欄位
  # ============================================================
  # Rule: 分頁功能
  # ============================================================

  Rule: 執行歷史支援分頁查詢

    Example: 成功 - 分頁查詢
      When 使用者發送 GET 請求至 "/api/triggers/trg-001/executions":
        | page      | 1 |
        | page_size | 2 |
      Then 請求應成功
      And 回傳結果應包含:
        | total       | 4 |
        | page        | 1 |
        | page_size   | 2 |
        | total_pages | 2 |
      And data 陣列應包含 2 筆記錄（exec-004, exec-001）

    Example: 成功 - 使用 cursor 分頁
      When 使用者發送 GET 請求至 "/api/triggers/trg-001/executions":
        | cursor | exec-002 |
        | limit  |       10 |
      Then 回傳結果應包含 exec-002 之後（更早）的執行記錄
  # ============================================================
  # Rule: 篩選功能
  # ============================================================

  Rule: 支援依條件篩選執行記錄

    Example: 成功 - 依狀態篩選
      When 使用者發送 GET 請求至 "/api/triggers/trg-001/executions":
        | status | completed |
      Then 回傳結果應只包含 status 為 "completed" 的記錄
      And total 應為 2

    Example: 成功 - 依時間範圍篩選
      When 使用者發送 GET 請求至 "/api/triggers/trg-001/executions":
        | start_date | 2024-01-14 |
        | end_date   | 2024-01-15 |
      Then 回傳結果應只包含指定日期範圍內的執行記錄
      And total 應為 2（exec-001, exec-002）

    Example: 成功 - 只查詢失敗的執行
      When 使用者發送 GET 請求至 "/api/triggers/trg-001/executions":
        | status | failed |
      Then 回傳結果應只包含:
        | id       | status |
        | exec-003 | failed |

    Example: 成功 - 依觸發類型篩選
      When 使用者發送 GET 請求至 "/api/agents/agent-001/executions":
        | trigger_type | webhook |
      Then 回傳結果應只包含 webhook 類型觸發器的執行記錄
  # ============================================================
  # Rule: 執行詳情
  # ============================================================

  Rule: 可以查詢單一執行記錄的詳細資訊

    Example: 成功 - 查詢執行詳情
      When 使用者發送 GET 請求至 "/api/executions/exec-001"
      Then 請求應成功，回傳狀態碼 200
      And 回傳結果應包含:
        | field             | value               |
        | id                | exec-001            |
        | trigger_id        | trg-001             |
        | trigger_name      | Daily Report        |
        | agent_id          | agent-001           |
        | agent_name        | TaskBot             |
        | status            | completed           |
        | trigger_type      | schedule            |
        | input             | (輸入內容)          |
        | output            | (Agent 輸出結果)    |
        | started_at        | 2024-01-15 09:00:00 |
        | finished_at       | 2024-01-15 09:00:30 |
        | duration_ms       |               30000 |
        | prompt_tokens     | (輸入 token)        |
        | completion_tokens | (輸出 token)        |
        | total_tokens      |                1500 |

    Example: 成功 - 查詢失敗執行的錯誤詳情
      When 使用者發送 GET 請求至 "/api/executions/exec-003"
      Then 回傳結果應包含 error 物件:
        | field   | value             |
        | code    | RUNTIME_ERROR     |
        | message | (錯誤訊息)        |
        | stack   | (錯誤堆疊，如有） |

    Example: 成功 - 包含工具調用記錄
      Given 執行記錄 "exec-001" 包含工具調用
      When 使用者發送 GET 請求至 "/api/executions/exec-001":
        | include_tool_calls | true |
      Then 回傳結果應包含 tool_calls 陣列:
        | tool_name  | status  | duration_ms |
        | send_email | success |         500 |
        | calculate  | success |         100 |
  # ============================================================
  # Rule: 權限控制
  # ============================================================

  Rule: 用戶只能查詢自己 Agent 的執行歷史

    Example: 失敗 - 查詢他人觸發器的執行歷史
      Given Agent "agent-002" 有觸發器 "trg-other"
      When 使用者 "user-001" 發送 GET 請求至 "/api/triggers/trg-other/executions"
      Then 請求應失敗，回傳狀態碼 403
      And 錯誤訊息應為 "You do not have permission to access this trigger"

    Example: 失敗 - 查詢不存在的觸發器
      When 使用者發送 GET 請求至 "/api/triggers/non-existent/executions"
      Then 請求應失敗，回傳狀態碼 404
      And 錯誤訊息應為 "Trigger not found"

    Example: 成功 - 管理員可查詢任何執行歷史
      Given 使用者 "admin@example.com" 已登入（角色為 admin）
      When 使用者發送 GET 請求至 "/api/triggers/trg-other/executions"
      Then 請求應成功
  # ============================================================
  # Rule: 統計資訊
  # ============================================================

  Rule: 可以查詢執行統計資訊

    Example: 成功 - 查詢觸發器執行統計
      When 使用者發送 GET 請求至 "/api/triggers/trg-001/stats"
      Then 請求應成功
      And 回傳結果應包含:
        | field              | value               |
        | total_executions   |                   4 |
        | successful_count   |                   2 |
        | failed_count       |                   1 |
        | running_count      |                   1 |
        | success_rate       |               66.67 |
        | avg_duration_ms    |               21666 |
        | total_tokens_used  |                3200 |
        | last_execution_at  | 2024-01-16 09:00:00 |
        | last_successful_at | 2024-01-15 09:00:00 |

    Example: 成功 - 查詢時間範圍內的統計
      When 使用者發送 GET 請求至 "/api/triggers/trg-001/stats":
        | start_date | 2024-01-14 |
        | end_date   | 2024-01-15 |
      Then 統計應只計算指定範圍內的執行記錄

    Example: 成功 - 查詢 Agent 層級統計
      When 使用者發送 GET 請求至 "/api/agents/agent-001/execution-stats"
      Then 回傳結果應包含該 Agent 下所有觸發器的彙總統計
  # ============================================================
  # Rule: 日誌查詢
  # ============================================================

  Rule: 可以查詢執行過程的詳細日誌

    Example: 成功 - 查詢執行日誌
      When 使用者發送 GET 請求至 "/api/executions/exec-001/logs"
      Then 請求應成功
      And 回傳結果應包含執行過程的日誌:
        | timestamp           | level | message                   |
        | 2024-01-15 09:00:00 | INFO  | Execution started         |
        | 2024-01-15 09:00:01 | INFO  | Input parsed successfully |
        | 2024-01-15 09:00:05 | INFO  | Calling LLM API           |
        | 2024-01-15 09:00:20 | INFO  | Tool call: send_email     |
        | 2024-01-15 09:00:25 | INFO  | Tool call completed       |
        | 2024-01-15 09:00:30 | INFO  | Execution completed       |

    Example: 成功 - 查詢失敗執行的錯誤日誌
      When 使用者發送 GET 請求至 "/api/executions/exec-003/logs"
      Then 回傳結果應包含錯誤日誌:
        | level | message                    |
        | ERROR | LLM API returned error 500 |
        | ERROR | Execution failed           |
  # ============================================================
  # Rule: 重新執行
  # ============================================================

  Rule: 可以重新執行失敗的觸發

    Example: 成功 - 重新執行失敗的觸發
      Given 執行記錄 "exec-003" 的 status 為 "failed"
      When 使用者發送 POST 請求至 "/api/executions/exec-003/retry"
      Then 請求應成功，回傳狀態碼 202
      And trigger_executions 表應新增一筆記錄:
        | field      | value              |
        | trigger_id | trg-001            |
        | status     | running            |
        | retry_of   | exec-003           |
        | input      | (與 exec-003 相同) |
      And 回傳結果應包含新的 execution_id

    Example: 失敗 - 無法重新執行成功的觸發
      Given 執行記錄 "exec-001" 的 status 為 "completed"
      When 使用者發送 POST 請求至 "/api/executions/exec-001/retry"
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "Can only retry failed executions"
