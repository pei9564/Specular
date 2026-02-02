Feature: 上下文組裝策略 (Context Assembly Strategy)

  Rule: 根據 STM 設定與 Token 限制組裝 Prompt

    Example: 根據 STM 設定截取歷史訊息
      Given Aggregate: Chat Topic 有 20 則歷史訊息
      And Config: STM (message_window) = 5
      And Context: 最後 5 則訊息總長度未超過 Token 上限
      When Command: 使用者執行 SubmitChatMessage (發送訊息)
        """
        Explain that again.
        """
      Then Event: 系統應發出 Chat_Context_Assembled 事件
      And Payload: messages 列表長度應為 7
      And Payload: 包含 System Prompt, 最近 5 則歷史, 與新訊息
      And Aggregate: Chat Topic 歷史訊息總數應更新為 21

    Example: 使用 One-shot 模式 (STM=0)
      Given Aggregate: Chat Topic 有 20 則歷史訊息
      And Config: 使用者剛將 STM 更新為 0
      When Command: 使用者執行 SubmitChatMessage (發送訊息)
        """
        Translate this.
        """
      Then Event: 系統應發出 Chat_Context_Assembled 事件
      And Payload: messages 列表長度應為 2
      And Aggregate: Chat Topic 歷史訊息總數應更新為 21

    Example: 歷史訊息超過 Token 上限時自動截斷 (FIFO 策略)
      Given Aggregate: Chat Topic 設定 STM=50
      And Context: 最近 50 則訊息的總 Token 數超過當前模型上限
      When Command: 使用者執行 SubmitChatMessage (發送訊息)
      Then Event: 系統應發出 Chat_Context_Assembled 事件
      And Payload: messages 列表應僅包含 STM 範圍內的部分訊息
      And Payload: 系統應優先移除該範圍內「最舊」的訊息 (FIFO)，直到總 Token 數 <= 模型上限
      And Payload: System Prompt 必須始終保留，不參與截斷

    Example: 拒絕發送空訊息 (後端防護)
      Given Context: 使用者輸入內容為 "   " (空白字元)
      When Command: 使用者執行 SubmitChatMessage
      Then Return: 系統應回傳 Error "Invalid Request"
      And Aggregate: Chat Session 不應新增該訊息

  Rule: 敏感操作前的檢查點驗證 (Human-in-the-loop Checkpoint)
    # HITL Rule - 對於具有副作用的工具 (Side-effect Tools)，在執行前需暫停並徵求使用者同意

    Example: 執行敏感工具前觸發 Checkpoint
      Given Aggregate: Agent 決定呼叫 "delete_database" 工具 (標記為敏感操作)
      When Command: LLM 產生 Tool Call 請求
      Then Event: 系統應發出 Interaction_Checkpoint_Reached 事件
      And Action: 流程應暫停 (Status: Paused)，等待使用者確認
      And Payload: 應包含 "Approve" 與 "Reject" 選項

    Example: 使用者批准執行 (Resume Flow)
      Given Aggregate: 當前流程處於 "Paused" 狀態 (Checkpoint: tool_confirmation)
      When Command: 使用者發送 "Approve" 指令
      Then Action: 系統應執行該工具 (delete_database)
      And Event: 系統應發出 Tool_Execution_Started 事件
      And Aggregate: 流程狀態應恢復為 "Running"

    Example: 使用者拒絕執行 (Abort Flow)
      Given Aggregate: 當前流程處於 "Paused" 狀態
      When Command: 使用者發送 "Reject" 指令
      Then Action: 系統應攔截該工具呼叫，並回傳 "User rejected execution" 給 LLM
      And Event: 系統應發出 Tool_Execution_Rejected 事件
      And Aggregate: LLM 應接收到拒絕訊息並嘗試生成新的回應 (如道歉或替代方案)
