Feature: Topic 查詢與內容讀取 (Topic Inquiry & Access)

  Rule: 進入 Topic 時應同時獲取運行配置與對話歷史
    # 這是使用者點擊對話視窗時的主要 API，應完整返回「我在用什麼模型」以及「我們之前聊了什麼」。

    Example: 載入一個已存在的對話主題
      Given 存在一筆對話主題 Topic "Math-101"
      And Config: 生效模型為 "gpt-4o", 源自 Agent "MathGuru"
      And Session: 當前活躍場次 (Active Session) 包含 5 則歷史訊息
      When 執行 GetTopicDetails，參數如下：
        | topic_id | Math-101 |
      Then 應回傳配置摘要：
        | field        | value                         |
        | current_llm  | gpt-4o                        |
        | source_agent | MathGuru                      |
        | active_tools | [tool_calc_v1] (繼承自 Agent) |
      And 應回傳該 Session 的 5 則對話紀錄清單
      And Metadata: 應包含當前 STM (message_window) 與 Token 使用統計 (僅總量)

  Rule: 僅能讀取當前活躍場次的歷史 (Session Isolation)
    # 基於「重置對話」規則，舊的場次不應出現在主畫面的查詢結果中，確保對話視窗的純淨。

    Example: 載入包含對話內容的活躍 Session
      Given Topic "News-Analysis" 當前 Session 有以下訊息：
        | Role      | Content                       |
        | User      | 幫我總結今天的科技頭條        |
        | Assistant | 今天的熱門話題包含 AI 發展... |
      When 執行 GetTopicDetails (ID: News-Analysis)
      Then 應回傳 2 則訊息紀錄
      And 第一則應為 User 訊息，內容包含 "科技頭條"
      And 第二則應為 Assistant 訊息，內容包含 "AI 發展"

    Example: 在重置後的 Topic 中查詢，不應看到舊訊息
      Given Topic "Support-99" 執行過 ClearChatTopic
      And 舊場次 Session "sess-old" 包含訊息 "我的電腦壞了"
      And 新場次 Session "sess-new" 目前為空 (Active)
      When 執行 GetTopicDetails (ID: Support-99)
      Then 對話紀錄清單應為空 (Empty List)
      And 結果中絕對不應出現 "我的電腦壞了" 這則舊訊息

  Rule: 支援大量對話主題的分頁查詢 (Cursor-based Pagination)
    # 確保在大量對話情境下仍能維持查詢效能與流暢的使用者體驗

    Example: 使用游標獲取下一頁對話主題
      Given 使用者 "u123" 擁有 100 個對話主題
      When 執行 ListUserTopics，參數如下：
        | limit  |   20 |
        | cursor | null |
      Then 應回傳前 20 筆最近建立的主題
      And 回傳結果應包含一個 `next_cursor` (最後一筆紀錄的 ID 或時間戳)

    Example: 使用 next_cursor 讀取更多主題
      Given 已獲取第一頁結果且 `next_cursor` 為 "t_020"
      When 執行 ListUserTopics，參數如下：
        | limit  |    20 |
        | cursor | t_020 |
      Then 應回傳從 "t_021" 開始的後續 20 筆主題
