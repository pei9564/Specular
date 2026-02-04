Feature: Agent 設置 (Agent Configuration)
  # 本 Feature 定義如何建立與管理 Agent 配置，包含 LLM 綁定、工具關聯、權限驗證與生命週期管理

  Rule: 支援完整與彈性的 Agent 配置策略
    # Configuration Rule - 允許建立綁定特定 LLM 或未綁定的通用 Agent

    Example: 成功建立完整配置的 Agent
      # 測試目標：驗證系統能完整建立一個綁定 LLM 與工具的 Agent
      Given 使用者資料, in table "users":
        | id    | role | permissions    |
        | u_001 | USER | ["use_gpt-4o"] |
      And 系統中存在以下 LLM, in table "llm_registry":
        | id     | modelName | status | accessLevel |
        | llm_01 | gpt-4o    | ACTIVE | PUBLIC      |
      And 系統中存在以下工具實例, in table "tool_instances":
        | id           | name       | templateId | config | status |
        | tool_calc_v1 | Calculator | calculator | {}     | ACTIVE |
      When 執行 API "CreateAgent", call:
        | endpoint    | method | bodyParams                                                       |
        | /api/agents | POST   | { name: "MathGuru", llmId: "llm_01", toolIds: ["tool_calc_v1"] } |
      Then 回應 HTTP 201, with data:
        | field        | value                           | type   |
        | id           | ag_001                          | string |
        | name         | MathGuru                        | string |
        | status       | ACTIVE                          | string |
        | llmId        | llm_01                          | string |
        | toolIds      | ["tool_calc_v1"]                | array  |
        | systemPrompt | You are a helpful AI assistant. | string |
        | createdAt    |             2026-02-04T00:00:00 | string |
      And 資料庫 table "agents" 應新增一筆記錄:
        | id     | name     | llmId  | status | userId |
        | ag_001 | MathGuru | llm_01 | ACTIVE | u_001  |
      And 資料庫 table "agent_tools" 應新增記錄:
        | agentId | toolId       | enabled |
        | ag_001  | tool_calc_v1 | true    |
      And 系統應發布事件 "AgentCreated", with payload:
        | field   | value  |
        | agentId | ag_001 |
        | userId  | u_001  |
        | llmId   | llm_01 |

    Example: 建立未綁定 LLM 的通用 Agent
      # 測試目標：驗證系統支援建立不綁定模型的通用 Agent，允許在對話時動態指定模型
      Given 使用者已登入, with userId="u_002"
      When 執行 API "CreateAgent", call:
        | endpoint    | method | bodyParams                              |
        | /api/agents | POST   | { name: "Generic Helper", llmId: null } |
      Then 回應 HTTP 201, with data:
        | field        | value                           | type   | nullable |
        | id           | ag_002                          | string | false    |
        | name         | Generic Helper                  | string | false    |
        | status       | ACTIVE                          | string | false    |
        | llmId        | null                            | null   | true     |
        | toolIds      | []                              | array  | false    |
        | systemPrompt | You are a helpful AI assistant. | string | false    |
        | createdAt    |             2026-02-04T00:00:00 | string | false    |
      And 欄位 "llmId" 應為 null
      And 系統應發布事件 "AgentCreated"

    Example: 未提供 System Prompt 時自動賦予預設值
      # 測試目標：驗證系統的預設值自動填充機制
      Given 使用者已登入, with userId="u_003"
      When 執行 API "CreateAgent", call:
        | endpoint    | method | bodyParams                                 |
        | /api/agents | POST   | { name: "DefaultBot", systemPrompt: null } |
      Then 回應 HTTP 201, with data:
        | field        | value                           |
        | name         | DefaultBot                      |
        | systemPrompt | You are a helpful AI assistant. |
      And 欄位 "systemPrompt" 應自動填入系統預設值

  Rule: 安全權限與存取控制驗證
    # Security Rule - 防止使用者綁定其無權使用的資源

    Example: 嘗試綁定無權限的模型 (權限拒絕)
      # 測試目標：驗證系統的權限控制機制，防止未授權的資源存取
      Given 使用者資料, in table "users":
        | id    | role | permissions |
        | u_004 | USER | []          |
      And 系統中存在以下 LLM, in table "llm_registry":
        | id     | modelName | status | accessLevel |
        | llm_02 | gpt-4o    | ACTIVE | ADMIN_ONLY  |
      When 執行 API "CreateAgent", call:
        | endpoint    | method | bodyParams                             |
        | /api/agents | POST   | { name: "SecretBot", llmId: "llm_02" } |
      Then 回應 HTTP 403, with error:
        | field   | value                                          | type   |
        | code    | PERMISSION_DENIED                              | string |
        | message | 您無權使用此模型                               | string |
        | details | { llmId: "llm_02", accessLevel: "ADMIN_ONLY" } | object |
      And 資料庫 table "agents" 不應新增任何記錄

  Rule: 技術相容性與依賴檢核
    # Validation Rule - 確保 Agent 的配置在技術上可行且依賴存在

    Example: 嘗試使用不支援工具的模型 (相容性錯誤)
      # 測試目標：驗證模型能力與工具需求的相容性檢查
      Given 系統中存在以下 LLM, in table "llm_registry":
        | id     | modelName              | status | capabilities |
        | llm_03 | gpt-3.5-turbo-instruct | ACTIVE | []           |
      And 系統中存在以下工具實例, in table "tool_instances":
        | id           | name       | requiresToolUse |
        | tool_calc_v1 | Calculator | true            |
      When 執行 API "CreateAgent", call:
        | endpoint    | method | bodyParams                                                      |
        | /api/agents | POST   | { name: "MathBot", llmId: "llm_03", toolIds: ["tool_calc_v1"] } |
      Then 回應 HTTP 400, with error:
        | field   | value                                              | type   |
        | code    | MODEL_CAPABILITY_MISMATCH                          | string |
        | message | 此模型不支援工具調用                               | string |
        | details | { llmId: "llm_03", missingCapability: "tool_use" } | object |
      And 資料庫 table "agents" 不應新增任何記錄

    Example: 嘗試綁定系統中不存在的工具 (依賴錯誤)
      # 測試目標：驗證依賴檢查機制，確保引用的工具存在
      Given 系統中不存在工具實例 id="tool_stock_prediction"
      When 執行 API "CreateAgent", call:
        | endpoint    | method | bodyParams                                                 |
        | /api/agents | POST   | { name: "FinanceBot", toolIds: ["tool_stock_prediction"] } |
      Then 回應 HTTP 404, with error:
        | field   | value                               | type   |
        | code    | TOOL_NOT_FOUND                      | string |
        | message | 工具實例不存在                      | string |
        | details | { toolId: "tool_stock_prediction" } | object |

  Rule: Agent 生命週期管理 (軟刪除)
    # Lifecycle Rule - Agent 不支援物理刪除，刪除後將變更狀態為 DELETED 以保留歷史紀錄

    Example: 刪除 (Delete) 一個現有的 Agent
      # 測試目標：驗證軟刪除機制，確保歷史紀錄保留
      Given 系統中存在以下 Agent, in table "agents":
        | id     | name   | status | userId |
        | ag_010 | OldBot | ACTIVE | u_001  |
      When 執行 API "DeleteAgent", call:
        | endpoint         | method | pathParams       |
        | /api/agents/{id} | DELETE | { id: "ag_010" } |
      Then 回應 HTTP 200, with data:
        | field   | value        |
        | message | Agent 已刪除 |
        | agentId | ag_010       |
      And 資料庫 table "agents" 應更新記錄:
        | id     | status  | deletedAt           |
        | ag_010 | DELETED | 2026-02-04T00:00:00 |
      And 系統應發布事件 "AgentDeleted", with payload:
        | field   | value  |
        | agentId | ag_010 |

    Example: Agent 刪除後，既存 Topic 變更為唯讀模式
      # 測試目標：驗證 Agent 刪除的下游影響，確保關聯 Topic 的行為合理
      Given Agent 資料, in table "agents":
        | id     | name   | status  |
        | ag_011 | OldBot | DELETED |
      And 存在基於該 Agent 的 Topic, in table "topics":
        | id      | name    | agentId | status |
        | topic_a | Topic-A | ag_011  | ACTIVE |
      When 執行 API "SubmitChatMessage", call:
        | endpoint                  | method | bodyParams                               |
        | /api/topics/{id}/messages | POST   | { topicId: "topic_a", message: "Hello" } |
      Then 回應 HTTP 400, with error:
        | field   | value                                     | type   |
        | code    | AGENT_DELETED                             | string |
        | message | 此對話的 Agent 已刪除，無法發送新訊息     | string |
        | details | { agentId: "ag_011", topicId: "topic_a" } | object |
      And Topic 應允許查詢歷史訊息但不允許新增對話

    Example: 還原 (Restore) 一個已刪除的 Agent
      # 測試目標：驗證管理員的 Agent 還原功能
      Given Agent 資料, in table "agents":
        | id     | name   | status  | deletedAt           |
        | ag_012 | OldBot | DELETED | 2026-02-03T00:00:00 |
      And 請求者為管理員, with userId="u_admin", role="ADMIN"
      When 執行 API "RestoreAgent", call:
        | endpoint                 | method | pathParams       |
        | /api/agents/{id}/restore | POST   | { id: "ag_012" } |
      Then 回應 HTTP 200, with data:
        | field   | value        |
        | message | Agent 已還原 |
        | agentId | ag_012       |
      And 資料庫 table "agents" 應更新記錄:
        | id     | status | deletedAt |
        | ag_012 | ACTIVE | null      |
      And 系統應發布事件 "AgentRestored", with payload:
        | field   | value  |
        | agentId | ag_012 |
      And 使用者應能基於此 Agent 建立新的 Topic
