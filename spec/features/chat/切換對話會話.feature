Feature: 切換對話會話
  在不同會話間切換

  Background:
    Given 系統中存在以下會話:
      | id       | user_id  | agent_id  | title        | status   | message_count |
      | conv-001 | user-001 | agent-001 | Math Chat    | active   |            10 |
      | conv-002 | user-001 | agent-001 | Code Help    | active   |             5 |
      | conv-003 | user-001 | agent-002 | Task Discuss | active   |             3 |
      | conv-004 | user-001 | agent-001 | Old Chat     | archived |            20 |
      | conv-005 | user-002 | agent-001 | Other User   | active   |             8 |
    And 使用者 "user-001" 已登入
  # ============================================================
  # Rule: 取得單一會話詳情
  # ============================================================

  Rule: 用戶可以取得特定會話的詳細資訊

    Example: 成功 - 取得會話詳情
      When 使用者發送 GET 請求至 "/api/conversations/conv-001"
      Then 請求應成功，回傳狀態碼 200
      And 回傳結果應包含:
        | field         | value     |
        | id            | conv-001  |
        | user_id       | user-001  |
        | agent_id      | agent-001 |
        | title         | Math Chat |
        | status        | active    |
        | message_count |        10 |
      And 回傳結果應包含 agent 摘要資訊:
        | field      | value        |
        | agent_name | (Agent 名稱) |
        | agent_mode | chat         |

    Example: 成功 - 取得會話並載入最近訊息
      When 使用者發送 GET 請求至 "/api/conversations/conv-001":
        | include_messages | true |
        | message_limit    |   20 |
      Then 回傳結果應包含 messages 陣列
      And messages 應包含最近 20 筆訊息（或全部，若不足 20 筆）
      And messages 應依 created_at 升序排列

    Example: 失敗 - 會話不存在
      When 使用者發送 GET 請求至 "/api/conversations/non-existent"
      Then 請求應失敗，回傳狀態碼 404
      And 錯誤訊息應為 "Conversation not found"

    Example: 失敗 - 無權存取他人會話
      When 使用者 "user-001" 發送 GET 請求至 "/api/conversations/conv-005"
      Then 請求應失敗，回傳狀態碼 403
      And 錯誤訊息應為 "You do not have permission to access this conversation"
  # ============================================================
  # Rule: 切換會話上下文
  # ============================================================

  Rule: 前端可標記當前活躍會話

    Example: 成功 - 設定當前活躍會話
      When 使用者發送 POST 請求至 "/api/conversations/conv-002/activate"
      Then 請求應成功，回傳狀態碼 200
      And user_preferences 表應更新:
        | user_id             | user-001   |
        | active_conversation | conv-002   |
        | updated_at          | (當前時間) |

    Example: 成功 - 切換到不同會話
      Given 使用者當前活躍會話為 "conv-001"
      When 使用者發送 POST 請求至 "/api/conversations/conv-002/activate"
      Then 請求應成功
      And user_preferences 的 active_conversation 應更新為 "conv-002"

    Example: 成功 - 查詢當前活躍會話
      Given user_preferences 中 active_conversation 為 "conv-001"
      When 使用者發送 GET 請求至 "/api/user/preferences"
      Then 回傳結果應包含:
        | field               | value    |
        | active_conversation | conv-001 |

    Example: 失敗 - 無法切換到不存在的會話
      When 使用者發送 POST 請求至 "/api/conversations/non-existent/activate"
      Then 請求應失敗，回傳狀態碼 404

    Example: 失敗 - 無法切換到他人會話
      When 使用者 "user-001" 發送 POST 請求至 "/api/conversations/conv-005/activate"
      Then 請求應失敗，回傳狀態碼 403
  # ============================================================
  # Rule: 切換到已封存會話
  # ============================================================

  Rule: 切換到已封存會話時應有適當提示

    Example: 成功 - 切換到已封存會話（唯讀模式）
      When 使用者發送 GET 請求至 "/api/conversations/conv-004"
      Then 請求應成功
      And 回傳結果應包含:
        | field     | value    |
        | status    | archived |
        | read_only | true     |

    Example: 警告 - 嘗試切換到已封存會話
      When 使用者發送 POST 請求至 "/api/conversations/conv-004/activate"
      Then 請求應成功
      And 回傳應包含警告:
        | warning | This conversation is archived and read-only |
  # ============================================================
  # Rule: 會話狀態更新
  # ============================================================

  Rule: 切換會話時應更新存取記錄

    Example: 記錄會話存取時間
      When 使用者發送 GET 請求至 "/api/conversations/conv-001"
      Then conversations 表中 conv-001 應更新:
        | field            | new_value  |
        | last_accessed_at | (當前時間) |

    Example: 更新會話排序權重
      Given 使用者存取會話順序為: conv-002, conv-001, conv-003
      When 使用者查詢會話列表，依最近存取排序
      Then 回傳結果應依 last_accessed_at 降序排列:
        | order | id       |
        |     1 | conv-003 |
        |     2 | conv-001 |
        |     3 | conv-002 |
  # ============================================================
  # Rule: 會話恢復
  # ============================================================

  Rule: 重新登入後應恢復上次的會話狀態

    Example: 恢復上次活躍會話
      Given user_preferences 中 active_conversation 為 "conv-001"
      When 使用者重新登入
      And 使用者發送 GET 請求至 "/api/user/preferences"
      Then 回傳應包含上次活躍的會話 ID
      And 前端可據此自動載入該會話

    Example: 上次活躍會話已刪除時的處理
      Given user_preferences 中 active_conversation 為 "deleted-conv"
      And 會話 "deleted-conv" 已被刪除
      When 使用者發送 GET 請求至 "/api/user/preferences"
      Then active_conversation 應為 null
      And 前端應顯示會話列表讓用戶選擇
  # ============================================================
  # Rule: 快速切換
  # ============================================================

  Rule: 支援快速切換最近會話

    Example: 取得最近使用的會話列表
      When 使用者發送 GET 請求至 "/api/conversations/recent":
        | limit | 5 |
      Then 請求應成功
      And 回傳結果應包含最近存取的 5 個會話
      And 會話應依 last_accessed_at 降序排列
      And 每個會話應包含摘要資訊（不含完整訊息）

    Example: 取得與特定 Agent 的最近會話
      When 使用者發送 GET 請求至 "/api/conversations/recent":
        | agent_id | agent-001 |
        | limit    |         3 |
      Then 回傳結果應只包含與 agent-001 的會話
      And 最多回傳 3 筆
