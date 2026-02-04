Feature: 上下文組裝策略 (Context Assembly Strategy)
  # 本 Feature 定義系統如何組裝 LangGraph 的執行上下文，包含 STM 管理、Token 截斷、HITL 檢查點與運行時解耦

  Rule: 根據 STM 設定與 Token 限制組裝 Prompt
    # 組裝規則：依據 Topic 的 STM 設定截取歷史訊息，並確保不超過模型 Token 上限

    Example: 根據 STM 設定截取歷史訊息
      # 測試目標：驗證系統能根據 STM 設定正確截取歷史訊息
      Given 系統中存在 Topic, in table "topics":
        | id        | name      | agentId | stmWindow | userId | status |
        | topic_001 | MathTopic | ag_001  |         5 | u_001  | ACTIVE |
      And Agent 配置, in table "agents":
        | id     | name     | llmId  | systemPrompt                  |
        | ag_001 | MathGuru | llm_01 | You are a helpful math tutor. |
      And LLM 配置, in table "llm_registry":
        | id     | modelId | contextWindow |
        | llm_01 | gpt-4o  |        128000 |
      And Agent 綁定工具, in table "agent_tools":
        | agentId | toolInstanceId |
        | ag_001  | tool_calc_v1   |
      And 當前活躍線程, in table "chat_threads":
        | id    | topicId   | isActive |
        | th_01 | topic_001 | true     |
      And 線程包含 20 則歷史訊息, in table "chat_messages":
        | threadId | sequence | role      | content    | tokenCount |
        | th_01    |        1 | USER      | Message 1  |         10 |
        | th_01    |        2 | ASSISTANT | Reply 1    |         15 |
        | ...      | ...      | ...       | ...        | ...        |
        | th_01    |       16 | USER      | Message 16 |         12 |
        | th_01    |       17 | ASSISTANT | Reply 16   |         18 |
        | th_01    |       18 | USER      | Message 18 |         11 |
        | th_01    |       19 | ASSISTANT | Reply 18   |         16 |
        | th_01    |       20 | USER      | Message 20 |         10 |
      And 最後 5 則訊息總 Token 數未超過上限
      When 使用者執行 API "SubmitChatMessage", call:
        | endpoint                  | method | bodyParams                                        |
        | /api/topics/{id}/messages | POST   | { topicId: "topic_001", message: "New question" } |
      Then 系統應組裝 LangGraph State:
        | key      | value                                                        | description                 |
        | messages | [SystemMessage, ...last 5 history messages, new UserMessage] | 系統提示 + 最近5則 + 新訊息 |
        | config   | { llm: "gpt-4o", tools: ["tool_calc_v1"] }                   | 模型與工具配置              |
      And messages 列表長度應為 7（1 System + 5 History + 1 New）
      And 系統應發布事件 "ChatContextAssembled", with payload:
        | field         | value     |
        | topicId       | topic_001 |
        | messagesCount |         7 |
        | stmWindow     |         5 |
      And 資料庫 table "chat_messages" 應新增使用者訊息:
        | threadId | role | content      | sequence |
        | th_01    | USER | New question |       21 |

    Example: 使用 One-shot 模式 (STM=0)
      # 測試目標：驗證無歷史模式的上下文組裝
      Given 系統中存在 Topic, in table "topics":
        | id        | name      | agentId | stmWindow | status |
        | topic_002 | MathTopic | ag_001  |         0 | ACTIVE |
      And Agent 配置與前例相同
      And 線程包含 20 則歷史訊息
      When 使用者執行 API "SubmitChatMessage", call:
        | endpoint                  | method | bodyParams                                    |
        | /api/topics/{id}/messages | POST   | { topicId: "topic_002", message: "Question" } |
      Then 系統應組裝 LangGraph State:
        | key      | value                                      |
        | messages | [SystemMessage, new UserMessage]           |
        | config   | { llm: "gpt-4o", tools: ["tool_calc_v1"] } |
      And messages 列表長度應為 2（僅系統提示 + 新訊息，無歷史）
      And 系統應發布事件 "ChatContextAssembled"

    Example: 歷史訊息超過 Token 上限時自動截斷 (FIFO 策略)
      # 測試目標：驗證 Token 超限時的自動截斷機制
      Given 系統中存在 Topic, in table "topics":
        | id        | name      | agentId | stmWindow | status |
        | topic_003 | LongTopic | ag_002  |        50 | ACTIVE |
      And Agent 配置, in table "agents":
        | id     | name       | llmId  | systemPrompt          | systemPromptTokens |
        | ag_002 | Researcher | llm_02 | You are a researcher. |                 50 |
      And LLM 配置, in table "llm_registry":
        | id     | modelId | contextWindow |
        | llm_02 | gpt-4   |          8192 |
      And 線程包含歷史訊息，最近 50 則總 Token 數為:
        | totalTokens | exceeds | contextWindow |
        |        9000 | true    |          8192 |
      When 使用者執行 API "SubmitChatMessage", call:
        | endpoint                  | method | bodyParams                                       |
        | /api/topics/{id}/messages | POST   | { topicId: "topic_003", message: "New message" } |
      Then 系統應組裝 LangGraph State, with constraints:
        | constraint         | value                                   |
        | totalTokens        | <= 8192                                 |
        | includeMessages    | SystemMessage + subset of history + new |
        | truncationStrategy | FIFO (移除最舊的訊息直到符合限制)       |
      And System Prompt 必須始終保留（不參與截斷）
      And 系統應優先移除該範圍內「最舊」的訊息直到總 Token 數 <= 8192
      And messages 列表的總 token 數應 <= 8192

    Example: 拒絕發送空訊息 (後端防護)
      # 測試目標：驗證輸入驗證機制
      Given 使用者輸入內容為 "   " (僅空白字元)
      When 使用者執行 API "SubmitChatMessage", call:
        | endpoint                  | method | bodyParams                               |
        | /api/topics/{id}/messages | POST   | { topicId: "topic_004", message: "   " } |
      Then 回應 HTTP 400, with error:
        | field   | value            | type   |
        | code    | INVALID_REQUEST  | string |
        | message | 訊息內容不可為空 | string |
      And 資料庫 table "chat_messages" 不應新增任何記錄

  Rule: 敏感操作前的檢查點驗證 (Human-in-the-loop Checkpoint)
    # HITL Rule - 對於具有副作用的工具 (Side-effect Tools)，在執行前需暫停並徵求使用者同意

    Example: 執行敏感工具前觸發 Checkpoint
      # 測試目標：驗證敏感工具調用的檢查點機制
      Given Agent 決定呼叫工具:
        | toolName        | isSensitive | action           |
        | delete_database | true        | DROP TABLE users |
      And LLM 產生 Tool Call 請求
      When 系統檢測到敏感工具調用
      Then 系統應暫停流程執行
      And 系統應發布事件 "InteractionCheckpointReached", with payload:
        | field          | value             |
        | checkpointType | tool_confirmation |
        | toolName       | delete_database   |
        | action         | DROP TABLE users  |
        | status         | PAUSED            |
      And 回應應包含確認選項:
        | option  | label    | action |
        | approve | 批准執行 | RESUME |
        | reject  | 拒絕執行 | ABORT  |

    Example: 使用者批准執行 (Resume Flow)
      # 測試目標：驗證使用者批准後的流程恢復
      Given 當前流程處於 PAUSED 狀態:
        | checkpointId | checkpointType    | toolName        |
        | ckpt_001     | tool_confirmation | delete_database |
      When 使用者發送批准指令, call:
        | endpoint                      | method | bodyParams                                      |
        | /api/checkpoints/{id}/approve | POST   | { checkpointId: "ckpt_001", action: "APPROVE" } |
      Then 系統應執行該工具 "delete_database"
      And 系統應發布事件 "ToolExecutionStarted", with payload:
        | field        | value           |
        | checkpointId | ckpt_001        |
        | toolName     | delete_database |
        | status       | RUNNING         |
      And 流程狀態應恢復為 RUNNING

    Example: 使用者拒絕執行 (Abort Flow)
      # 測試目標：驗證使用者拒絕後的流程處理
      Given 當前流程處於 PAUSED 狀態:
        | checkpointId | checkpointType    | toolName        |
        | ckpt_002     | tool_confirmation | delete_database |
      When 使用者發送拒絕指令, call:
        | endpoint                     | method | bodyParams                                     |
        | /api/checkpoints/{id}/reject | POST   | { checkpointId: "ckpt_002", action: "REJECT" } |
      Then 系統應攔截該工具呼叫
      And 系統應回傳訊息給 LLM: "User rejected execution"
      And 系統應發布事件 "ToolExecutionRejected", with payload:
        | field        | value           |
        | checkpointId | ckpt_002        |
        | toolName     | delete_database |
        | status       | ABORTED         |
      And LLM 應接收到拒絕訊息並生成新的回應（如道歉或替代方案）

  Rule: 運行時解耦組裝 (LangGraph State Mapping)
    # 確保對話時才動態拉取各組件配置，並映射為 LangGraph 所需的輸入格式

    Example: 執行 SubmitChatMessage 時的組裝邏輯
      # 測試目標：驗證運行時的動態配置組裝
      Given Topic 記錄, in table "topics":
        | id        | name    | agentId | llmId | stmWindow |
        | topic_005 | Topic-1 | ag_003  | null  |        10 |
      And Agent 當前配置, in table "agents":
        | id     | name     | llmId  | systemPrompt          |
        | ag_003 | MathGuru | llm_03 | You are a math tutor. |
      And Agent 綁定工具, in table "agent_tools":
        | agentId | toolInstanceId |
        | ag_003  | tool_calc_v2   |
      And 工具實例配置, in table "tool_instances":
        | id           | name       | config              |
        | tool_calc_v2 | Calculator | { precision: high } |
      When 使用者在 "topic_005" 發送訊息
      Then 系統應即時抓取最新配置:
        | source        | field        | value                 |
        | Agent         | llmId        | llm_03                |
        | Agent         | systemPrompt | You are a math tutor. |
        | Agent_Tools   | tools        | [tool_calc_v2]        |
        | Tool_Instance | config       | { precision: high }   |
      And 系統應初始化 LangGraph State:
        | key      | value                                                                           |
        | messages | [SystemMessage("You are a math tutor."), ...]                                   |
        | config   | { llm: "llm_03", tools: [{ id: "tool_calc_v2", config: { precision: high } }] } |
      And 即使工具實例 (Calculator) 的配置變更，下一次執行時會自動抓取最新配置
      And Topic 資料表不應產生冗餘記錄

    Example: Agent 配置更新後立即生效
      # 測試目標：驗證 Agent 配置變更的即時生效
      Given Topic 引用 Agent, in table "topics":
        | id        | agentId |
        | topic_006 | ag_004  |
      And Agent 初始配置, in table "agents":
        | id     | systemPrompt | llmId  |
        | ag_004 | Old prompt   | llm_01 |
      And Agent 配置被更新:
        | id     | systemPrompt | llmId  | updatedAt           |
        | ag_004 | New prompt   | llm_02 | 2026-02-04T10:00:00 |
      When 使用者在 "topic_006" 發送訊息（在 Agent 更新後）
      Then 系統應使用最新的 Agent 配置:
        | field        | value      |
        | systemPrompt | New prompt |
        | llmId        | llm_02     |
      And LangGraph State 應包含新的系統提示與模型
      And 不需要手動更新 Topic 配置
