Feature: Agent 模式設定
  設定 Agent 為被動對話或主動觸發模式

  Background:
    Given 系統中存在以下 Agent:
      | id        | name       | owner_id | status | mode     |
      | agent-001 | ChatAgent  | user-001 | active | chat     |
      | agent-002 | TaskAgent  | user-001 | active | triggers |
      | agent-003 | DraftAgent | user-001 | draft  | chat     |
    And 使用者 "user-001" 已登入
  # ============================================================
  # Rule: Chat 模式設定
  # ============================================================

  Rule: Chat 模式使 Agent 出現在對話列表中等待使用者輸入

    Example: 成功 - 設定為 Chat 模式
      Given Agent "agent-002" 的 mode 為 "triggers"
      When 使用者 "user-001" 提交編輯請求:
        | agent_id | agent-002 |
        | mode     | chat      |
      Then 請求應成功，回傳狀態碼 200
      And Agent "agent-002" 的資料應更新為:
        | field      | old_value | new_value  |
        | mode       | triggers  | chat       |
        | updated_at | (原時間)  | (當前時間) |

    Example: Chat 模式 Agent 出現在對話列表
      Given Agent "agent-001" 的 mode 為 "chat" 且 status 為 "active"
      When 使用者 "user-001" 查詢可對話 Agent 列表
      Then 回傳結果應包含 "ChatAgent"
      And 每筆 Agent 應包含:
        | field          | value     |
        | id             | agent-001 |
        | name           | ChatAgent |
        | can_start_chat | true      |

    Example: Draft 狀態的 Chat Agent 不出現在對話列表
      Given Agent "agent-003" 的 mode 為 "chat" 且 status 為 "draft"
      When 使用者 "user-001" 查詢可對話 Agent 列表
      Then 回傳結果不應包含 "DraftAgent"

    Example: Chat 模式下 Agent 等待使用者輸入後回應
      Given Agent "agent-001" 為 chat 模式
      And 使用者開啟與 "agent-001" 的對話 session
      When 使用者發送訊息 "你好"
      Then 系統應建立 conversation_messages 記錄:
        | field      | value          |
        | session_id | (session UUID) |
        | agent_id   | agent-001      |
        | role       | user           |
        | content    | 你好           |
        | created_at | (當前時間)     |
      And Agent 應產生回應並建立記錄:
        | field      | value            |
        | session_id | (session UUID)   |
        | agent_id   | agent-001        |
        | role       | assistant        |
        | content    | (Agent 回應內容) |
  # ============================================================
  # Rule: Triggers 模式設定
  # ============================================================

  Rule: Triggers 模式使 Agent 由事件或排程觸發執行

    Example: 成功 - 設定為 Triggers 模式
      Given Agent "agent-001" 的 mode 為 "chat"
      When 使用者 "user-001" 提交編輯請求:
        | agent_id | agent-001 |
        | mode     | triggers  |
      Then 請求應成功
      And Agent "agent-001" 的 mode 應為 "triggers"
      And Agent "agent-001" 應從對話列表中移除

    Example: Triggers 模式 Agent 不出現在對話列表
      Given Agent "agent-002" 的 mode 為 "triggers"
      When 使用者 "user-001" 查詢可對話 Agent 列表
      Then 回傳結果不應包含 "TaskAgent"

    Example: Triggers 模式 Agent 出現在自動化設定列表
      Given Agent "agent-002" 的 mode 為 "triggers"
      When 使用者 "user-001" 查詢可設定觸發器的 Agent 列表
      Then 回傳結果應包含:
        | id        | name      | mode     |
        | agent-002 | TaskAgent | triggers |
  # ============================================================
  # Rule: 觸發器配置（Triggers 模式專屬）
  # ============================================================

  Rule: Triggers 模式 Agent 可配置觸發條件

    Example: 成功 - 配置 Webhook 觸發器
      Given Agent "agent-002" 的 mode 為 "triggers"
      When 使用者 "user-001" 提交觸發器配置請求:
        | agent_id     | agent-002                       |
        | trigger_type | webhook                         |
        | config       | {"path": "/api/hook/agent-002"} |
      Then 請求應成功
      And agent_triggers 表應新增一筆記錄:
        | agent_id  | type    | config                          | status |
        | agent-002 | webhook | {"path": "/api/hook/agent-002"} | active |
      And 系統應生成 webhook URL: "https://api.specular.ai/hook/agent-002"

    Example: 成功 - 配置排程觸發器 (Cron)
      Given Agent "agent-002" 的 mode 為 "triggers"
      When 使用者 "user-001" 提交觸發器配置請求:
        | agent_id     | agent-002                                          |
        | trigger_type | schedule                                           |
        | config       | {"cron": "0 9 * * 1-5", "timezone": "Asia/Taipei"} |
      Then 請求應成功
      And agent_triggers 表應新增一筆記錄:
        | agent_id  | type     | config                                             | next_run       |
        | agent-002 | schedule | {"cron": "0 9 * * 1-5", "timezone": "Asia/Taipei"} | (下次執行時間) |

    Example: 成功 - 配置事件觸發器
      Given Agent "agent-002" 的 mode 為 "triggers"
      When 使用者 "user-001" 提交觸發器配置請求:
        | agent_id     | agent-002                                                 |
        | trigger_type | event                                                     |
        | config       | {"event": "document.uploaded", "filter": {"type": "pdf"}} |
      Then 請求應成功
      And agent_triggers 表應新增一筆記錄:
        | agent_id  | type  | config                                                    |
        | agent-002 | event | {"event": "document.uploaded", "filter": {"type": "pdf"}} |

    Example: 失敗 - Chat 模式 Agent 無法配置觸發器
      Given Agent "agent-001" 的 mode 為 "chat"
      When 使用者 "user-001" 提交觸發器配置請求:
        | agent_id     | agent-001 |
        | trigger_type | webhook   |
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "Triggers can only be configured for agents in 'triggers' mode"

    Example: 失敗 - 無效的 Cron 表達式
      Given Agent "agent-002" 的 mode 為 "triggers"
      When 使用者 "user-001" 提交觸發器配置請求:
        | agent_id     | agent-002                |
        | trigger_type | schedule                 |
        | config       | {"cron": "invalid-cron"} |
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "Invalid cron expression: 'invalid-cron'"
  # ============================================================
  # Rule: 觸發執行記錄
  # ============================================================

  Rule: 每次觸發執行都應記錄

    Example: Webhook 觸發執行記錄
      Given Agent "agent-002" 已配置 webhook 觸發器
      When 外部系統呼叫 webhook "https://api.specular.ai/hook/agent-002":
        | method  | POST                         |
        | headers | {"X-Custom": "value"}        |
        | body    | {"task": "process document"} |
      Then agent_trigger_logs 表應新增一筆記錄:
        | agent_id   | agent-002                    |
        | trigger_id | (觸發器 ID)                  |
        | status     | running                      |
        | input      | {"task": "process document"} |
        | started_at | (當前時間)                   |
      And Agent 開始執行後，記錄應更新為:
        | status      | completed        |
        | output      | (Agent 執行結果) |
        | finished_at | (完成時間)       |
        | duration_ms | (執行時長毫秒)   |

    Example: 排程觸發執行記錄
      Given Agent "agent-002" 已配置 cron "0 9 * * 1-5" 排程觸發器
      When 系統排程時間到達 09:00
      Then 系統應自動觸發 Agent "agent-002"
      And agent_trigger_logs 表應新增一筆記錄:
        | agent_id     | agent-002 |
        | trigger_type | schedule  |
        | status       | running   |

    Example: 觸發執行失敗記錄
      Given Agent "agent-002" 已配置觸發器
      When 觸發器執行但 Agent 執行過程中發生錯誤
      Then agent_trigger_logs 記錄應更新為:
        | status      | failed                            |
        | error       | {"code": "...", "message": "..."} |
        | finished_at | (當前時間)                        |
  # ============================================================
  # Rule: 模式切換副作用
  # ============================================================

  Rule: 模式切換會影響相關配置與資料

    Example: Chat 切換至 Triggers - 對話 Session 處理
      Given Agent "agent-001" 的 mode 為 "chat"
      And Agent "agent-001" 有 3 個進行中的對話 session
      When 使用者 "user-001" 提交編輯請求:
        | agent_id | agent-001 |
        | mode     | triggers  |
      Then 請求應成功
      And 所有進行中的對話 session 應標記為 "closed"
      And session 的 closed_reason 應為 "agent_mode_changed"

    Example: Triggers 切換至 Chat - 觸發器處理
      Given Agent "agent-002" 的 mode 為 "triggers"
      And Agent "agent-002" 有 2 個已配置的觸發器
      When 使用者 "user-001" 提交編輯請求:
        | agent_id | agent-002 |
        | mode     | chat      |
      Then 請求應成功
      And 所有觸發器應標記為 "paused"
      And 回傳警告訊息: "2 triggers have been paused. They will resume if you switch back to triggers mode."

    Example: 切換回 Triggers - 恢復觸發器
      Given Agent "agent-002" 原本有 2 個 "paused" 狀態的觸發器
      When 使用者 "user-001" 提交編輯請求:
        | agent_id | agent-002 |
        | mode     | triggers  |
      Then 請求應成功
      And 所有 "paused" 狀態的觸發器應恢復為 "active"
  # ============================================================
  # Rule: 模式驗證
  # ============================================================

  Rule: 只允許有效的模式值

    Example: 失敗 - 無效的模式值
      When 使用者 "user-001" 提交編輯請求:
        | agent_id | agent-001    |
        | mode     | invalid_mode |
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "Invalid mode. Allowed values: 'chat', 'triggers'"
