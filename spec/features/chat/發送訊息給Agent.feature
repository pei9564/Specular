Feature: 發送訊息給 Agent
  # 與 Agent 進行即時對話交互

  Rule: 發送訊息給 Agent 的核心邏輯
    # 定義 發送訊息給 Agent 的相關規則與行為

    Example: 發送訊息並接收串流回應 (SSE)
      When 用戶向 "/agents/{id}/chat/stream" 發送 POST 請求
      Then 系統應建立 SSE 連線
      And 逐字回傳 Agent 的回應 (Stream Mode)
      And 對話內容應被儲存至資料庫

    Example: 對話歷史持久化
      When 對話結束
      Then 系統應確保 User 和 Agent 的訊息都已寫入 Message 表
