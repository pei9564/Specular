Feature: 對話主題配置管理 (Topic Configuration Management)
  # 本 Feature 定義 Topic 的建立、配置更新、權限驗證與重置機制

  Rule: 初始化策略 - 支援繼承 Agent或直接指定 LLM
    # Initialization Rule - 定義 Topic 誕生時的初始狀態來源

    Example: 從現有 Agent 建立 Topic
      # 測試目標：驗證系統能基於 Agent 建立 Topic 並繼承其配置
      Given 系統中存在以下 Agent, in table "agents":
        | id     | name     | llmId  | status | systemPrompt                  |
        | ag_001 | MathGuru | llm_01 | ACTIVE | You are a helpful math tutor. |
      And Agent 綁定工具, in table "agent_tools":
        | agentId | toolInstanceId |
        | ag_001  | tool_calc_v1   |
      And LLM 資料, in table "llm_registry":
        | id     | modelId |
        | llm_01 | gpt-4o  |
      And 使用者資訊:
        | userId |
        | u_001  |
      When 執行 API "InitializeTopic", call:
        | endpoint    | method | bodyParams                                |
        | /api/topics | POST   | { agentId: "ag_001", name: "Math Study" } |
      Then 回應 HTTP 201, with data:
        | field     | value               | type   | nullable |
        | id        | topic_001           | string | false    |
        | name      | Math Study          | string | false    |
        | agentId   | ag_001              | string | false    |
        | llmId     | llm_01              | string | false    |
        | stmWindow |                  10 | number | false    |
        | userId    | u_001               | string | false    |
        | status    | ACTIVE              | string | false    |
        | createdAt | 2026-02-04T00:00:00 | string | false    |
      And 資料庫 table "topics" 應新增記錄:
        | id        | name       | agentId | llmId  | stmWindow | userId | status |
        | topic_001 | Math Study | ag_001  | llm_01 |        10 | u_001  | ACTIVE |
      And 資料庫 table "chat_threads" 應新增活躍線程:
        | topicId   | isActive |
        | topic_001 | true     |
      And 系統應發布事件 "TopicInitialized", with payload:
        | field   | value     |
        | topicId | topic_001 |
        | agentId | ag_001    |
        | userId  | u_001     |

    Example: 不使用 Agent 直接指定 LLM 建立 Topic (Raw Mode)
      # 測試目標：驗證系統支援直接指定 LLM 建立 Topic
      Given 使用者擁有權限使用 LLM, in table "llm_registry":
        | id     | modelId       | status | accessLevel |
        | llm_02 | claude-3-opus | ACTIVE | PUBLIC      |
      And 使用者資訊:
        | userId | role |
        | u_002  | USER |
      When 執行 API "InitializeTopic", call:
        | endpoint    | method | bodyParams                                       |
        | /api/topics | POST   | { agentId: null, llmId: "llm_02", name: "Chat" } |
      Then 回應 HTTP 201, with data:
        | field     | value     | type   | nullable |
        | id        | topic_002 | string | false    |
        | name      | Chat      | string | false    |
        | agentId   | null      | null   | true     |
        | llmId     | llm_02    | string | false    |
        | stmWindow |        10 | number | false    |
        | userId    | u_002     | string | false    |
        | status    | ACTIVE    | string | false    |
      And 資料庫 table "topics" 應新增記錄:
        | id        | name | agentId | llmId  | userId | status |
        | topic_002 | Chat | null    | llm_02 | u_002  | ACTIVE |
      And 系統應發布事件 "TopicInitialized"

    Example: 嘗試建立不具備模型的 Topic (失敗)
      # 測試目標：驗證系統的必要欄位驗證
      Given 系統中存在 Agent, in table "agents":
        | id     | name           | llmId | status |
        | ag_002 | Generic Helper | null  | ACTIVE |
      When 執行 API "InitializeTopic", call:
        | endpoint    | method | bodyParams                         |
        | /api/topics | POST   | { agentId: "ag_002", llmId: null } |
      Then 回應 HTTP 400, with error:
        | field   | value                              | type   |
        | code    | MODEL_MISSING                      | string |
        | message | 話題或代理人必須指定模型           | string |
        | details | { agentId: "ag_002", llmId: null } | object |
      And 資料庫 table "topics" 不應新增任何記錄

  Rule: 運行時變更與隔離 - 允許覆寫但不影響原始 Agent
    # Override Rule - 確保 Topic 的修改是獨立的 (Instance Level)，不會汙染 Agent Template

    Example: 更新 Topic 的模型設定 (覆寫)
      # 測試目標：驗證 Topic 級別的配置覆寫與 Agent 的隔離性
      Given 系統中存在以下 Topic, in table "topics":
        | id        | name    | agentId | llmId  | stmWindow | status |
        | topic_003 | MyTopic | ag_003  | llm_03 |         5 | ACTIVE |
      And 使用者擁有權限使用 LLM, in table "llm_registry":
        | id     | modelId       | status | accessLevel |
        | llm_04 | gpt-3.5-turbo | ACTIVE | PUBLIC      |
      When 執行 API "UpdateTopicConfig", call:
        | endpoint         | method | pathParams          | bodyParams                         |
        | /api/topics/{id} | PATCH  | { id: "topic_003" } | { llmId: "llm_04", stmWindow: 10 } |
      Then 回應 HTTP 200, with data:
        | field     | value     | type   |
        | id        | topic_003 | string |
        | llmId     | llm_04    | string |
        | stmWindow |        10 | number |
      And 資料庫 table "topics" 應更新記錄:
        | id        | llmId  | stmWindow | updatedAt           |
        | topic_003 | llm_04 |        10 | 2026-02-04T00:00:00 |
      And 資料庫 table "agents" 不應變更任何記錄（解耦）
      And 系統應發布事件 "TopicConfigUpdated", with payload:
        | field      | value     |
        | topicId    | topic_003 |
        | changedLlm | llm_04    |

  Rule: 安全與權限驗證 - 防止未授權的模型使用
    # Security Rule - 無論是初始化還是更新，都必須檢查模型存取權限

    Example: 嘗試切換至無權限的模型 (更新失敗)
      # 測試目標：驗證權限檢查機制
      Given 使用者資料, in table "users":
        | id    | role | permissions |
        | u_003 | USER | []          |
      And LLM 資料, in table "llm_registry":
        | id     | modelId | status | accessLevel |
        | llm_05 | gpt-4o  | ACTIVE | ADMIN_ONLY  |
      And 系統中存在 Topic, in table "topics":
        | id        | userId | status |
        | topic_004 | u_003  | ACTIVE |
      When 執行 API "UpdateTopicConfig", call:
        | endpoint         | method | pathParams          | bodyParams          |
        | /api/topics/{id} | PATCH  | { id: "topic_004" } | { llmId: "llm_05" } |
      Then 回應 HTTP 403, with error:
        | field   | value                                          | type   |
        | code    | PERMISSION_DENIED                              | string |
        | message | 您無權使用此模型                               | string |
        | details | { llmId: "llm_05", accessLevel: "ADMIN_ONLY" } | object |
      And 資料庫 table "topics" 不應變更任何記錄

    Example: 使用者權限降級後嘗試在舊有 Topic 發送訊息 (強制降級模型)
      # 測試目標：驗證動態權限檢查與自動降級機制
      Given 系統中存在 Topic, in table "topics":
        | id        | name       | llmId  | userId  | status |
        | topic_005 | AdminTopic | llm_06 | u_admin | ACTIVE |
      And LLM 資料, in table "llm_registry":
        | id     | modelId       | accessLevel |
        | llm_06 | gpt-4o        | ADMIN_ONLY  |
        | llm_07 | gpt-3.5-turbo | PUBLIC      |
      And 使用者權限已降級, with userId="u_admin", originalRole="ADMIN", currentRole="USER"
      When 執行 API "SubmitChatMessage", call:
        | endpoint                  | method | bodyParams                                 |
        | /api/topics/{id}/messages | POST   | { topicId: "topic_005", message: "Hello" } |
      Then 回應 HTTP 200, with data:
        | field        | value                                    |
        | messageId    | m_new                                    |
        | warning      | 模型已因權限變動自動切換至 gpt-3.5-turbo |
        | updatedLlmId | llm_07                                   |
      And 資料庫 table "topics" 應自動更新模型:
        | id        | llmId  |
        | topic_005 | llm_07 |
      And 系統應發布事件 "TopicModelDowngraded", with payload:
        | field    | value     |
        | topicId  | topic_005 |
        | oldLlmId | llm_06    |
        | newLlmId | llm_07    |

  Rule: 重置對話主題 (Clear Topic) - 封存舊 Thread 並開啟新 Thread
    # Reset Rule - 清除視窗內的對話歷史，但不影響 Topic 配置

    Example: 使用者清除對話歷史
      # 測試目標：驗證對話重置機制與 Thread 隔離
      Given 系統中存在 Topic, in table "topics":
        | id    | userId | status |
        | t_123 | u_001  | ACTIVE |
      And 當前活躍線程, in table "chat_threads":
        | id   | topicId | isActive | createdAt           |
        | th_1 | t_123   | true     | 2026-01-15T00:00:00 |
      And 線程包含訊息, in table "chat_messages":
        | id   | threadId | role      | content     |
        | m_01 | th_1     | USER      | Hello       |
        | m_02 | th_1     | ASSISTANT | Hi          |
        | m_03 | th_1     | USER      | How are you |
        | m_04 | th_1     | ASSISTANT | Good        |
        | m_05 | th_1     | USER      | Great       |
      When 執行 API "ClearChatTopic", call:
        | endpoint               | method | pathParams      |
        | /api/topics/{id}/clear | POST   | { id: "t_123" } |
      Then 回應 HTTP 200, with data:
        | field       | value      |
        | message     | 對話已重置 |
        | oldThreadId | th_1       |
        | newThreadId | th_2       |
      And 資料庫 table "chat_threads" 應更新舊線程:
        | id   | isActive | archivedAt          |
        | th_1 | false    | 2026-02-04T00:00:00 |
      And 資料庫 table "chat_threads" 應新增新線程:
        | id   | topicId | isActive | createdAt           |
        | th_2 | t_123   | true     | 2026-02-04T00:00:00 |
      And 新線程 "th_2" 的對話記錄應為空
      And 系統應發布事件 "TopicCleared", with payload:
        | field       | value |
        | topicId     | t_123 |
        | oldThreadId | th_1  |
        | newThreadId | th_2  |
