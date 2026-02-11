Feature: 發送訊息給 Agent
  與 Agent 進行即時對話交互

  Background:
    Given Agent "ChatBot" (id: agent-001) 處於 active 狀態
    # Clarification 2026-02-10: Skills are out-of-scope for MVP; only MCP tools are supported.
    And 該 Agent 綁定了 MCP 工具 (get_weather)
    And 使用者 "user-001" 已建立與該 Agent 的會話 "conv-001"

  Rule: 用戶可以發送訊息並接收 Agent 回應

    Example: 成功 - 發送訊息並接收回應
      When 使用者在會話 "conv-001" 發送訊息 "你好，請問你是誰？"
      Then 系統應接收訊息並觸發 Agent 處理
      And messages 表應新增:
        | role      | content            |
        | user      | 你好，請問你是誰？ |
        | assistant | (Agent 回應內容)   |
      And conversations 表的 message_count 應增加
      And conversations 表的 updated_at 應更新

    Example: 成功 - 訊息包含對話歷史上下文
      Given 會話已有歷史訊息 "我叫小明"
      When 使用者發送訊息 "你還記得我的名字嗎？"
      Then Agent 應能讀取歷史訊息並正確回應
      And 發送給 LLM 的 context 應包含完整對話歷史

  Rule: 支援 AGUI 標準 Server-Sent Events 串流回應

    Example: 成功 - 串流模式發送文字訊息
      When 使用者以串流模式發送訊息 "你好"
      Then 系統應建立 SSE 連線
      And 系統應依序回傳符合 AGUI 標準的事件:
        | event              |
        | RunStarted         |
        | TextMessageStart   |
        | TextMessageContent |
        | TextMessageEnd     |
        | RunFinished        |
      And 完整回應後，messages 表應儲存完整訊息內容

    Example: 成功 - 串流模式發送工具調用訊息
      When 使用者以串流模式發送訊息 "查詢天氣"
      Then 系統應回傳 AGUI 工具調用事件:
        | event          |
        | RunStarted     |
        | ToolCallStart  |
        | ToolCallArgs   |
        | ToolCallEnd    |
        | ToolCallResult |
        | RunFinished    |

    Example: SSE 連線中斷處理
      When 串流過程中連線中斷
      Then 系統應標記該次訊息狀態為 "incomplete"

    Example: SSE 錯誤處理 (RunError)
      When Agent 處理發生錯誤
      Then 系統應回傳 RunError 事件

  Rule: Agent 可以調用綁定的工具（Skills/MCP）

    Example: 成功 - Agent 調用 MCP 工具
      When 使用者請求 "台北今天天氣如何？"
      Then Agent 應調用 MCP 工具 get_weather
      And tool_calls 表應記錄調用細節

    Example: 工具調用失敗處理
      Given MCP 工具無法連線
      When 使用者請求使用該工具
      Then tool_calls 表應記錄 status 為 "failed"
      And Agent 應告知使用者工具調用失敗

  Rule: 系統應驗證訊息內容

    Example: 失敗 - 訊息內容為空
      When 使用者發送空訊息
      Then 發送應失敗並提示內容不能為空

    Example: 失敗 - 訊息過長
      When 使用者發送超過長度限制的訊息
      Then 發送應失敗

    Example: 失敗 - 會話不存在或已關閉
      When 使用者嘗試對無效會話發送訊息
      Then 發送應失敗

  Rule: 並發控制

    Example: 失敗 - 會話正在處理中
      Given 會話目前有進行中的訊息處理
      When 使用者嘗試發送新訊息
      Then 發送應失敗，提示需等待前一訊息處理完成

  Rule: 系統應追蹤每次對話的 Token 使用量

    Example: 記錄 Token 使用量
      When 對話完成
      Then messages 表應記錄 prompt_tokens 與 completion_tokens
      And token_usage 表應新增使用量記錄

  Rule: LLM 呼叫失敗時應正確處理

    Example: LLM API 逾時或錯誤
      When LLM 服務回應逾時或錯誤
      Then 系統應回傳適當的錯誤訊息給使用者
      And 錯誤應被記錄以便除錯
