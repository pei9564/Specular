Feature: 發送訊息給 Agent
  與 Agent 進行即時對話交互

  Background:
    Given 系統中存在以下 Agent:
      | id        | name    | owner_id | status | mode | model_id | system_prompt      |
      | agent-001 | ChatBot | user-001 | active | chat | gpt-4o   | 你是一個友善的助手 |
    And Agent "agent-001" 已綁定以下 Skills:
      | skill_id  | function_name |
      | skill-001 | calculate     |
    And Agent "agent-001" 已綁定以下 MCP:
      | mcp_id  | tools       |
      | mcp-001 | get_weather |
    And 系統中存在以下會話:
      | id       | user_id  | agent_id  | status |
      | conv-001 | user-001 | agent-001 | active |
    And 使用者 "user-001" 已登入
  # ============================================================
  # Rule: 發送訊息（一般模式）
  # ============================================================

  Rule: 用戶可以發送訊息並接收 Agent 回應

    Example: 成功 - 發送訊息並接收回應
      Given 會話 "conv-001" 目前有 0 筆訊息
      # API: POST /api/v1/agents/{agent_id}/chat
      When 使用者發送 POST 請求至 "/api/v1/agents/agent-001/chat":
        | content | 你好，請問你是誰？ |
      Then 請求應成功，回傳狀態碼 200
      And messages 表應新增兩筆記錄:
        | id   | conversation_id | role      | content            | created_at |
        | m-01 | conv-001        | user      | 你好，請問你是誰？ | (當前時間) |
        | m-02 | conv-001        | assistant | (Agent 回應內容)   | (當前時間) |
      And conversations 表中 conv-001 應更新:
        | field           | new_value  |
        | message_count   |          2 |
        | last_message_at | (當前時間) |
        | updated_at      | (當前時間) |
      And 回傳結果應包含:
        | field   | value        |
        | id      | m-02         |
        | role    | assistant    |
        | content | (Agent 回應) |

    Example: 成功 - 訊息包含對話歷史上下文
      Given 會話 "conv-001" 已有以下訊息:
        | role      | content    |
        | user      | 我叫小明   |
        | assistant | 你好小明！ |
      # API: POST /api/v1/agents/{id}/chat
      When 使用者發送 POST 請求至 "/api/v1/agents/agent-001/chat":
        | conversation_id | conv-001             |
        | message         | 你還記得我的名字嗎？ |
      Then Agent 應能基於歷史訊息回應（含有 "小明"）
      And 發送給 LLM 的 messages 應包含完整對話歷史
  # ============================================================
  # Rule: 串流回應 (SSE)
  # ============================================================

  Rule: 支援 AGUI 標準 Server-Sent Events 串流回應

    Example: 成功 - 串流模式發送文字訊息 (AGUI Standard)
      # API: POST /api/v1/agents/{id}/chat/stream
      When 使用者發送 POST 請求至 "/api/v1/agents/agent-001/chat/stream":
        | conversation_id | conv-001 |
        | message         | 你好     |
      Then 系統應建立 SSE 連線
      And 回傳標頭應包含:
        | header        | value             |
        | Content-Type  | text/event-stream |
        | Cache-Control | no-cache          |
        | Connection    | keep-alive        |
      And 系統應依序回傳以下 AGUI 事件:
        | event              | data                                          |
        | RunStarted         | {"runId": "run-123", "threadId": "conv-001"}  |
        | TextMessageStart   | {"messageId": "msg-001", "role": "assistant"} |
        | TextMessageContent | {"messageId": "msg-001", "delta": "你"}       |
        | TextMessageContent | {"messageId": "msg-001", "delta": "好"}       |
        | TextMessageEnd     | {"messageId": "msg-001"}                      |
        | RunFinished        | {"runId": "run-123"}                          |
      And 完整回應應寫入 messages 表

    Example: 成功 - 串流模式發送工具調用訊息 (AGUI Standard)
      # API: POST /api/v1/agents/{id}/chat/stream
      When 使用者發送 POST 請求至 "/api/v1/agents/agent-001/chat/stream":
        | conversation_id | conv-001 |
        | message         | 查詢天氣 |
      Then 系統應依序回傳以下 AGUI 事件:
        | event          | data                                                              |
        | RunStarted     | {"runId": "run-124"}                                              |
        | ToolCallStart  | {"toolCallId": "call-001", "toolCallName": "get_weather"}         |
        | ToolCallArgs   | {"toolCallId": "call-001", "delta": "{\\"city\\": \\"Taipei\\"}"} |
        | ToolCallEnd    | {"toolCallId": "call-001"}                                        |
        | ToolCallResult | {"toolCallId": "call-001", "result": "25C"}                       |
        | RunFinished    | {"runId": "run-124"}                                              |

    Example: SSE 連線中斷處理
      Given 使用者開始串流請求
      When 網路連線中斷
      Then 系統應記錄中斷事件
      And 已接收的部分回應應仍寫入 messages 表
      And message 的 status 應標記為 "incomplete"

    Example: SSE 錯誤處理 (RunError)
      Given Agent 處理過程中發生錯誤
      When 系統發送錯誤事件
      Then 系統應回傳 AGUI 錯誤事件:
        | event    | data                                        |
        | RunError | {"runId": "run-125", "code": "token_limit"} |
  # ============================================================
  # Rule: 工具調用
  # ============================================================

  Rule: Agent 可以調用綁定的工具（Skills/MCP）

    Example: 成功 - Agent 調用 Skill
      # API: POST /api/v1/agents/{id}/chat
      When 使用者發送 POST 請求至 "/api/v1/agents/agent-001/chat":
        | conversation_id | conv-001             |
        | message         | 請幫我計算 123 + 456 |
      Then Agent 應調用 calculate 函數
      And tool_calls 表應新增一筆記錄:
        | field       | value                       |
        | message_id  | (assistant message id)      |
        | tool_type   | skill                       |
        | tool_name   | calculate                   |
        | input       | {"expression": "123 + 456"} |
        | output      | {"result": 579}             |
        | status      | success                     |
        | duration_ms | (執行時長)                  |
      And Agent 最終回應應包含計算結果 "579"

    Example: 成功 - Agent 調用 MCP 工具
      # API: POST /api/v1/agents/{id}/chat
      When 使用者發送 POST 請求至 "/api/v1/agents/agent-001/chat":
        | conversation_id | conv-001           |
        | message         | 台北今天天氣如何？ |
      Then Agent 應調用 get_weather 工具
      And tool_calls 表應新增一筆記錄:
        | tool_type | mcp              |
        | tool_name | get_weather      |
        | input     | {"city": "台北"} |

    Example: 工具調用失敗處理
      Given MCP Server "mcp-001" 目前無法連線
      # API: POST /api/v1/agents/{id}/chat
      When 使用者發送 POST 請求至 "/api/v1/agents/agent-001/chat":
        | conversation_id | conv-001 |
        | message         | 查詢天氣 |
      Then tool_calls 記錄的 status 應為 "failed"
      And tool_calls 記錄應包含 error 訊息
      And Agent 應回應工具調用失敗的訊息
  # ============================================================
  # Rule: 訊息驗證
  # ============================================================

  Rule: 系統應驗證訊息內容

    Example: 失敗 - 訊息內容為空
      # API: POST /api/v1/agents/{id}/chat
      When 使用者發送 POST 請求至 "/api/v1/agents/agent-001/chat":
        | conversation_id | conv-001 |
        | message         |          |
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "Message content is required"

    Example: 失敗 - 訊息過長
      # API: POST /api/v1/agents/{id}/chat
      When 使用者發送 POST 請求至 "/api/v1/agents/agent-001/chat":
        | conversation_id | conv-001            |
        | message         | (超過32000字的內容) |
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "Message content exceeds maximum length (32000 characters)"

    Example: 失敗 - 會話不存在
      # API: POST /api/v1/agents/{id}/chat
      When 使用者發送 POST 請求至 "/api/v1/agents/agent-001/chat":
        | conversation_id | non-existent |
        | message         | Hello        |
      Then 請求應失敗，回傳狀態碼 404
      And 錯誤訊息應為 "Conversation not found"

    Example: 失敗 - 會話已關閉
      Given 會話 "conv-001" 的 status 為 "archived"
      # API: POST /api/v1/agents/{id}/chat
      When 使用者發送 POST 請求至 "/api/v1/agents/agent-001/chat":
        | conversation_id | conv-001 |
        | message         | Hello    |
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "Cannot send message to archived conversation"

    Example: 失敗 - 無權存取他人會話
      Given 會話 "conv-001" 的 user_id 為 "user-002"
      # API: POST /api/v1/agents/{id}/chat
      When 使用者發送 POST 請求至 "/api/v1/agents/agent-001/chat":
        | conversation_id | conv-001 |
        | message         | Hello    |
      Then 請求應失敗，回傳狀態碼 403
  # ============================================================
  # Rule: 並發控制
  # ============================================================

  Rule: 同一會話同時只能有一個進行中的請求

    Example: 失敗 - 會話正在處理中
      Given 會話 "conv-001" 目前有一個進行中的訊息請求
      # API: POST /api/v1/agents/{id}/chat
      When 使用者發送 POST 請求至 "/api/v1/agents/agent-001/chat":
        | conversation_id | conv-001       |
        | message         | Are you there? |
      Then 請求應失敗，回傳狀態碼 409
      And 錯誤訊息應為 "A message is already being processed in this conversation. Please wait."
  # ============================================================
  # Rule: Token 使用量追蹤
  # ============================================================

  Rule: 系統應追蹤每次對話的 Token 使用量

    Example: 記錄 Token 使用量
      # API: POST /api/v1/agents/{id}/chat
      When 使用者發送 POST 請求至 "/api/v1/agents/agent-001/chat":
        | conversation_id | conv-001 |
        | message         | Hello    |
      Then messages 表中 assistant 訊息應包含:
        | field             | value        |
        | prompt_tokens     | (輸入 token) |
        | completion_tokens | (輸出 token) |
        | total_tokens      | (總計 token) |
      And token_usage 表應新增一筆記錄:
        | field             | value        |
        | user_id           | user-001     |
        | agent_id          | agent-001    |
        | model_id          | gpt-4o       |
        | prompt_tokens     | (輸入 token) |
        | completion_tokens | (輸出 token) |
        | created_at        | (當前時間)   |
  # ============================================================
  # Rule: 錯誤處理
  # ============================================================

  Rule: LLM 呼叫失敗時應正確處理

    Example: LLM API 逾時
      Given LLM API 回應超過 60 秒
      # API: POST /api/v1/agents/{id}/chat
      When 使用者發送 POST 請求至 "/api/v1/agents/agent-001/chat":
        | conversation_id | conv-001 |
        | message         | Hello    |
      Then 請求應失敗，回傳狀態碼 504
      And 錯誤訊息應為 "LLM request timed out. Please try again."
      And user 訊息仍應寫入 messages 表
      And 應新增一筆 error message:
        | role    | system            |
        | content | Request timed out |
        | type    | error             |

    Example: LLM API 回傳錯誤
      Given LLM API 回傳 500 錯誤
      # API: POST /api/v1/agents/{id}/chat
      When 使用者發送 POST 請求至 "/api/v1/agents/agent-001/chat":
        | conversation_id | conv-001 |
        | message         | Hello    |
      Then 請求應失敗，回傳狀態碼 502
      And 錯誤訊息應為 "LLM service error. Please try again later."

    Example: Rate Limit 超過
      Given 使用者在 1 分鐘內發送超過 60 則訊息
      # API: POST /api/v1/agents/{id}/chat
      When 使用者發送 POST 請求至 "/api/v1/agents/agent-001/chat":
        | conversation_id | conv-001 |
        | message         | Hello    |
      Then 請求應失敗，回傳狀態碼 429
      And 錯誤訊息應為 "Rate limit exceeded. Please slow down."
      And 回傳標頭應包含 "Retry-After"
