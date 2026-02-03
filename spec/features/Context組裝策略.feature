Feature: 上下文組裝策略 (Context Assembly Strategy)

  Rule: 根據 STM 設定與 Token 限制組裝 Prompt

    Example: 根據 STM 設定截取歷史訊息
      Given 存在 Chat Topic "MathTopic" 綁定 Agent "MathGuru"
      And Agent "MathGuru" 配置：LLM="gpt-4o", Tools=["Calculator"]
      And Chat Topic "MathTopic" 目前有 20 則歷史訊息且設定 STM=5
      And 最後 5 則訊息總長度未超過 Token 上限
      When 使用者在 "MathTopic" 執行 SubmitChatMessage (發送訊息)
      Then 系統應發出 Chat_Context_Assembled 事件
      And 初始化之 Graph State 應包含：
        | Key      | Value (Runtime Source)                        |
        | messages | System Prompt (from MathGuru) + 最近 5 則歷史 |
        | config   | { "llm": "gpt-4o", "tools": ["Calculator"] }  |
      And messages 列表長度應為 7 (System + 5 History + 1 New)
      And Chat Topic 歷史訊息總數應更新為 21

    Example: 使用 One-shot 模式 (STM=0)
      Given 存在 Chat Topic "MathTopic" 綁定 Agent "MathGuru"
      And Agent "MathGuru" 配置：LLM="gpt-4o", Tools=["Calculator"]
      And Chat Topic "MathTopic" 目前有 20 則歷史訊息且設定 STM=0
      When 使用者在 "MathTopic" 執行 SubmitChatMessage (發送訊息)
      Then 系統應發出 Chat_Context_Assembled 事件
      And 組裝之 Graph State 應包含：
        | Key      | Value                                     |
        | messages | System Prompt + 新訊息 (BaseMessage 列表) |
        | config   | { "llm": "...", "tools": [...] }          |
      And messages 列表長度應為 2
      And Chat Topic 歷史訊息總數應更新為 21

    Example: 歷史訊息超過 Token 上限時自動截斷 (FIFO 策略)
      Given 存在 Chat Topic "LongTopic" 綁定 Agent "Researcher" (LLM="gpt-4", STM=50)
      And 最近 50 則訊息的總 Token 數超過 gpt-4 的模型上限
      When 使用者在 "LongTopic" 執行 SubmitChatMessage (發送訊息)
      Then 系統應發出 Chat_Context_Assembled 事件
      And 初始化之 Graph State 應包含：
        | Key      | Value                                              |
        | messages | 包含 System Prompt 且總 Token 數 <= 模型上限的訊息 |
        | config   | 從 Agent "Researcher" 讀取之最新模型與工具配置     |
      And 系統應優先移除該範圍內「最舊」的訊息 (FIFO)，直到總 Token 數 <= 模型上限
      And System Prompt (from Researcher) 必須始終保留，不參與截斷

    Example: 拒絕發送空訊息 (後端防護)
      Given 使用者輸入內容為 "   " (空白字元)
      When 使用者執行 SubmitChatMessage
      Then 系統應回傳 Error "Invalid Request"
      And Chat Session 不應新增該訊息

  Rule: 敏感操作前的檢查點驗證 (Human-in-the-loop Checkpoint)
    # HITL Rule - 對於具有副作用的工具 (Side-effect Tools)，在執行前需暫停並徵求使用者同意

    Example: 執行敏感工具前觸發 Checkpoint
      Given Agent 決定呼叫 "delete_database" 工具 (標記為敏感操作)
      When LLM 產生 Tool Call 請求
      Then 系統應發出 Interaction_Checkpoint_Reached 事件
      And 流程應暫停 (Status: Paused)，等待使用者確認
      And 應包含 "Approve" 與 "Reject" 選項

    Example: 使用者批准執行 (Resume Flow)
      Given 當前流程處於 "Paused" 狀態 (Checkpoint: tool_confirmation)
      When 使用者發送 "Approve" 指令
      Then 系統應執行該工具 (delete_database)
      And 系統應發出 Tool_Execution_Started 事件
      And 流程狀態應恢復為 "Running"

    Example: 使用者拒絕執行 (Abort Flow)
      Given 當前流程處於 "Paused" 狀態
      When 使用者發送 "Reject" 指令
      Then 系統應攔截該工具呼叫，並回傳 "User rejected execution" 給 LLM
      And 系統應發出 Tool_Execution_Rejected 事件
      And LLM 應接收到拒絕訊息並嘗試生成新的回應 (如道歉或替代方案)

  Rule: 運行時解耦組裝 (LangGraph State Mapping)
    # 確保對話時才動態拉取各組件配置，並映射為 LangGraph 所需的輸入格式

    Example: 執行 SubmitChatMessage 時的組裝邏輯
      Given Chat Topic "Topic-1" 僅記錄 agent_id="MathGuru"
      And Agent "MathGuru" 當前綁定 LLM="gpt-4o" 且 Tools=["Calculator"]
      When 使用者在 "Topic-1" 發送訊息
      Then 系統應即時抓取最新配置並初始化 LangGraph State：
      And 啟動 LangGraph 執行，不產生資料表冗餘記錄
      And 即使工具實例 (Calculator) 的名稱或配置變更，下一次 Graph 執行時會自動抓取最新配置內容
