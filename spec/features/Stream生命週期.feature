Feature: 串流生命週期與可靠性 (Stream Lifecycle & Reliability - AGUI Protocol)

  Background: AGUI 核心概念
    Given 系統遵循 AGUI (Agent User Interaction Protocol) 標準
    And 使用 PascalCase 作為事件命名慣例
    And ID 映射關係如下：
      | 原欄位名稱   | AGUI 欄位名稱 | 對應資料表欄位         |
      | trace_id     | runId         | AuditLog.trace_id      |
      | thread_id    | threadId      | ChatThread.thread_id   |
      | message_id   | messageId     | ChatMessage.message_id |
      | tool_call_id | toolCallId    | (事件專用)             |

  Rule: Run 生命週期事件 (Run Lifecycle)

    Example: 成功觸發並完成 Run（完整事件序列）
      Given Chat_Context_Assembled 已成功發生
      And Payload: 包含合法的 messages 列表
      When 系統執行 TriggerInference (觸發推論)
      Then 系統應透過 SSE 發出 event: "RunStarted"
      And data 應包含 { "runId": "run-abc123", "threadId": "thread-xyz789", "timestamp": "2026-02-03T14:30:05Z" }
      And 系統應持續發送文字訊息事件序列
      And 最終應發出 event: "RunFinished"
      And data 應包含 { "runId": "run-abc123", "threadId": "thread-xyz789", "usage": { "total_tokens": 350 } }

    Example: 驗證 RunStarted 事件資料完整性
      Given 系統準備開始新的推論
      When 發送 RunStarted 事件
      Then data 必須包含 runId (string)
      And data 必須包含 threadId (string)
      And data 必須包含 timestamp (ISO8601 格式)
      And data 可選包含 input (object, 觸發此 run 的輸入)

    Example: 驗證 RunFinished 事件的完整性
      Given Run 已完成所有內容生成與工具執行
      When 發送 RunFinished 事件
      Then data 必須包含 runId (string)
      And data 必須包含 threadId (string)
      And data 應包含 usage.total_tokens (number)
      And 前端應停止 Loading 狀態並關閉 SSE 連線

  Rule: 文字訊息生命週期 (Text Message Lifecycle)

    Example: 完整的文字訊息串流（Start → Content → End）
      Given RunStarted 已發出
      When Agent 準備輸出一段文字訊息
      Then 系統應發出 event: "TextMessageStart"
      And data 應包含 { "messageId": "msg-001", "role": "assistant", "timestamp": "..." }
      And 系統應持續發送 event: "TextMessageContent"
      And 每個 Content 的 data 應為 { "messageId": "msg-001", "delta": "量子" }
      And 最終應發出 event: "TextMessageEnd"
      And End 事件的 data 應包含 { "messageId": "msg-001", "timestamp": "..." }

    Example: 驗證 TextMessageStart 事件
      Given Run 正在進行中
      When Agent 決定生成新的訊息
      Then 應發出 TextMessageStart 事件
      And data 必須包含 messageId (唯一識別)
      And data 必須包含 role (值為 "assistant" 或 "system")
      And 前端應建立新的對話氣泡

    Example: 驗證 TextMessageContent 使用 delta 而非 content
      Given TextMessageStart 已發出
      When 系統串流傳輸文字片段
      Then 每個 TextMessageContent 事件應包含 delta 欄位
      And delta 欄位為 string 類型
      And 前端應將 delta 累加至訊息氣泡
      And 不再使用 index 欄位（依賴 SSE 順序性）

    Example: 驗證 TextMessageEnd 標記訊息結束
      Given 所有文字片段已傳輸完畢
      When 發送 TextMessageEnd 事件
      Then data 必須包含 messageId
      And 前端應結束游標閃爍或 Loading 動畫
      And 該訊息進入 finalized 狀態

  Rule: 工具調用生命週期 (Tool Call Lifecycle - AGUI Enhanced)

    Example: 完整的工具調用流程（Start → Args → End → Result）
      Given RunStarted 已發出
      And Agent 決定調用工具 "search_arxiv"
      When 系統開始處理工具調用
      Then 系統應發出 event: "ToolCallStart"
      And data 應包含 { "toolCallId": "call-xyz", "toolCallName": "search_arxiv", "parentMessageId": "msg-001" }
      And 系統應串流發送 event: "ToolCallArgs"
      And Args 事件的 data 應為 { "toolCallId": "call-xyz", "delta": "{\"query\"" }
      When 參數傳輸完畢
      Then 應發出 event: "ToolCallEnd"
      And data 應包含 { "toolCallId": "call-xyz" }
      When 工具執行完成
      Then 應發出 event: "ToolCallResult"
      And data 應包含 { "toolCallId": "call-xyz", "result": {...}, "isError": false }

    Example: 工具參數串流 (Streaming Tool Arguments)
      Given ToolCallStart 已發出
      When 工具參數為長 JSON 或複雜內容
      Then 系統可分多次發送 ToolCallArgs 事件
      And 每次傳輸一段 delta
      And 前端應累加 delta 以還原完整參數
      And 此功能對生成程式碼類工具特別有用

    Example: 單次對話中執行多個工具 (Multi-Tool Chain)
      Given RunStarted 已發出
      And Agent 依序呼叫兩個工具
      When 執行第一個工具 "search_database"
      Then 應依序發出：ToolCallStart → ToolCallArgs → ToolCallEnd → ToolCallResult
      When 執行第二個工具 "summarize_results"
      Then 應依序發出：ToolCallStart → ToolCallArgs → ToolCallEnd → ToolCallResult
      And 最終 Agent 繼續生成文字回應並發送 RunFinished

    Example: 工具執行結果包含錯誤狀態
      Given 工具執行過程中發生錯誤（如 API 超時）
      When 發送 ToolCallResult 事件
      Then data 應包含 { "toolCallId": "call-xyz", "result": {...}, "isError": true }
      And result 中應包含錯誤訊息
      And Agent 可選擇繼續推論或終止

  Rule: 錯誤處理統一為 RunError (Error Handling)

    Example: 觸發 Token Limit 錯誤
      Given Run 正在進行中
      When 上游 LLM 回傳 Token Limit 錯誤
      Then 系統應發出 event: "RunError"
      And data 應包含 { "runId": "run-abc123", "code": "token_limit", "message": "單次訊息過長，請嘗試縮減內容" }
      And 系統不應存入任何 ChatMessage
      And Audit Log 應記錄該錯誤

    Example: 觸發內容安全性攔截 (Content Filter)
      Given Run 正在進行中
      When 上游 LLM 回傳內容安全錯誤
      Then 系統應發出 event: "RunError"
      And data 應包含 { "code": "content_filter", "message": "內容涉及敏感資訊，無法生成" }

    Example: API 配額超限 (Quota Exceeded)
      Given Run 正在進行中
      When 上游 LLM 回傳 Quota Exceeded 錯誤
      Then 系統應發出 event: "RunError"
      And data 應包含 { "code": "quota_exceeded", "message": "系統資源繁忙，請稍後再試" }

    Example: 連線中斷 (Connection Lost)
      Given Run 正在進行中
      When 與上游 LLM 服務連線中斷
      Then 系統應發出 event: "RunError"
      And data 應包含 { "code": "connection_lost", "message": "與上游 LLM 服務連線中斷" }
      And ChatThread 應新增一條 Role="System" 的錯誤提示訊息

    Example: 使用已停用的模型 (Model Inactive)
      Given Chat Topic 使用的 LLM 狀態為 "Inactive"
      When 系統執行 TriggerInference
      Then 系統應在 Run 開始前返回錯誤
      And 應發出 event: "RunError"
      And data 應包含 { "code": "model_inactive", "message": "所選模型已停用，請聯絡管理員" }

    Example: 使用者主動中斷 (Client Abort)
      Given Run 正在進行中
      When 使用者關閉瀏覽器或主動中斷 SSE 連線
      Then 系統應發出 event: "RunError"
      And data 應包含 { "code": "aborted", "message": "使用者主動中斷" }
      And 系統應立即中止與上游 LLM 的請求
      And 該次未完成的回應不應存入 ChatThread 歷史紀錄
      And Audit Log 應記錄截至中斷前已生成的內容與 Token 消耗量

    Example: 驗證所有 error code 的值必須來自預定義清單
      Given 系統發生任何錯誤
      When 發送 RunError 事件
      Then code 的值必須為以下之一：
        | error_code      |
        | token_limit     |
        | content_filter  |
        | quota_exceeded  |
        | connection_lost |
        | model_inactive  |
        | aborted         |
      And 不允許使用未定義的 error code

  Rule: 完整事件序列範例 (Event Sequences)

    Example: 正常回答（無工具）
      Given 使用者詢問一般問題
      When 系統執行推論
      Then 事件序列應為：
        """
        RunStarted         → { runId: "run-1" }
        TextMessageStart   → { messageId: "msg-1", role: "assistant" }
        TextMessageContent → { messageId: "msg-1", delta: "你好" }
        TextMessageContent → { messageId: "msg-1", delta: "，" }
        TextMessageContent → { messageId: "msg-1", delta: "請問" }
        TextMessageEnd     → { messageId: "msg-1" }
        RunFinished        → { runId: "run-1" }
        """

    Example: 包含工具呼叫（Tool Usage）
      Given 使用者詢問需要查詢資料的問題
      When Agent 決定使用工具
      Then 事件序列應為：
        """
        RunStarted         → { runId: "run-2" }
        
        ToolCallStart      → { toolCallId: "call-1", toolCallName: "Weather" }
        ToolCallArgs       → { toolCallId: "call-1", delta: "{\"city\"" }
        ToolCallArgs       → { toolCallId: "call-1", delta: ":\"Taipei\"}" }
        ToolCallEnd        → { toolCallId: "call-1" }
        ToolCallResult     → { toolCallId: "call-1", result: "25°C", isError: false }
        
        TextMessageStart   → { messageId: "msg-2", role: "assistant" }
        TextMessageContent → { messageId: "msg-2", delta: "台北現在" }
        TextMessageContent → { messageId: "msg-2", delta: "25度" }
        TextMessageEnd     → { messageId: "msg-2" }
        
        RunFinished        → { runId: "run-2" }
        """

    Example: 工具執行期間使用者中斷
      Given ToolCallStart 已發出
      And 工具正在執行中
      When 使用者中斷 SSE 連線
      Then 系統應立即中止工具執行
      And 不應發出 ToolCallResult 事件
      And 應發出 event: "RunError"
      And data 應包含 { "code": "aborted", "message": "使用者主動中斷" }
      And Audit Log 應記錄工具執行被中斷

  Rule: AGUI 事件 ID 的唯一性與追蹤 (Event Tracking)

    Example: 每個 SSE 事件應包含唯一的 event id
      Given Run 正在進行中
      When 系統發送任何 SSE 事件
      Then 每個事件應包含唯一的 id 欄位（如 "evt-001"）
      And id 應遞增或使用 UUID 格式
      And 前端可透過 event.lastEventId 取得

    Example: 使用 runId 關聯同一次推論的所有事件
      Given 系統開始一次新的推論
      Then RunStarted 事件應包含 runId
      And 所有後續事件（TextMessage*, ToolCall*, RunFinished, RunError）應共享相同的 runId
      And Audit Log 應使用此 runId 記錄完整推論過程

    Example: 使用 threadId 關聯同一對話串的所有 Runs
      Given 使用者開啟一個 Chat Topic
      Then 該 Topic 對應唯一的 threadId
      And 所有在此 Topic 內的 Runs 應共享相同的 threadId
      And 前端可透過 threadId 查詢完整對話歷史
