Feature: 創建對話會話
  管理與 Agent 的對話 Context

  Background:
    Given 系統中存在以下 Agent:
      | id        | name        | owner_id | status   | mode     | visibility |
      | agent-001 | ChatBot     | user-001 | active   | chat     | public     |
      | agent-002 | TaskBot     | user-001 | active   | triggers | public     |
      | agent-003 | PrivateBot  | user-002 | active   | chat     | private    |
      | agent-004 | DraftBot    | user-001 | draft    | chat     | public     |
      | agent-005 | InactiveBot | user-001 | inactive | chat     | public     |
    And 系統中存在以下用戶:
      | id       | email             | role |
      | user-001 | user@example.com  | user |
      | user-002 | other@example.com | user |
    And 使用者 "user-001" 已登入
  # ============================================================
  # Rule: 創建新會話
  # ============================================================

  Rule: 用戶可以與可用的 Agent 創建新對話會話

    Example: 成功 - 創建新會話
      Given conversations 表中 user_id 為 "user-001" 且 agent_id 為 "agent-001" 的會話數為 0
      # API: POST /api/v1/agents/{id}/conversations
      When 使用者發送 POST 請求至 "/api/v1/agents/agent-001/conversations":
        | title | Math Questions |
      Then 請求應成功，回傳狀態碼 201
      And conversations 表應新增一筆記錄:
        | field           | value           |
        | id              | (自動生成 UUID) |
        | user_id         | user-001        |
        | agent_id        | agent-001       |
        | title           | Math Questions  |
        | status          | active          |
        | created_at      | (當前時間)      |
        | updated_at      | (當前時間)      |
        | message_count   |               0 |
        | last_message_at | null            |
      And 回傳結果應包含:
        | field    | value          |
        | id       | (會話 UUID)    |
        | agent_id | agent-001      |
        | title    | Math Questions |
        | status   | active         |

    Example: 成功 - 未指定 title 時自動生成
      # API: POST /api/v1/agents/{id}/conversations
      When 使用者發送 POST 請求至 "/api/v1/agents/agent-001/conversations"
      Then 請求應成功
      And 新會話的 title 應為 "New conversation with ChatBot"

    Example: 成功 - 與同一 Agent 創建多個會話
      Given 使用者已有與 Agent "agent-001" 的會話:
        | id       | title      |
        | conv-001 | First Chat |
      # API: POST /api/v1/agents/{id}/conversations
      When 使用者發送 POST 請求至 "/api/v1/agents/agent-001/conversations":
        | title | Second Chat |
      Then 請求應成功
      And conversations 表中 user_id 為 "user-001" 且 agent_id 為 "agent-001" 的記錄數應為 2

    Example: 成功 - 與公開 Agent 創建會話（非擁有者）
      Given Agent "agent-001" 的 visibility 為 "public"
      And Agent "agent-001" 的 owner_id 為 "user-001"
      Given 使用者 "user-002" 已登入
      # API: POST /api/v1/agents/{id}/conversations
      When 使用者發送 POST 請求至 "/api/v1/agents/agent-001/conversations"
      Then 請求應成功
      And 新會話的 user_id 應為 "user-002"
  # ============================================================
  # Rule: Agent 可用性檢查
  # ============================================================

  Rule: 只能與可對話的 Agent 創建會話

    Example: 失敗 - Agent 不存在
      # API: POST /api/v1/agents/{id}/conversations
      When 使用者發送 POST 請求至 "/api/v1/agents/non-existent-agent/conversations"
      Then 請求應失敗，回傳狀態碼 404
      And 錯誤訊息應為 "Agent 'non-existent-agent' not found"

    Example: 失敗 - Agent 為 triggers 模式
      # API: POST /api/v1/agents/{id}/conversations
      When 使用者發送 POST 請求至 "/api/v1/agents/agent-002/conversations"
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "Agent 'TaskBot' is in triggers mode and does not support chat conversations"

    Example: 失敗 - Agent 為 draft 狀態
      # API: POST /api/v1/agents/{id}/conversations
      When 使用者發送 POST 請求至 "/api/v1/agents/agent-004/conversations"
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "Agent 'DraftBot' is not active (status: draft)"

    Example: 失敗 - Agent 為 inactive 狀態
      # API: POST /api/v1/agents/{id}/conversations
      When 使用者發送 POST 請求至 "/api/v1/agents/agent-005/conversations"
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "Agent 'InactiveBot' is not active (status: inactive)"

    Example: 失敗 - 無權存取 private Agent
      Given 使用者 "user-001" 已登入
      # API: POST /api/v1/agents/{id}/conversations
      When 使用者發送 POST 請求至 "/api/v1/agents/agent-003/conversations"
      Then 請求應失敗，回傳狀態碼 403
      And 錯誤訊息應為 "You do not have permission to access this agent"
  # ============================================================
  # Rule: 會話數量限制
  # ============================================================

  Rule: 系統對用戶的會話數量有上限限制

    Example: 失敗 - 超過會話數量上限
      Given 使用者 "user-001" 已有 100 個 active 會話（達到上限）
      # API: POST /api/v1/agents/{id}/conversations
      When 使用者發送 POST 請求至 "/api/v1/agents/agent-001/conversations"
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "Maximum conversation limit reached (100). Please delete some conversations first."
  # ============================================================
  # Rule: 查詢會話列表
  # ============================================================

  Rule: 用戶可以查詢自己的會話列表

    Example: 成功 - 查詢所有會話
      Given 使用者 "user-001" 有以下會話:
        | id       | agent_id  | title    | status   | updated_at          |
        | conv-001 | agent-001 | Chat 1   | active   | 2024-01-15 10:00:00 |
        | conv-002 | agent-001 | Chat 2   | active   | 2024-01-14 09:00:00 |
        | conv-003 | agent-001 | Archived | archived | 2024-01-10 08:00:00 |
      # API: GET /api/v1/agents/{id}/conversations
      When 使用者發送 GET 請求至 "/api/v1/agents/agent-001/conversations"
      Then 請求應成功
      And 回傳結果應包含:
        | total | 3 |
      And data 應依 updated_at 降序排列
      And 每筆會話應包含:
        | field           | type     |
        | id              | string   |
        | agent_id        | string   |
        | agent_name      | string   |
        | title           | string   |
        | status          | string   |
        | message_count   | number   |
        | last_message_at | datetime |
        | created_at      | datetime |
        | updated_at      | datetime |

    Example: 成功 - 依狀態篩選
      Given 使用者有 2 個 active 會話和 1 個 archived 會話
      # API: GET /api/v1/agents/{id}/conversations
      When 使用者發送 GET 請求至 "/api/v1/agents/agent-001/conversations":
        | status | active |
      Then 回傳結果的 total 應為 2
      And 所有回傳的會話 status 應為 "active"

    Example: 成功 - 依 Agent 篩選
      # API: GET /api/v1/agents/{id}/conversations
      When 使用者發送 GET 請求至 "/api/v1/agents/agent-001/conversations":
      Then 回傳結果應只包含與 agent-001 的會話

    Example: 成功 - 關鍵字搜尋（title）
      # API: GET /api/v1/agents/{id}/conversations
      When 使用者發送 GET 請求至 "/api/v1/agents/agent-001/conversations":
        | search | Math |
      Then 回傳結果應包含 title 含有 "Math" 的會話

    Example: 只能查詢自己的會話
      Given 使用者 "user-002" 有會話 "conv-other"
      # API: GET /api/v1/agents/{id}/conversations
      When 使用者 "user-001" 發送 GET 請求至 "/api/v1/agents/agent-001/conversations"
      Then 回傳結果不應包含 "conv-other"
  # ============================================================
  # Rule: 分頁功能
  # ============================================================

  Rule: 會話列表支援分頁

    Example: 成功 - 分頁查詢
      Given 使用者有 25 個會話
      # API: GET /api/v1/agents/{id}/conversations
      When 使用者發送 GET 請求至 "/api/v1/agents/agent-001/conversations":
        | page      |  2 |
        | page_size | 10 |
      Then 請求應成功
      And 回傳結果應包含:
        | total       | 25 |
        | page        |  2 |
        | page_size   | 10 |
        | total_pages |  3 |
      And data 陣列應包含 10 筆會話
  # ============================================================
  # Rule: 會話預覽
  # ============================================================

  Rule: 會話列表可包含最後訊息預覽

    Example: 成功 - 包含最後訊息預覽
      Given 會話 "conv-001" 有以下訊息:
        | id   | role      | content                 | created_at          |
        | m-01 | user      | Hello                   | 2024-01-15 10:00:00 |
        | m-02 | assistant | Hi! How can I help you? | 2024-01-15 10:00:05 |
      # API: GET /api/v1/agents/{id}/conversations
      When 使用者發送 GET 請求至 "/api/v1/agents/agent-001/conversations":
        | include_preview | true |
      Then 回傳的會話 "conv-001" 應包含:
        | field                | value                   |
        | last_message_preview | Hi! How can I help you? |
        | last_message_role    | assistant               |
