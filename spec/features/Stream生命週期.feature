Feature: 串流生命週期與可靠性 (Stream Lifecycle & Reliability)

  Rule: 處理 LLM 串流回應與中斷

    Example: 成功觸發並完成串流回應
      Given Chat_Context_Assembled 已成功發生
      And Payload: 包含合法的 messages 列表
      When 系統執行 TriggerInference (觸發推論)
      Then 系統應發出 Response_Stream_Started
      And 系統應持續發送 Stream Chunk (內容片段) 給前端
      And 最終應發出 Response_Stream_Finalized

    Example: 串流途中發生連線異常
      Given Response_Stream_Started 已發生
      But 在傳輸過程中，上游 LLM 服務連線中斷 (Connection Reset)
      When 系統偵測到 Stream Error
      Then 系統應發出 Response_Stream_Failed
      And Chat Session 應新增一條 Role="System" 的錯誤提示訊息

  Rule: 針對 LLM 邏輯錯誤提供細分回饋

    Example: 觸發內容安全性攔截 (Content Filter)
      Given TriggerInference 已執行
      When 上游 LLM 回傳內容安全錯誤
      Then 系統應發出 Response_Stream_Failed
      And Return: 錯誤訊息「內容涉及敏感資訊，無法生成」

    Example: 觸發對話長度限制 (Context Limit)
      Given TriggerInference 已執行
      When 上游 LLM 回傳 Token Limit 錯誤
      Then Return: 錯誤訊息「單次訊息過長，請嘗試縮減內容或重置對話」

    Example: API 配額超限 (Quota Exceeded)
      Given TriggerInference 已執行
      When 上游 LLM 回傳 Quota Exceeded 錯誤
      Then Return: 錯誤訊息「系統資源繁忙，請稍後再試」

  Rule: 前端中斷對話應立即中止後端推論

    Example: 使用者主動中斷串流連線 (Client Abort)
      Given Response_Stream_Started 已發生
      When 使用者關閉瀏覽器或主動中斷連線
      Then 系統應立即中止與上游 LLM 的請求
      And 系統應發出 Response_Stream_Aborted
      And 該次未完成的回應不應存入 Chat Session 歷史紀錄
      And Audit Log 應記錄截至中斷前已生成的內容與 Token 消耗量
