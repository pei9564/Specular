Feature: Agent 探索與能力檢視 (Agent Discovery & Inspection)
  # 本 Feature 定義系統如何呈現與查詢 Agent 資源，包含清單查詢與單一資源的詳細檢視

  Rule: 提供 Agent 清單與基礎摘要
    # List View Rule - 讓使用者快速瀏覽系統中有哪些可用的 Agent

    Example: 查詢包含能力標籤的 Agent 清單
      # 測試目標：驗證系統能正確列出所有活躍的 Agent，並過濾掉已刪除的資源
      Given 系統中存在以下 Agent 資料, in table "agents":
        | id   | name           | status  | llmModel | tools          | description       | createdAt           |
        | ag_1 | MathGuru       | ACTIVE  | gpt-4o   | ["Calculator"] | 數學專家          | 2026-01-01T10:00:00 |
        | ag_2 | Ghost Agent    | DELETED | gpt-4o   | []             | 已刪除的代理人    | 2026-01-02T11:00:00 |
        | ag_3 | Generic Helper | ACTIVE  | null     | []             | 通用助手 (未綁定) | 2026-01-03T12:00:00 |
      When 執行 API "ListAvailableAgents", call:
        | endpoint    | method | queryParams       |
        | /api/agents | GET    | { status: ACTIVE} |
      Then 回應 HTTP 200, with table:
        | id   | name           | llmModel | tools          | description       | hasTools |
        | ag_1 | MathGuru       | gpt-4o   | ["Calculator"] | 數學專家          | true     |
        | ag_3 | Generic Helper | null     | []             | 通用助手 (未綁定) | false    |
      And 回傳清單總數應為 2
      And 回傳結果不應包含 id="ag_2" (Ghost Agent)

  Rule: 檢視單一 Agent 的完整詳細規格
    # Detail View Rule - 當使用者點擊特定 Agent 時，顯示完整的 Prompt、配置與能力細節

    Example: 檢視具備完整能力的 Agent 詳情
      # 測試目標：驗證系統能返回 Agent 的完整配置，包括 System Prompt、LLM 資訊與工具清單
      Given 系統中存在以下 Agent 資料, in table "agents":
        | id   | name     | status | llmModel | llmContextWindow | systemPrompt                                               | createdAt           |
        | ag_1 | MathGuru | ACTIVE | gpt-4o   |           128000 | You are a helpful math tutor. Use python for complex calc. | 2026-01-01T10:00:00 |
      And Agent "ag_1" 綁定以下工具, in table "agent_tools":
        | agentId | toolName        | toolType | enabled |
        | ag_1    | Calculator      | BUILT_IN | true    |
        | ag_1    | CodeInterpreter | BUILT_IN | true    |
      When 執行 API "GetAgentDetails", call:
        | endpoint         | method | pathParams     |
        | /api/agents/{id} | GET    | { id: "ag_1" } |
      Then 回應 HTTP 200, with data:
        | field            | value                                                      | type   |
        | id               | ag_1                                                       | string |
        | name             | MathGuru                                                   | string |
        | status           | ACTIVE                                                     | string |
        | systemPrompt     | You are a helpful math tutor. Use python for complex calc. | string |
        | llmModel         | gpt-4o                                                     | string |
        | llmContextWindow |                                                     128000 | number |
        | tools            | ["Calculator", "CodeInterpreter"]                          | array  |
        | createdAt        |                                        2026-01-01T10:00:00 | string |
      And 應包含欄位 "systemPrompt" 且值不為空
      And 應包含欄位 "tools" 且陣列長度為 2
      And tools 陣列應包含 "Calculator" 與 "CodeInterpreter"

    Example: 檢視未綁定模型的通用 Agent 詳情
      # 測試目標：驗證系統能正確處理未綁定 LLM 的 Agent，並提示使用者需在對話時指定模型
      Given 系統中存在以下 Agent 資料, in table "agents":
        | id   | name           | status | llmModel | systemPrompt                 | createdAt           |
        | ag_3 | Generic Helper | ACTIVE | null     | You are a helpful assistant. | 2026-01-03T12:00:00 |
      And Agent "ag_3" 沒有綁定任何工具, in table "agent_tools":
        | (empty) |
      When 執行 API "GetAgentDetails", call:
        | endpoint         | method | pathParams     |
        | /api/agents/{id} | GET    | { id: "ag_3" } |
      Then 回應 HTTP 200, with data:
        | field        | value                        | type   | nullable |
        | id           | ag_3                         | string | false    |
        | name         | Generic Helper               | string | false    |
        | status       | ACTIVE                       | string | false    |
        | systemPrompt | You are a helpful assistant. | string | false    |
        | llmModel     | null                         | null   | true     |
        | tools        | []                           | array  | false    |
        | createdAt    |          2026-01-03T12:00:00 | string | false    |
      And 欄位 "llmModel" 應為 null
      And 欄位 "tools" 應為空陣列
      And 介面應提示訊息 "此 Agent 需在對話時指定模型"

    Example: 查詢不存在的 Agent (錯誤處理)
      # 測試目標：驗證系統對於無效 Agent ID 的錯誤處理
      Given 系統中不存在 id="ag_999" 的 Agent
      When 執行 API "GetAgentDetails", call:
        | endpoint         | method | pathParams       |
        | /api/agents/{id} | GET    | { id: "ag_999" } |
      Then 回應 HTTP 404, with error:
        | field   | value               | type   |
        | code    | AGENT_NOT_FOUND     | string |
        | message | Agent ag_999 不存在 | string |
