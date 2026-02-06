Feature: 編輯 Agent
  修改現有 Agent 的配置

  Background:
    Given 系統中存在以下 Agent:
      | id        | name    | owner_id | status | mode | model_id | system_prompt    |
      | agent-001 | MathBot | user-001 | active | chat | gpt-4o   | 你是數學專家     |
      | agent-002 | CodeBot | user-002 | active | chat | claude-3 | 你是程式設計專家 |
    And 系統中存在以下 LLM 模型:
      | model_id | provider  | status |
      | gpt-4o   | openai    | active |
      | claude-3 | anthropic | active |
    And 使用者 "user-001" 已登入
  # ============================================================
  # Rule: 基本欄位編輯
  # ============================================================

  Rule: 擁有者可以編輯自己的 Agent 基本資料

    Example: 成功 - 更新 System Prompt
      Given Agent "agent-001" 的 system_prompt 為 "你是數學專家"
      # API: PUT /api/v1/agents/{id}
      When 使用者 "user-001" 發送 PUT 請求至 "/api/v1/agents/agent-001":
        | system_prompt | 你是進階數學專家，擅長微積分 |
      Then 請求應成功，回傳狀態碼 200
      And Agent "agent-001" 的資料應更新為:
        | field         | old_value    | new_value                    |
        | system_prompt | 你是數學專家 | 你是進階數學專家，擅長微積分 |
        | updated_at    | (原時間)     | (當前時間)                   |
      And 應建立一筆 Agent 變更歷史記錄:
        | field         | action | old_value    | new_value                    |
        | system_prompt | update | 你是數學專家 | 你是進階數學專家，擅長微積分 |

    Example: 成功 - 更新名稱
      Given 系統中不存在名為 "AdvancedMathBot" 的 Agent
      # API: PUT /api/v1/agents/{id}
      When 使用者 "user-001" 發送 PUT 請求至 "/api/v1/agents/agent-001":
        | name | AdvancedMathBot |
      Then 請求應成功
      And Agent "agent-001" 的 name 應為 "AdvancedMathBot"

    Example: 失敗 - 更新名稱與其他 Agent 衝突
      # API: PUT /api/v1/agents/{id}
      When 使用者 "user-001" 發送 PUT 請求至 "/api/v1/agents/agent-001":
        | name | CodeBot |
      Then 請求應失敗，回傳狀態碼 409
      And 錯誤訊息應為 "Agent name 'CodeBot' already exists"
      And Agent "agent-001" 的 name 應維持為 "MathBot"

    Example: 成功 - 更新描述
      # API: PUT /api/v1/agents/{id}
      When 使用者 "user-001" 發送 PUT 請求至 "/api/v1/agents/agent-001":
        | description | 專門處理數學問題的 AI |
      Then 請求應成功
      And Agent "agent-001" 的 description 應為 "專門處理數學問題的 AI"
  # ============================================================
  # Rule: 模型配置編輯
  # ============================================================

  Rule: 可以變更 Agent 使用的 LLM 模型與參數

    Example: 成功 - 變更模型
      Given Agent "agent-001" 的 model_id 為 "gpt-4o"
      # API: PUT /api/v1/agents/{id}
      When 使用者 "user-001" 發送 PUT 請求至 "/api/v1/agents/agent-001":
        | model_id | claude-3 |
      Then 請求應成功
      And Agent "agent-001" 的 model_config 應更新:
        | field    | old_value | new_value |
        | model_id | gpt-4o    | claude-3  |
        | provider | openai    | anthropic |

    Example: 成功 - 調整 temperature
      Given Agent "agent-001" 的 temperature 為 0.7
      # API: PUT /api/v1/agents/{id}
      When 使用者 "user-001" 發送 PUT 請求至 "/api/v1/agents/agent-001":
        | temperature | 0.3 |
      Then 請求應成功
      And Agent "agent-001" 的 model_config.temperature 應為 0.3

    Example: 失敗 - 變更為不存在的模型
      # API: PUT /api/v1/agents/{id}
      When 使用者 "user-001" 發送 PUT 請求至 "/api/v1/agents/agent-001":
        | model_id | invalid-model |
      Then 請求應失敗，回傳狀態碼 400
      And Agent "agent-001" 的 model_id 應維持為 "gpt-4o"
  # ============================================================
  # Rule: 記憶類型變更
  # ============================================================

  Rule: 變更記憶類型會影響對話歷史的處理方式

    Example: 成功 - 從 in_memory 升級到 database
      Given Agent "agent-001" 的 memory_config 為:
        | field | value     |
        | type  | in_memory |
      And Agent "agent-001" 目前有 10 筆 in_memory 對話記錄
      # API: PUT /api/v1/agents/{id}
      When 使用者 "user-001" 發送 PUT 請求至 "/api/v1/agents/agent-001":
        | memory_config.type | database |
      Then 請求應成功
      And Agent "agent-001" 的 memory_config.type 應為 "database"
      And 原有的 10 筆對話記錄應遷移至資料庫
      And conversation_history 表應新增 10 筆記錄，agent_id 為 "agent-001"

    Example: 警告 - 從 database 降級到 in_memory
      Given Agent "agent-001" 的 memory_config.type 為 "database"
      And conversation_history 表中有 100 筆 agent_id 為 "agent-001" 的記錄
      # API: PUT /api/v1/agents/{id}
      When 使用者 "user-001" 發送 PUT 請求至 "/api/v1/agents/agent-001":
        | memory_config.type | in_memory |
        | confirm_data_loss  | false     |
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "Changing memory type to in_memory will result in loss of 100 conversation records. Set confirm_data_loss=true to proceed."

    Example: 成功 - 確認後從 database 降級到 in_memory
      Given Agent "agent-001" 的 memory_config.type 為 "database"
      # API: PUT /api/v1/agents/{id}
      When 使用者 "user-001" 發送 PUT 請求至 "/api/v1/agents/agent-001":
        | memory_config.type | in_memory |
        | confirm_data_loss  | true      |
      Then 請求應成功
      And Agent "agent-001" 的 memory_config.type 應為 "in_memory"
      And conversation_history 表中 agent_id 為 "agent-001" 的記錄應被封存（soft delete）
  # ============================================================
  # Rule: 權限控制
  # ============================================================

  Rule: 只有擁有者或管理員可以編輯 Agent

    Example: 失敗 - 非擁有者嘗試編輯
      # API: PUT /api/v1/agents/{id}
      When 使用者 "user-001" 發送 PUT 請求至 "/api/v1/agents/agent-002":
        | system_prompt | 惡意修改的內容 |
      Then 請求應失敗，回傳狀態碼 403
      And 錯誤訊息應為 "You do not have permission to edit this agent"
      And Agent "agent-002" 的 system_prompt 應維持為 "你是程式設計專家"

    Example: 成功 - 管理員可以編輯任何 Agent
      Given 使用者 "admin-001" 已登入且擁有 "admin" 角色
      # API: PUT /api/v1/agents/{id}
      When 使用者 "admin-001" 發送 PUT 請求至 "/api/v1/agents/agent-002":
        | system_prompt | 管理員更新的提示詞 |
      Then 請求應成功
      And Agent "agent-002" 的 system_prompt 應為 "管理員更新的提示詞"

    Example: 失敗 - Agent 不存在
      # API: PUT /api/v1/agents/{id}
      When 使用者 "user-001" 發送 PUT 請求至 "/api/v1/agents/non-existent-agent":
        | name | NewName |
      Then 請求應失敗，回傳狀態碼 404
      And 錯誤訊息應為 "Agent 'non-existent-agent' not found"
  # ============================================================
  # Rule: 狀態變更
  # ============================================================

  Rule: Agent 狀態變更會影響其可用性

    Example: 成功 - 停用 Agent
      Given Agent "agent-001" 的 status 為 "active"
      # API: PUT /api/v1/agents/{id}
      When 使用者 "user-001" 發送 PUT 請求至 "/api/v1/agents/agent-001":
        | status | inactive |
      Then 請求應成功
      And Agent "agent-001" 的 status 應為 "inactive"
      And 該 Agent 應從對話列表中隱藏
      And 正在進行的對話 session 應標記為 "agent_disabled"

    Example: 成功 - 重新啟用 Agent
      Given Agent "agent-001" 的 status 為 "inactive"
      # API: PUT /api/v1/agents/{id}
      When 使用者 "user-001" 發送 PUT 請求至 "/api/v1/agents/agent-001":
        | status | active |
      Then 請求應成功
      And Agent "agent-001" 的 status 應為 "active"
      And 該 Agent 應重新出現在對話列表中
