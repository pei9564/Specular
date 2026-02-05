Feature: 查詢 Agent 工具調用紀錄
  監控 Agent 運行狀態與工具使用情況，包含輸入輸出與成本分析

  Background:
    Given 系統已累積以下工具調用紀錄:
      | id      | agent_id  | tool_name   | status  | duration_ms | created_at          | cost_tokens |
      | call-01 | agent-001 | web_search  | success |        1500 | 2024-02-05 10:00:00 |          50 |
      | call-02 | agent-001 | calculate   | success |         100 | 2024-02-05 10:05:00 |          10 |
      | call-03 | agent-002 | weather_api | error   |         500 | 2024-02-05 11:00:00 |           5 |
      | call-04 | agent-001 | web_search  | success |        1200 | 2024-02-05 11:30:00 |          60 |
    And 使用者 "user-001" 為 "agent-001" 的擁有者
    And 使用者 "admin-001" 為系統管理員
  # ============================================================
  # Rule: 查詢調用歷史
  # ============================================================

  Rule: 用戶可查詢自己 Agent 的工具調用詳細紀錄

    Example: 成功 - 查詢特定 Agent 的所有調用
      Given 使用者 "user-001" 已登入
      When 查詢 "agent-001" 的工具調用紀錄
      Then 回傳結果應包含 3 筆資料 (call-01, call-02, call-04)
      And 每筆記錄應顯示:
        | field       |
        | tool_name   |
        | inputs      |
        | outputs     |
        | status      |
        | duration_ms |

    Example: 成功 - 依工具名稱篩選
      When 查詢 "agent-001" 且 tool_name="web_search"
      Then 回傳結果應包含 2 筆資料 (call-01, call-04)

    Example: 成功 - 依執行狀態篩選
      When 查詢 "agent-002" 且 status="error"
      Then 回傳結果應包含 1 筆資料 (call-03)
      And 應顯示錯誤訊息 (error_message)
  # ============================================================
  # Rule: 詳細輸入輸出檢視
  # ============================================================

  Rule: 支援檢視單次調用的完整 Payload，但在敏感資料時需遮蔽

    Example: 檢視完整輸入輸出
      When 使用者檢視 "call-01" 的詳細資訊
      Then 應回傳完整 JSON 資料:
        | field   | value                                   |
        | inputs  | {"query": "Latest AI news"}             |
        | outputs | {"results": ["News 1...", "News 2..."]} |

    Example: 敏感資料遮蔽
      Given 工具定義中標記 "api_key" 參數為敏感資料
      When 使用者檢視包含該參數的調用紀錄
      Then inputs 中的 "api_key" 值應顯示為 "sk-***"
  # ============================================================
  # Rule: 權限控制
  # ============================================================

  Rule: 僅擁有者與管理員可查看調用紀錄

    Example: 失敗 - 查詢他人 Agent
      Given 使用者 "user-001" 嘗試查詢 "agent-002" (擁用者為 user-002)
      When 發送查詢請求
      Then 請求應失敗，回傳狀態碼 403
      And 錯誤訊息為 "Permission denied"

    Example: 成功 - 管理員查詢任意 Agent
      Given 使用者 "admin-001" 已登入
      When 查詢 "agent-002" 的紀錄
      Then 請求應成功並回傳結果
  # ============================================================
  # Rule: 統計分析
  # ============================================================

  Rule: 支援聚合查詢以分析工具使用趨勢

    Example: 統計工具使用頻率
      When 查詢 "agent-001" 的工具使用分佈
      Then 應回傳:
        | tool_name  | count | avg_duration |
        | web_search |     2 |       1350ms |
        | calculate  |     1 |        100ms |
