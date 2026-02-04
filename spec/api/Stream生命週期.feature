Feature: 串流生命週期與可靠性 (Stream Lifecycle & Reliability - AGUI Protocol)
  # 本 Feature 定義基於 AGUI (Agent User Interaction Protocol) 的 SSE 串流協議，包含事件生命週期、錯誤處理與追蹤機制

  Background: AGUI 核心概念
    Given 系統遵循 AGUI (Agent User Interaction Protocol) 標準
    And 使用 PascalCase 作為事件命名慣例
    And ID 映射關係如下, in table "id_mapping":
      | 原欄位名稱   | AGUI 欄位名稱 | 對應資料表欄位       |
      | trace_id     | runId         | audit_logs.trace_id  |
      | thread_id    | threadId      | chat_threads.id      |
      | message_id   | messageId     | chat_messages.id     |
      | tool_call_id | toolCallId    | (事件專用，不持久化) |

  Rule: Run 生命週期事件 (Run Lifecycle)
    # Run 代表一次完整的推論過程，從開始到結束

    Example: 成功觸發並完成 Run（完整事件序列）
      # 測試目標：驗證完整 Run 的 SSE 事件序列
      Given Chat Context 已成功組裝, with data:
        | threadId  | topicId   | messageCount | totalTokens |
        | thread_01 | topic_001 |           10 |        2500 |
      When 執行 API "SubmitChatMessage", triggering inference:
        | endpoint                  | method | bodyParams                                    |
        | /api/topics/{id}/messages | POST   | { topicId: "topic_001", message: "Hello AI" } |
      Then 系統應透過 SSE 發送事件序列:
        | eventType          | eventData                                                                         | order |
        | RunStarted         | { runId: "run-abc123", threadId: "thread_01", timestamp: "2026-02-04T00:00:00Z" } |     1 |
        | TextMessageStart   | { messageId: "msg-001", role: "assistant", timestamp: "..." }                     |     2 |
        | TextMessageContent | { messageId: "msg-001", delta: "Hello" }                                          |     3 |
        | TextMessageContent | { messageId: "msg-001", delta: " there" }                                         |     4 |
        | TextMessageEnd     | { messageId: "msg-001", timestamp: "..." }                                        |     5 |
        | RunFinished        | { runId: "run-abc123", threadId: "thread_01", usage: { total_tokens: 350 } }      |     6 |
      And 資料庫 table "audit_logs" 應記錄:
        | traceId    | threadId  | status   | totalTokens | createdAt           |
        | run-abc123 | thread_01 | FINISHED |         350 | 2026-02-04T00:00:00 |
      And 資料庫 table "chat_messages" 應新增助理回應:
        | id      | threadId  | role      | content     | createdAt           |
        | msg-001 | thread_01 | ASSISTANT | Hello there | 2026-02-04T00:00:00 |

    Example: 驗證 RunStarted 事件資料完整性
      # 測試目標：驗證 RunStarted 事件的必要欄位
      Given 系統準備開始新的推論, with context:
        | threadId  | userId | topicId   |
        | thread_02 | u_001  | topic_002 |
      When 發送 SSE event "RunStarted"
      Then event data 必須包含以下欄位:
        | field     | type   | required | example              |
        | runId     | string | true     | run-xyz456           |
        | threadId  | string | true     | thread_02            |
        | timestamp | string | true     | 2026-02-04T00:00:00Z |
        | input     | object | false    | { message: "Hello" } |

    Example: 驗證 RunFinished 事件的完整性
      # 測試目標：驗證 RunFinished 事件標記推論結束
      Given Run 已完成所有內容生成, with data:
        | runId      | totalTokens | duration |
        | run-def789 |         450 |     3.5s |
      When 發送 SSE event "RunFinished"
      Then event data 必須包含:
        | field                   | type   | required | description   |
        | runId                   | string | true     | 推論 ID       |
        | threadId                | string | true     | 線程 ID       |
        | usage.total_tokens      | number | true     | Token 使用量  |
        | usage.prompt_tokens     | number | false    | 提示 Token 數 |
        | usage.completion_tokens | number | false    | 生成 Token 數 |
      And 前端應停止 Loading 狀態並關閉 SSE 連線

  Rule: 文字訊息生命週期 (Text Message Lifecycle)
    # 文字訊息分為 Start → Content → End 三階段

    Example: 完整的文字訊息串流（Start → Content → End）
      # 測試目標：驗證文字訊息的完整生命週期
      Given RunStarted 已發出, with runId="run-001"
      When Agent 準備輸出文字訊息
      Then 系統應發送 SSE 事件序列:
        | eventType          | eventData                                                     | order |
        | TextMessageStart   | { messageId: "msg-111", role: "assistant", timestamp: "..." } |     1 |
        | TextMessageContent | { messageId: "msg-111", delta: "量子" }                       |     2 |
        | TextMessageContent | { messageId: "msg-111", delta: "計算" }                       |     3 |
        | TextMessageContent | { messageId: "msg-111", delta: "是" }                         |     4 |
        | TextMessageEnd     | { messageId: "msg-111", timestamp: "..." }                    |     5 |
      And 前端應累加所有 delta 值形成完整訊息: "量子計算是"

    Example: 驗證 TextMessageContent 使用 delta 而非 content
      # 測試目標：驗證增量傳輸的欄位命名
      Given TextMessageStart 已發出, with messageId="msg-222"
      When 系統串流傳輸文字片段
      Then 每個 SSE event "TextMessageContent" 應包含:
        | field     | type   | required | description  |
        | messageId | string | true     | 訊息 ID      |
        | delta     | string | true     | 文字增量片段 |
      And 不再使用 index 欄位（依賴 SSE 順序性）
      And 前端應將 delta 累加至訊息氣泡

    Example: 驗證 TextMessageEnd 標記訊息結束
      # 測試目標：驗證訊息結束標記
      Given 所有文字片段已傳輸完畢, with messageId="msg-333"
      When 發送 SSE event "TextMessageEnd"
      Then event data 必須包含:
        | field     | type   | required |
        | messageId | string | true     |
        | timestamp | string | true     |
      And 前端應結束游標閃爍或 Loading 動畫
      And 該訊息進入 finalized 狀態

  Rule: 工具調用生命週期 (Tool Call Lifecycle - AGUI Enhanced)
    # 工具調用分為 Start → Args → End → Result 四階段

    Example: 完整的工具調用流程（Start → Args → End → Result）
      # 測試目標：驗證工具調用的完整生命週期
      Given RunStarted 已發出, with runId="run-tool-001"
      And Agent 決定調用工具 "search_arxiv"
      When 系統開始處理工具調用
      Then 系統應發送 SSE 事件序列:
        | eventType      | eventData                                                                            | order |
        | ToolCallStart  | { toolCallId: "call-xyz", toolCallName: "search_arxiv", parentMessageId: "msg-001" } |     1 |
        | ToolCallArgs   | { toolCallId: "call-xyz", delta: "{\\"query\\"" }                                    |     2 |
        | ToolCallArgs   | { toolCallId: "call-xyz", delta: ": \\"quantum computing\\"}" }                      |     3 |
        | ToolCallEnd    | { toolCallId: "call-xyz" }                                                           |     4 |
        | ToolCallResult | { toolCallId: "call-xyz", result: { papers: [...] }, isError: false }                |     5 |
      And 前端應累加 ToolCallArgs 的 delta 還原完整參數: {"query": "quantum computing"}

    Example: 單次對話中執行多個工具 (Multi-Tool Chain)
      # 測試目標：驗證多工具調用的事件序列
      Given RunStarted 已發出, with runId="run-multi-tool"
      And Agent 依序呼叫兩個工具
      When 執行第一個工具 "search_database"
      Then 應依序發出 SSE 事件:
        | eventType      | toolCallId | order |
        | ToolCallStart  | call-db    |     1 |
        | ToolCallArgs   | call-db    |     2 |
        | ToolCallEnd    | call-db    |     3 |
        | ToolCallResult | call-db    |     4 |
      When 執行第二個工具 "summarize_results"
      Then 應依序發出 SSE 事件:
        | eventType      | toolCallId   | order |
        | ToolCallStart  | call-summary |     5 |
        | ToolCallArgs   | call-summary |     6 |
        | ToolCallEnd    | call-summary |     7 |
        | ToolCallResult | call-summary |     8 |
      And 最終 Agent 繼續生成文字回應並發送 RunFinished

    Example: 工具執行結果包含錯誤狀態
      # 測試目標：驗證工具執行錯誤的處理
      Given 工具執行過程中發生錯誤:
        | toolCallId | toolName | errorType | errorMessage |
        | call-err   | Weather  | TIMEOUT   | API timeout  |
      When 發送 SSE event "ToolCallResult"
      Then event data 應包含:
        | field      | value                    | type    |
        | toolCallId | call-err                 | string  |
        | result     | { error: "API timeout" } | object  |
        | isError    | true                     | boolean |
      And Agent 可選擇繼續推論或終止

  Rule: 錯誤處理統一為 RunError (Error Handling)
    # 所有錯誤統一使用 RunError 事件，並使用預定義的 error code

    Example: 觸發 Token Limit 錯誤
      # 測試目標：驗證 Token 超限錯誤的處理
      Given Run 正在進行中, with runId="run-err-001"
      And 上游 LLM 回傳 Token Limit 錯誤
      When 系統捕獲該錯誤
      Then 系統應發送 SSE event "RunError", with data:
        | field   | value                        | type   |
        | runId   | run-err-001                  | string |
        | code    | token_limit                  | string |
        | message | 單次訊息過長，請嘗試縮減內容 | string |
      And 資料庫 table "chat_messages" 不應新增任何訊息
      And 資料庫 table "audit_logs" 應記錄錯誤:
        | traceId     | status | errorCode   | errorMessage                 |
        | run-err-001 | ERROR  | token_limit | 單次訊息過長，請嘗試縮減內容 |

    Example: 觸發內容安全性攔截 (Content Filter)
      # 測試目標：驗證內容過濾錯誤的處理
      Given Run 正在進行中, with runId="run-err-002"
      And 上游 LLM 回傳內容安全錯誤
      When 系統捕獲該錯誤
      Then 系統應發送 SSE event "RunError", with data:
        | field   | value                      | type   |
        | runId   | run-err-002                | string |
        | code    | content_filter             | string |
        | message | 內容涉及敏感資訊，無法生成 | string |

    Example: 使用者主動中斷 (Client Abort)
      # 測試目標：驗證使用者中斷的處理
      Given Run 正在進行中, with runId="run-abort"
      And TextMessageContent 事件正在發送中
      When 使用者關閉瀏覽器或主動中斷 SSE 連線
      Then 系統應立即中止與上游 LLM 的請求
      And 系統應發送 SSE event "RunError", with data:
        | field   | value          | type   |
        | runId   | run-abort      | string |
        | code    | aborted        | string |
        | message | 使用者主動中斷 | string |
      And 資料庫 table "chat_messages" 不應保存未完成的訊息
      And 資料庫 table "audit_logs" 應記錄中斷事件:
        | traceId   | status  | errorCode | partialContent  | tokensUsed |
        | run-abort | ABORTED | aborted   | "Hello ther..." |        120 |

    Example: 驗證所有 error code 的值必須來自預定義清單
      # 測試目標：驗證錯誤碼的規範性
      Given 系統發生任何錯誤
      When 發送 SSE event "RunError"
      Then code 的值必須為以下之一, from table "error_codes":
        | error_code      | description        |
        | token_limit     | Token 超過模型上限 |
        | content_filter  | 內容安全過濾       |
        | quota_exceeded  | API 配額超限       |
        | connection_lost | 連線中斷           |
        | model_inactive  | 模型已停用         |
        | aborted         | 使用者主動中斷     |
      And 不允許使用未定義的 error code

  Rule: 完整事件序列範例 (Event Sequences)
    # 提供常見場景的事件序列參考

    Example: 正常回答（無工具）
      # 測試目標：驗證最簡單的問答流程
      Given 使用者詢問一般問題: "你好嗎？"
      When 系統執行推論
      Then SSE 事件序列應為:
        ```
        event: RunStarted
        data: { "runId": "run-1", "threadId": "thread-1", "timestamp": "..." }
        
        event: TextMessageStart
        data: { "messageId": "msg-1", "role": "assistant", "timestamp": "..." }
        
        event: TextMessageContent
        data: { "messageId": "msg-1", "delta": "我很" }
        
        event: TextMessageContent
        data: { "messageId": "msg-1", "delta": "好" }
        
        event: TextMessageContent
        data: { "messageId": "msg-1", "delta": "，謝謝" }
        
        event: TextMessageEnd
        data: { "messageId": "msg-1", "timestamp": "..." }
        
        event: RunFinished
        data: { "runId": "run-1", "threadId": "thread-1", "usage": { "total_tokens": 85 } }
        ```

    Example: 包含工具呼叫（Tool Usage）
      # 測試目標：驗證工具調用場景的事件序列
      Given 使用者詢問需要查詢資料的問題: "台北現在天氣如何？"
      When Agent 決定使用工具 "Weather"
      Then SSE 事件序列應為:
        ```
        event: RunStarted
        data: { "runId": "run-2", "threadId": "thread-2" }
        
        event: ToolCallStart
        data: { "toolCallId": "call-1", "toolCallName": "Weather", "parentMessageId": null }
        
        event: ToolCallArgs
        data: { "toolCallId": "call-1", "delta": "{\"city\"" }
        
        event: ToolCallArgs
        data: { "toolCallId": "call-1", "delta": ":\"Taipei\"}" }
        
        event: ToolCallEnd
        data: { "toolCallId": "call-1" }
        
        event: ToolCallResult
        data: { "toolCallId": "call-1", "result": "25°C, 晴天", "isError": false }
        
        event: TextMessageStart
        data: { "messageId": "msg-2", "role": "assistant" }
        
        event: TextMessageContent
        data: { "messageId": "msg-2", "delta": "台北現在" }
        
        event: TextMessageContent
        data: { "messageId": "msg-2", "delta": "25度，晴天" }
        
        event: TextMessageEnd
        data: { "messageId": "msg-2" }
        
        event: RunFinished
        data: { "runId": "run-2", "usage": { "total_tokens": 150 } }
        ```

  Rule: AGUI 事件 ID 的唯一性與追蹤 (Event Tracking)
    # 確保所有事件都能被追蹤與關聯

    Example: 使用 runId 關聯同一次推論的所有事件
      # 測試目標：驗證 runId 的一致性
      Given 系統開始一次新的推論
      When 發送 SSE event "RunStarted", generating runId="run-track-001"
      Then 所有後續事件應共享相同的 runId:
        | eventType          | runId         |
        | RunStarted         | run-track-001 |
        | TextMessageStart   | (implicit)    |
        | TextMessageContent | (implicit)    |
        | TextMessageEnd     | (implicit)    |
        | RunFinished        | run-track-001 |
      And 資料庫 table "audit_logs" 應使用此 runId 記錄完整推論過程

    Example: 使用 threadId 關聯同一對話串的所有 Runs
      # 測試目標：驗證 threadId 的一致性
      Given 使用者開啟一個 Chat Topic, creating threadId="thread-persist"
      When 使用者發送第一則訊息, triggering runId="run-1"
      And 使用者發送第二則訊息, triggering runId="run-2"
      And 使用者發送第三則訊息, triggering runId="run-3"
      Then 所有 Runs 應共享相同的 threadId:
        | runId | threadId       |
        | run-1 | thread-persist |
        | run-2 | thread-persist |
        | run-3 | thread-persist |
      And 前端可透過 threadId 查詢完整對話歷史
