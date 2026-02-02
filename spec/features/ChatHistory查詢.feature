Feature: 對話紀錄存取 (Chat History Access)

  Rule: 查詢活躍對話場次紀錄 (Active Session History)
    # Scope Rule - 僅回傳當前活躍 Session 的對話內容

    Example: 載入已存在的對話視窗
      Given Aggregate: Chat Topic (ID: topic-101) 當前有一個 Active Session (ID: sess_99)
      And Content: Session sess_99 包含 20 則歷史訊息
      And Config: STM (message_window) 設定為 5
      When Query: 執行 GetChatHistory (取得對話歷史)，參數如下：
        | topic_id | topic-101 |
      Then Read Model: 應回傳 Session sess_99 的該 20 則訊息
      And Metadata: 應標示 current_stm_setting = 5
      And Check: 系統不應回傳 topic-101 下已封存 (Ended) 的其他 Session 訊息
