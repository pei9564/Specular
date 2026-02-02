Feature: Topic 查詢與內容讀取 (Topic Inquiry & Access)

  Rule: 進入 Topic 時應同時獲取運行配置與對話歷史
    # 這是使用者點擊對話視窗時的主要 API，應完整返回「我在用什麼模型」以及「我們之前聊了什麼」。

    Example: 載入一個已存在的對話主題
      Given Aggregate: 存在一筆對話主題 Topic "Math-101"
      And Config: 生效模型為 "gpt-4o", 源自 Agent "MathGuru"
      And Session: 當前活躍場次 (Active Session) 包含 5 則歷史訊息
      When Query: 執行 GetTopicDetails，參數如下：
        | topic_id | Math-101 |
      Then Read Model: 應回傳配置摘要：
        | field        | value                         |
        | current_llm  | gpt-4o                        |
        | source_agent | MathGuru                      |
        | active_tools | [tool_calc_v1] (繼承自 Agent) |
      And Read Model: 應回傳該 Session 的 5 則對話紀錄清單
      And Metadata: 應包含當前 STM (message_window) 與 Token 使用統計 (僅總量)

  Rule: 僅能讀取當前活躍場次的歷史 (Session Isolation)
    # 基於「重置對話」規則，舊的場次不應出現在主畫面的查詢結果中，確保對話視窗的純淨。

    Example: 載入包含對話內容的活躍 Session
      Given Aggregate: Topic "News-Analysis" 當前 Session 有以下訊息：
        | Role      | Content                       |
        | User      | 幫我總結今天的科技頭條        |
        | Assistant | 今天的熱門話題包含 AI 發展... |
      When Query: 執行 GetTopicDetails (ID: News-Analysis)
      Then Read Model: 應回傳 2 則訊息紀錄
      And Read Model: 第一則應為 User 訊息，內容包含 "科技頭條"
      And Read Model: 第二則應為 Assistant 訊息，內容包含 "AI 發展"

    Example: 在重置後的 Topic 中查詢，不應看到舊訊息
      Given Aggregate: Topic "Support-99" 執行過 ClearChatTopic
      And Aggregate: 舊場次 Session "sess-old" 包含訊息 "我的電腦壞了"
      And Aggregate: 新場次 Session "sess-new" 目前為空 (Active)
      When Query: 執行 GetTopicDetails (ID: Support-99)
      Then Read Model: 對話紀錄清單應為空 (Empty List)
      And Check: 結果中絕對不應出現 "我的電腦壞了" 這則舊訊息
