Feature: 對話紀錄存取 (Chat History Access)
  Rule: 查詢對話歷史紀錄
    Example: 載入已存在的對話視窗
      Given Aggregate: Chat Topic (ID: topic-101) 包含 20 則歷史訊息
        And Config: STM (message_window) 設定為 5
      When Query: 執行 GetChatHistory (取得對話歷史)
        With arguments: topic_id="topic-101"
      Then Read Model: 應回傳包含 20 則訊息的清單
        And Metadata: 應標示 current_stm_setting = 5