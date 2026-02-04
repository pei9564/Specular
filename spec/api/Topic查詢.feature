Feature: Topic 查詢與內容讀取 (Topic Inquiry & Access)
  # 本 Feature 定義如何查詢對話主題與讀取對話歷史，包含配置摘要與訊息清單

  Rule: 進入 Topic 時應同時獲取運行配置與對話歷史
    # 這是使用者點擊對話視窗時的主要 API，應完整返回「我在用什麼模型」以及「我們之前聊了什麼」

    Example: 載入一個已存在的對話主題
      # 測試目標：驗證系統能返回 Topic 的完整配置與對話歷史
      Given 系統中存在以下 Topic, in table "topics":
        | id       | name     | agentId | llmId  | stmWindow | userId | status | createdAt           |
        | topic_01 | Math-101 | ag_001  | llm_01 |         5 | u_001  | ACTIVE | 2026-01-15T00:00:00 |
      And Agent 資料, in table "agents":
        | id     | name     | systemPrompt                  |
        | ag_001 | MathGuru | You are a helpful math tutor. |
      And LLM 資料, in table "llm_registry":
        | id     | modelId |
        | llm_01 | gpt-4o  |
      And Agent 綁定工具, in table "agent_tools":
        | agentId | toolInstanceId |
        | ag_001  | tool_calc_v1   |
      And 當前活躍線程資料, in table "chat_threads":
        | id    | topicId  | isActive | createdAt           |
        | th_01 | topic_01 | true     | 2026-01-15T00:00:00 |
      And 線程包含對話記錄, in table "chat_messages":
        | id   | threadId | role      | content            | createdAt           |
        | m_01 | th_01    | USER      | 幫我算 123 + 456   | 2026-01-15T10:00:00 |
        | m_02 | th_01    | ASSISTANT | 結果是 579         | 2026-01-15T10:00:05 |
        | m_03 | th_01    | USER      | 謝謝               | 2026-01-15T10:01:00 |
        | m_04 | th_01    | ASSISTANT | 不客氣             | 2026-01-15T10:01:02 |
        | m_05 | th_01    | USER      | 再幫我算 789 - 123 | 2026-01-15T10:02:00 |
      When 執行 API "GetTopicDetails", call:
        | endpoint         | method | pathParams         |
        | /api/topics/{id} | GET    | { id: "topic_01" } |
      Then 回應 HTTP 200, with data structure:
        | section  | field       | value            | type   |
        | config   | topicId     | topic_01         | string |
        | config   | name        | Math-101         | string |
        | config   | currentLlm  | gpt-4o           | string |
        | config   | sourceAgent | MathGuru         | string |
        | config   | activeTools | ["tool_calc_v1"] | array  |
        | config   | stmWindow   |                5 | number |
        | messages | count       |                5 | number |
        | metadata | tokenUsage  | { total: 1250 }  | object |
      And 回應應包含 messages 陣列，長度為 5
      And messages[0] 應為:
        | field   | value            |
        | id      | m_01             |
        | role    | USER             |
        | content | 幫我算 123 + 456 |
      And messages[4] 應為:
        | field   | value              |
        | id      | m_05               |
        | role    | USER               |
        | content | 再幫我算 789 - 123 |

  Rule: 僅能讀取當前活躍線程的歷史 (Thread Isolation)
    # 基於「重置對話」規則，舊的線程不應出現在主畫面的查詢結果中，確保對話視窗的純淨

    Example: 載入包含對話內容的活躍 Thread
      # 測試目標：驗證系統只返回活躍線程的訊息
      Given 系統中存在以下 Topic, in table "topics":
        | id       | name          | userId | status |
        | topic_02 | News-Analysis | u_001  | ACTIVE |
      And 活躍線程資料, in table "chat_threads":
        | id    | topicId  | isActive | createdAt           |
        | th_02 | topic_02 | true     | 2026-01-20T00:00:00 |
      And 線程包含對話記錄, in table "chat_messages":
        | id   | threadId | role      | content                       | sequence |
        | m_10 | th_02    | USER      | 幫我總結今天的科技頭條        |        1 |
        | m_11 | th_02    | ASSISTANT | 今天的熱門話題包含 AI 發展... |        2 |
      When 執行 API "GetTopicDetails", call:
        | endpoint         | method | pathParams         |
        | /api/topics/{id} | GET    | { id: "topic_02" } |
      Then 回應 HTTP 200, with messages array:
        | id   | role      | content                       | sequence |
        | m_10 | USER      | 幫我總結今天的科技頭條        |        1 |
        | m_11 | ASSISTANT | 今天的熱門話題包含 AI 發展... |        2 |
      And 回應的 messages 陣列長度應為 2
      And messages[0].content 應包含 "科技頭條"
      And messages[1].content 應包含 "AI 發展"

    Example: 在重置後的 Topic 中查詢，不應看到舊訊息
      # 測試目標：驗證線程隔離機制，確保舊訊息不會被返回
      Given 系統中存在以下 Topic, in table "topics":
        | id       | name       | userId | status |
        | topic_03 | Support-99 | u_001  | ACTIVE |
      And 存在舊線程（已停用）, in table "chat_threads":
        | id     | topicId  | isActive | createdAt           |
        | th_old | topic_03 | false    | 2026-01-10T00:00:00 |
      And 舊線程包含訊息, in table "chat_messages":
        | id    | threadId | role | content      |
        | m_old | th_old   | USER | 我的電腦壞了 |
      And 存在新線程（活躍）, in table "chat_threads":
        | id     | topicId  | isActive | createdAt           |
        | th_new | topic_03 | true     | 2026-01-25T00:00:00 |
      When 執行 API "GetTopicDetails", call:
        | endpoint         | method | pathParams         |
        | /api/topics/{id} | GET    | { id: "topic_03" } |
      Then 回應 HTTP 200, with messages array:
        | (empty) |
      And messages 陣列應為空 []
      And 回應結果中絕對不應出現 content="我的電腦壞了" 的訊息

  Rule: 支援大量對話主題的分頁查詢 (Cursor-based Pagination)
    # 確保在大量對話情境下仍能維持查詢效能與流暢的使用者體驗

    Example: 使用游標獲取第一頁對話主題
      # 測試目標：驗證分頁查詢的基本功能
      Given 使用者 "u_123" 擁有 100 個對話主題, in table "topics"
      When 執行 API "ListUserTopics", call:
        | endpoint    | method | queryParams                                  |
        | /api/topics | GET    | { userId: "u_123", limit: 20, cursor: null } |
      Then 回應 HTTP 200, with structure:
        | field      | type    | description                   |
        | topics     | array   | 最近建立的 20 筆主題          |
        | nextCursor | string  | 下一頁的游標（最後一筆的 ID） |
        | hasMore    | boolean | 是否還有更多資料              |
      And topics 陣列長度應為 20
      And nextCursor 應不為 null
      And hasMore 應為 true

    Example: 使用 next_cursor 讀取更多主題
      # 測試目標：驗證游標分頁的連續查詢
      Given 已獲取第一頁結果且 nextCursor="t_020"
      When 執行 API "ListUserTopics", call:
        | endpoint    | method | queryParams                                     |
        | /api/topics | GET    | { userId: "u_123", limit: 20, cursor: "t_020" } |
      Then 回應 HTTP 200, with structure:
        | field      | value               |
        | topics     | (array, length: 20) |
        | nextCursor | t_040               |
        | hasMore    | true                |
      And topics[0].id 應大於 "t_020"（從下一筆開始）

    Example: 查詢最後一頁時 hasMore 為 false
      # 測試目標：驗證分頁查詢的結束標記
      Given 使用者 "u_123" 擁有共 25 個對話主題
      And 已獲取第一頁 20 筆，nextCursor="t_020"
      When 執行 API "ListUserTopics", call:
        | endpoint    | method | queryParams                                     |
        | /api/topics | GET    | { userId: "u_123", limit: 20, cursor: "t_020" } |
      Then 回應 HTTP 200, with structure:
        | field      | value              |
        | topics     | (array, length: 5) |
        | nextCursor | null               |
        | hasMore    | false              |
      And topics 陣列長度應為 5（剩餘的主題數）
