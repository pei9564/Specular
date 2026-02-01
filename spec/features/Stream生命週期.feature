Feature: 串流生命週期與可靠性 (Stream Lifecycle & Reliability)
  Rule: 處理 LLM 串流回應與中斷
    Example: 成功觸發並完成串流回應
      Given Event: Chat_Context_Assembled 已成功發生
        And Payload: 包含合法的 messages 列表
      When Command: 系統執行 TriggerInference (觸發推論)
      Then Event: 系統應發出 Response_Stream_Started
      And Event: 系統應持續發送 Stream Chunk (內容片段) 給前端
      And Event: 最終應發出 Response_Stream_Finalized
    Example: 串流途中發生連線異常
      Given Event: Response_Stream_Started 已發生
      But Event: 在傳輸過程中，上游 LLM 服務連線中斷 (Connection Reset)
      When Command: 系統偵測到 Stream Error
      Then Event: 系統應發出 Response_Stream_Failed
      And Aggregate: Chat Session 應新增一條 Role="System" 的錯誤提示訊息