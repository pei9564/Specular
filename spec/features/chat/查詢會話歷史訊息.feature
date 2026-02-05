Feature: 查詢會話歷史訊息
  獲取特定會話的詳細對話紀錄

  Background:
    Given 系統中存在以下會話:
      | id       | user_id  | agent_id  | status |
      | conv-001 | user-001 | agent-001 | active |
      | conv-002 | user-002 | agent-001 | active |
    And 會話 "conv-001" 有以下訊息:
      | id   | role      | content                    | created_at          | tool_calls  |
      | m-01 | user      | 你好                       | 2024-01-15 10:00:00 | null        |
      | m-02 | assistant | 你好！有什麼可以幫助你的？ | 2024-01-15 10:00:05 | null        |
      | m-03 | user      | 幫我計算 1+1               | 2024-01-15 10:01:00 | null        |
      | m-04 | assistant | 計算結果是 2               | 2024-01-15 10:01:10 | [calculate] |
      | m-05 | user      | 謝謝                       | 2024-01-15 10:02:00 | null        |
      | m-06 | assistant | 不客氣！                   | 2024-01-15 10:02:05 | null        |
    And 使用者 "user-001" 已登入
  # ============================================================
  # Rule: 查詢訊息列表
  # ============================================================

  Rule: 用戶可以查詢自己會話的歷史訊息

    Example: 成功 - 查詢所有訊息
      When 使用者發送 GET 請求至 "/api/conversations/conv-001/messages"
      Then 請求應成功，回傳狀態碼 200
      And 回傳結果應包含:
        | field | value |
        | total |     6 |
      And data 陣列應依 created_at 升序排列（最舊的在前）
      And 每筆訊息應包含以下欄位:
        | field      | type     | description            |
        | id         | string   | 訊息 UUID              |
        | role       | string   | user/assistant/system  |
        | content    | string   | 訊息內容               |
        | created_at | datetime | 建立時間               |
        | tool_calls | array    | 工具調用記錄（可為空） |

    Example: 成功 - 訊息區分角色
      When 使用者查詢會話 "conv-001" 的訊息
      Then 回傳的訊息中:
        | index | role      | content                    |
        |     0 | user      | 你好                       |
        |     1 | assistant | 你好！有什麼可以幫助你的？ |
        |     2 | user      | 幫我計算 1+1               |
        |     3 | assistant | 計算結果是 2               |

    Example: 成功 - 包含工具調用詳情
      When 使用者發送 GET 請求至 "/api/conversations/conv-001/messages":
        | include_tool_calls | true |
      Then 訊息 "m-04" 應包含 tool_calls 陣列:
        | tool_name | input                 | output        | status  |
        | calculate | {"expression": "1+1"} | {"result": 2} | success |
  # ============================================================
  # Rule: 分頁功能
  # ============================================================

  Rule: 訊息列表支援分頁

    Example: 成功 - 分頁查詢
      When 使用者發送 GET 請求至 "/api/conversations/conv-001/messages":
        | page      | 1 |
        | page_size | 2 |
      Then 請求應成功
      And 回傳結果應包含:
        | total       | 6 |
        | page        | 1 |
        | page_size   | 2 |
        | total_pages | 3 |
      And data 陣列應包含 2 筆訊息（m-01, m-02）

    Example: 成功 - 查詢最新訊息（倒序分頁）
      When 使用者發送 GET 請求至 "/api/conversations/conv-001/messages":
        | page      |    1 |
        | page_size |    2 |
        | order     | desc |
      Then data 陣列應包含最新的 2 筆訊息（m-06, m-05）

    Example: 成功 - 使用 cursor 分頁（適合無限滾動）
      When 使用者發送 GET 請求至 "/api/conversations/conv-001/messages":
        | cursor    | m-04   |
        | limit     |     10 |
        | direction | before |
      Then data 陣列應包含 m-04 之前的所有訊息（m-01, m-02, m-03）
      And 回傳應包含 next_cursor 和 has_more 欄位
  # ============================================================
  # Rule: 時間範圍篩選
  # ============================================================

  Rule: 支援依時間範圍篩選訊息

    Example: 成功 - 查詢特定時間後的訊息
      When 使用者發送 GET 請求至 "/api/conversations/conv-001/messages":
        | after | 2024-01-15T10:01:00Z |
      Then 回傳結果應只包含 created_at 在指定時間之後的訊息:
        | id   |
        | m-04 |
        | m-05 |
        | m-06 |

    Example: 成功 - 查詢特定時間範圍的訊息
      When 使用者發送 GET 請求至 "/api/conversations/conv-001/messages":
        | after  | 2024-01-15T10:00:30Z |
        | before | 2024-01-15T10:01:30Z |
      Then 回傳結果應只包含:
        | id   |
        | m-03 |
        | m-04 |
  # ============================================================
  # Rule: 權限控制
  # ============================================================

  Rule: 用戶只能查詢自己的會話訊息

    Example: 失敗 - 查詢他人會話的訊息
      When 使用者 "user-001" 發送 GET 請求至 "/api/conversations/conv-002/messages"
      Then 請求應失敗，回傳狀態碼 403
      And 錯誤訊息應為 "You do not have permission to access this conversation"

    Example: 失敗 - 會話不存在
      When 使用者發送 GET 請求至 "/api/conversations/non-existent/messages"
      Then 請求應失敗，回傳狀態碼 404
      And 錯誤訊息應為 "Conversation not found"
  # ============================================================
  # Rule: 訊息搜尋
  # ============================================================

  Rule: 支援在會話中搜尋訊息

    Example: 成功 - 關鍵字搜尋
      When 使用者發送 GET 請求至 "/api/conversations/conv-001/messages":
        | search | 計算 |
      Then 回傳結果應只包含 content 含有 "計算" 的訊息:
        | id   | content      |
        | m-03 | 幫我計算 1+1 |
        | m-04 | 計算結果是 2 |

    Example: 成功 - 依角色篩選
      When 使用者發送 GET 請求至 "/api/conversations/conv-001/messages":
        | role | user |
      Then 回傳結果應只包含 role 為 "user" 的訊息
      And total 應為 3
  # ============================================================
  # Rule: 訊息格式
  # ============================================================

  Rule: 訊息可能包含不同類型的內容

    Example: 純文字訊息
      Then 訊息 "m-01" 的結構應為:
        | field        | value |
        | id           | m-01  |
        | role         | user  |
        | content      | 你好  |
        | content_type | text  |

    Example: 包含工具調用的訊息
      Then 訊息 "m-04" 的結構應為:
        | field        | value                                        |
        | id           | m-04                                         |
        | role         | assistant                                    |
        | content      | 計算結果是 2                                 |
        | content_type | text                                         |
        | tool_calls   | [{"name": "calculate", "status": "success"}] |

    Example: 包含 Markdown 的訊息
      Given 訊息 "m-07" 的 content 為 "# 標題\n- 項目1\n- 項目2"
      When 使用者查詢訊息
      Then 訊息 "m-07" 應保留原始 Markdown 格式
      And content_type 應為 "markdown"

    Example: 包含程式碼的訊息
      Given 訊息包含程式碼區塊
      Then 訊息應保留程式碼格式和語法標示
  # ============================================================
  # Rule: 效能考量
  # ============================================================

  Rule: 大量訊息查詢應有效能保護

    Example: 限制單次查詢數量
      When 使用者發送 GET 請求至 "/api/conversations/conv-001/messages":
        | page_size | 500 |
      Then page_size 應被限制為最大值 100
      And data 陣列最多包含 100 筆訊息

    Example: 訊息內容截斷預覽
      When 使用者發送 GET 請求至 "/api/conversations/conv-001/messages":
        | preview_only | true |
      Then 每筆訊息的 content 應截斷至 200 字元
      And 超過 200 字元的訊息應標示 "truncated": true
