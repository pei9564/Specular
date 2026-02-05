Feature: 設定 Agent 觸發器
  配置 Agent 的主動執行條件 (Triggers)

  Background:
    Given 系統中存在以下 Agent:
      | id        | name     | owner_id | status | mode     |
      | agent-001 | TaskBot  | user-001 | active | triggers |
      | agent-002 | ChatBot  | user-001 | active | chat     |
      | agent-003 | OtherBot | user-002 | active | triggers |
    And 使用者 "user-001" 已登入
  # ============================================================
  # Rule: 排程觸發器 (Schedule)
  # ============================================================

  Rule: 可以為 triggers 模式的 Agent 設定排程觸發

    Example: 成功 - 設定 Cron 排程觸發器
      When 使用者發送 POST 請求至 "/api/agents/agent-001/triggers":
        | type            | schedule       |
        | name            | Daily Report   |
        | config.cron     |    0 9 * * 1-5 |
        | config.timezone | Asia/Taipei    |
        | input_template  | 請生成今日報告 |
      Then 請求應成功，回傳狀態碼 201
      And triggers 表應新增一筆記錄:
        | field          | value                                              |
        | id             | (自動生成 UUID)                                    |
        | agent_id       | agent-001                                          |
        | type           | schedule                                           |
        | name           | Daily Report                                       |
        | config         | {"cron": "0 9 * * 1-5", "timezone": "Asia/Taipei"} |
        | input_template | 請生成今日報告                                     |
        | status         | active                                             |
        | next_run_at    | (根據 cron 計算的下次執行時間)                     |
        | created_at     | (當前時間)                                         |
        | created_by     | user-001                                           |
      And 回傳結果應包含 trigger_id 和 next_run_at

    Example: 成功 - 設定每小時執行的排程
      When 使用者發送 POST 請求至 "/api/agents/agent-001/triggers":
        | type        | schedule  |
        | config.cron | 0 * * * * |
      Then 請求應成功
      And next_run_at 應為下一個整點時間

    Example: 失敗 - 無效的 Cron 表達式
      When 使用者發送 POST 請求至 "/api/agents/agent-001/triggers":
        | type        | schedule     |
        | config.cron | invalid-cron |
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "Invalid cron expression: 'invalid-cron'"

    Example: 失敗 - 執行頻率過高（低於 1 分鐘）
      When 使用者發送 POST 請求至 "/api/agents/agent-001/triggers":
        | type        | schedule       |
        | config.cron | */30 * * * * * |
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "Minimum schedule interval is 1 minute"
  # ============================================================
  # Rule: Webhook 觸發器
  # ============================================================

  Rule: 可以設定 Webhook 觸發器接收外部請求

    Example: 成功 - 設定 Webhook 觸發器
      When 使用者發送 POST 請求至 "/api/agents/agent-001/triggers":
        | type           | webhook                                                             |
        | name           | GitHub Webhook                                                      |
        | config.secret  | my-webhook-secret                                                   |
        | input_template | 收到 GitHub 事件: {{payload.action}} on {{payload.repository.name}} |
      Then 請求應成功，回傳狀態碼 201
      And triggers 表應新增一筆記錄:
        | field  | value                                                       |
        | type   | webhook                                                     |
        | config | {"secret_hash": "(hash)", "path": "/webhooks/(trigger_id)"} |
      And 回傳結果應包含:
        | field       | value                                         |
        | webhook_url | https://api.specular.ai/webhooks/(trigger_id) |
        | secret      | my-webhook-secret                             |
      And secret 應只在創建時回傳一次，後續查詢不應包含

    Example: 成功 - 自動生成 Webhook Secret
      When 使用者發送 POST 請求至 "/api/agents/agent-001/triggers":
        | type | webhook             |
        | name | Auto Secret Webhook |
      Then 請求應成功
      And 系統應自動生成安全的 secret（32 字元隨機字串）
      And 回傳結果應包含生成的 secret

    Example: Webhook 需要正確的 Secret 驗證
      Given Agent "agent-001" 有 Webhook 觸發器，secret 為 "my-secret"
      When 外部系統呼叫 webhook URL:
        | header           | value        |
        | X-Webhook-Secret | wrong-secret |
      Then 請求應失敗，回傳狀態碼 401
      And 錯誤訊息應為 "Invalid webhook secret"
  # ============================================================
  # Rule: 事件觸發器
  # ============================================================

  Rule: 可以設定系統內部事件觸發器

    Example: 成功 - 設定文件上傳事件觸發器
      When 使用者發送 POST 請求至 "/api/agents/agent-001/triggers":
        | type           | event                                       |
        | name           | Process New Documents                       |
        | config.event   | document.uploaded                           |
        | config.filter  | {"type": "pdf", "size_gt": 1000}            |
        | input_template | 請處理新上傳的文件: {{event.document.name}} |
      Then 請求應成功
      And triggers 表應新增一筆記錄:
        | field  | value                                           |
        | type   | event                                           |
        | config | {"event": "document.uploaded", "filter": {...}} |

    Example: 支援的系統事件列表
      When 使用者發送 GET 請求至 "/api/triggers/events"
      Then 回傳結果應包含可用的事件類型:
        | event              | description    |
        | document.uploaded  | 文件上傳完成   |
        | document.processed | 文件處理完成   |
        | rag.indexed        | RAG 索引完成   |
        | user.created       | 新用戶註冊     |
        | agent.error        | Agent 執行錯誤 |
  # ============================================================
  # Rule: Input Template
  # ============================================================

  Rule: Input Template 支援動態變數替換

    Example: 成功 - 使用 Payload 變數
      Given Agent "agent-001" 有 Webhook 觸發器:
        | input_template | 用戶 {{payload.username}} 提交了請求: {{payload.message}} |
      When 外部系統呼叫 webhook:
        | payload | {"username": "john", "message": "Hello"} |
      Then Agent 收到的輸入應為 "用戶 john 提交了請求: Hello"

    Example: 成功 - 使用 Event 變數
      Given Agent "agent-001" 有事件觸發器:
        | input_template | 新文件: {{event.document.name}}, 大小: {{event.document.size}} bytes |
      When 系統觸發 document.uploaded 事件:
        | document.name | report.pdf |
        | document.size |       1024 |
      Then Agent 收到的輸入應為 "新文件: report.pdf, 大小: 1024 bytes"

    Example: 成功 - 使用系統變數
      Given Agent "agent-001" 有排程觸發器:
        | input_template | 定時任務執行於 {{system.timestamp}}, 觸發器: {{trigger.name}} |
      When 排程時間到達
      Then Agent 收到的輸入應包含當前時間戳和觸發器名稱

    Example: 失敗 - 無效的變數引用
      When 使用者發送 POST 請求至 "/api/agents/agent-001/triggers":
        | input_template | {{invalid.variable}} |
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "Invalid template variable: 'invalid.variable'"
  # ============================================================
  # Rule: 權限控制
  # ============================================================

  Rule: 只有 Agent 擁有者可以設定觸發器

    Example: 失敗 - 為他人的 Agent 設定觸發器
      When 使用者 "user-001" 發送 POST 請求至 "/api/agents/agent-003/triggers":
        | type | schedule |
      Then 請求應失敗，回傳狀態碼 403
      And 錯誤訊息應為 "You do not have permission to modify this agent"

    Example: 失敗 - 為 chat 模式 Agent 設定觸發器
      When 使用者發送 POST 請求至 "/api/agents/agent-002/triggers":
        | type | schedule |
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "Triggers can only be configured for agents in 'triggers' mode"
  # ============================================================
  # Rule: 觸發器數量限制
  # ============================================================

  Rule: 單一 Agent 的觸發器數量有上限

    Example: 失敗 - 超過觸發器上限
      Given Agent "agent-001" 已有 10 個觸發器（達到上限）
      When 使用者發送 POST 請求至 "/api/agents/agent-001/triggers":
        | type | schedule |
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "Maximum trigger limit reached (10 per agent)"
  # ============================================================
  # Rule: 查詢觸發器
  # ============================================================

  Rule: 可以查詢 Agent 的所有觸發器

    Example: 成功 - 查詢觸發器列表
      Given Agent "agent-001" 有以下觸發器:
        | id      | type     | name          | status |
        | trg-001 | schedule | Daily Report  | active |
        | trg-002 | webhook  | GitHub Hook   | active |
        | trg-003 | event    | Doc Processor | paused |
      When 使用者發送 GET 請求至 "/api/agents/agent-001/triggers"
      Then 請求應成功
      And 回傳結果應包含 3 個觸發器
      And 每個觸發器應包含:
        | field          | type     |
        | id             | string   |
        | type           | string   |
        | name           | string   |
        | status         | string   |
        | config         | object   |
        | input_template | string   |
        | next_run_at    | datetime |
        | last_run_at    | datetime |
        | created_at     | datetime |
