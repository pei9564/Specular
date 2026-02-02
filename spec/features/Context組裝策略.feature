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

    Example: 歷史訊息超過 Token 上限時自動截斷
      Given Aggregate: Chat Topic 設定 STM=50
      And Context: 最近 50 則訊息的總 Token 數 (例如 10k) 超過模型上限 (例如 8k)
      When Command: 使用者執行 SubmitChatMessage (發送訊息)
      Then Event: 系統應發出 Chat_Context_Assembled 事件
      And Payload: messages 列表應包含「少於」50 則歷史訊息
      And Payload: 總 Token 數應 <= 8k

    Example: 拒絕發送空訊息 (後端防護)
      Given Context: 使用者輸入內容為 "   " (空白字元)
      When Command: 使用者執行 SubmitChatMessage
      Then Return: 系統應回傳 Error "Invalid Request"
      And Aggregate: Chat Session 不應新增該訊息
