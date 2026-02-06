Feature: 觸發事件並調用 Runtime
  系統內部處理觸發事件的流程

  Background:
    Given 系統中存在以下 Agent:
      | id        | name    | owner_id | mode     | model_id | system_prompt    |
      | agent-001 | TaskBot | user-001 | triggers | gpt-4o   | 你是任務處理助手 |
    And Agent "agent-001" 已綁定 Skills:
      | skill_id  | function_name |
      | skill-001 | send_email    |
    And Agent "agent-001" 有以下觸發器:
      | id      | type     | name         | status | input_template                    |
      | trg-001 | schedule | Daily Report | active | 請生成 {{system.date}} 的日報     |
      | trg-002 | webhook  | API Hook     | active | 處理請求: {{payload.action}}      |
      | trg-003 | event    | Doc Process  | active | 處理文件: {{event.document.name}} |
  # ============================================================
  # Rule: 排程觸發執行
  # ============================================================

  Rule: 排程時間到達時系統應自動觸發執行

    Example: 成功 - 排程觸發執行流程
      Given 觸發器 "trg-001" 的 next_run_at 為 "2024-01-16 09:00:00"
      And 當前系統時間為 "2024-01-16 09:00:00"
      When 系統排程檢查器偵測到觸發時間
      Then trigger_executions 表應新增一筆記錄:
        | field        | value                    |
        | id           | (自動生成 UUID)          |
        | trigger_id   | trg-001                  |
        | agent_id     | agent-001                |
        | status       | running                  |
        | trigger_type | schedule                 |
        | input        | 請生成 2024-01-16 的日報 |
        | started_at   | (當前時間)               |
        | attempt      |                        1 |
      And 系統應調用 Agent Runtime 執行 Agent
      And triggers 表中 trg-001 的 last_run_at 應更新為當前時間
      And triggers 表中 trg-001 的 next_run_at 應更新為下次執行時間

    Example: 執行完成 - 更新狀態為 completed
      Given 觸發器執行記錄 "exec-001" 正在執行中
      When Agent Runtime 成功完成執行
      Then trigger_executions 表中 exec-001 應更新:
        | field       | value            |
        | status      | completed        |
        | output      | (Agent 輸出結果) |
        | finished_at | (當前時間)       |
        | duration_ms | (執行時長毫秒)   |
        | tokens_used | (使用的 token)   |

    Example: 執行失敗 - 更新狀態為 failed
      Given 觸發器執行記錄 "exec-001" 正在執行中
      When Agent Runtime 執行過程中發生錯誤
      Then trigger_executions 表中 exec-001 應更新:
        | field       | value                                       |
        | status      | failed                                      |
        | error       | {"code": "RUNTIME_ERROR", "message": "..."} |
        | finished_at | (當前時間)                                  |
  # ============================================================
  # Rule: Webhook 觸發執行
  # ============================================================

  Rule: 收到 Webhook 請求時應觸發執行

    Example: 成功 - Webhook 觸發執行流程
      Given 觸發器 "trg-002" 的 webhook_url 為 "https://api.specular.ai/api/v1/webhooks/trg-002"
      When 外部系統發送 POST 請求至該 URL:
        | header           | value                                     |
        | X-Webhook-Secret | (正確的 secret)                           |
        | Content-Type     | application/json                          |
        | body             | {"action": "deploy", "env": "production"} |
      Then 請求應成功，回傳狀態碼 202 Accepted
      And 回傳結果應包含:
        | field        | value         |
        | execution_id | (執行記錄 ID) |
        | status       | accepted      |
      And trigger_executions 表應新增一筆記錄:
        | field        | value                                     |
        | trigger_id   | trg-002                                   |
        | trigger_type | webhook                                   |
        | input        | 處理請求: deploy                          |
        | payload      | {"action": "deploy", "env": "production"} |
        | source_ip    | (請求來源 IP)                             |

    Example: 失敗 - Secret 驗證失敗
      When 外部系統發送請求，X-Webhook-Secret 不正確
      Then 請求應失敗，回傳狀態碼 401
      And 不應建立執行記錄
      And 應記錄安全警告日誌

    Example: 失敗 - 請求頻率過高
      Given 觸發器 "trg-002" 在過去 1 分鐘內已收到 100 次請求
      When 外部系統再次發送請求
      Then 請求應失敗，回傳狀態碼 429
      And 錯誤訊息應為 "Rate limit exceeded for this webhook"
  # ============================================================
  # Rule: 事件觸發執行
  # ============================================================

  Rule: 系統事件發生時應觸發對應的執行

    Example: 成功 - 事件觸發執行流程
      Given 觸發器 "trg-003" 監聽 "document.uploaded" 事件
      And 觸發器配置 filter 為 {"type": "pdf"}
      When 系統發布事件:
        | event_type    | document.uploaded |
        | document.name | report.pdf        |
        | document.type | pdf               |
        | document.size |              1024 |
      Then trigger_executions 表應新增一筆記錄:
        | field        | value                                      |
        | trigger_id   | trg-003                                    |
        | trigger_type | event                                      |
        | input        | 處理文件: report.pdf                       |
        | event_data   | {"name": "report.pdf", "type": "pdf", ...} |

    Example: 事件不符合 filter 條件時不觸發
      Given 觸發器 "trg-003" 的 filter 為 {"type": "pdf"}
      When 系統發布事件:
        | event_type    | document.uploaded |
        | document.type | docx              |
      Then 觸發器 "trg-003" 不應執行
      And trigger_executions 表不應有新增記錄
  # ============================================================
  # Rule: Input Template 解析
  # ============================================================

  Rule: 系統應正確解析 Input Template 生成輸入

    Example: 解析 payload 變數
      Given 觸發器的 input_template 為 "用戶: {{payload.user}}, 操作: {{payload.action}}"
      When webhook 收到 payload: {"user": "john", "action": "submit"}
      Then 生成的 input 應為 "用戶: john, 操作: submit"

    Example: 解析 event 變數
      Given 觸發器的 input_template 為 "文件: {{event.document.name}}"
      When 事件觸發: {"document": {"name": "test.pdf"}}
      Then 生成的 input 應為 "文件: test.pdf"

    Example: 解析 system 變數
      Given 觸發器的 input_template 為 "執行於: {{system.timestamp}}, 觸發器: {{trigger.name}}"
      When 觸發器 "Daily Report" 執行
      Then 生成的 input 應包含當前時間戳和 "Daily Report"

    Example: 處理缺失的變數
      Given 觸發器的 input_template 為 "用戶: {{payload.user}}"
      When webhook 收到 payload: {}（缺少 user）
      Then 生成的 input 應為 "用戶: "（空值）
      And 應記錄警告日誌

    Example: 支援巢狀變數
      Given 觸發器的 input_template 為 "{{payload.data.items[0].name}}"
      When webhook 收到 payload: {"data": {"items": [{"name": "first"}]}}
      Then 生成的 input 應為 "first"
  # ============================================================
  # Rule: Agent Runtime 調用
  # ============================================================

  Rule: 系統應正確調用 Agent Runtime 執行任務

    Example: Runtime 調用參數
      When 系統調用 Agent Runtime 執行觸發器
      Then 調用參數應包含:
        | field         | value            |
        | agent_id      | agent-001        |
        | input         | (解析後的 input) |
        | model_id      | gpt-4o           |
        | system_prompt | 你是任務處理助手 |
        | skills        | [skill-001]      |
        | execution_id  | (執行記錄 ID)    |

    Example: 工具調用記錄
      Given Agent 執行過程中調用了 send_email 工具
      Then tool_calls 表應新增一筆記錄:
        | field        | value          |
        | execution_id | (執行記錄 ID)  |
        | tool_type    | skill          |
        | tool_name    | send_email     |
        | input        | (工具輸入參數) |
        | output       | (工具輸出結果) |
        | status       | success        |
  # ============================================================
  # Rule: 重試機制
  # ============================================================

  Rule: 執行失敗時應支援重試

    Example: 自動重試
      Given 觸發器 "trg-001" 配置 max_retries 為 3
      And 執行記錄 "exec-001" 第一次執行失敗
      Then 系統應在 30 秒後自動重試
      And 新的執行記錄應標示:
        | field   | value |
        | attempt |     2 |

    Example: 達到最大重試次數
      Given 執行記錄已重試 3 次（達到上限）
      When 第 3 次重試仍失敗
      Then 執行記錄的 status 應為 "failed"
      And 不應再自動重試
      And 應發送告警通知給 Agent 擁有者

    Example: 指數退避重試間隔
      Given 觸發器配置使用指數退避策略
      Then 重試間隔應為:
        | attempt | interval |
        |       1 |    30 秒 |
        |       2 |    60 秒 |
        |       3 |   120 秒 |
  # ============================================================
  # Rule: 並發控制
  # ============================================================

  Rule: 同一觸發器應限制並發執行數量

    Example: 限制並發執行
      Given 觸發器 "trg-001" 配置 max_concurrent 為 1
      And 目前有一個執行記錄狀態為 "running"
      When 觸發條件再次滿足
      Then 新的執行應被排入佇列
      And 執行記錄的 status 應為 "queued"

    Example: 佇列執行完成後繼續
      Given 佇列中有一個等待執行的任務
      When 當前執行完成
      Then 佇列中的任務應開始執行
      And 執行記錄的 status 應從 "queued" 變為 "running"
  # ============================================================
  # Rule: Token 使用量追蹤
  # ============================================================

  Rule: 觸發器執行應追蹤 Token 使用量

    Example: 記錄 Token 使用量
      When 觸發器執行完成
      Then trigger_executions 記錄應包含:
        | field             | value        |
        | prompt_tokens     | (輸入 token) |
        | completion_tokens | (輸出 token) |
        | total_tokens      | (總計)       |
      And token_usage 表應新增一筆記錄:
        | field      | value     |
        | user_id    | user-001  |
        | agent_id   | agent-001 |
        | trigger_id | trg-001   |
        | source     | trigger   |
