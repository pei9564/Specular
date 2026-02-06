Feature: 創建 Agent
  使用低程式碼界面配置並創建 Agent

  Background:
    Given 系統中存在以下 LLM 模型:
      | model_id | provider  | status     |
      | gpt-4o   | openai    | active     |
      | claude-3 | anthropic | active     |
      | gpt-3.5  | openai    | deprecated |
    And 使用者 "user-001" 已登入且擁有 "create:agent" 權限
  # ============================================================
  # Rule: Agent 基本資料驗證
  # ============================================================

  Rule: Agent 名稱必須唯一且符合格式規範

    Example: 成功創建 - 名稱唯一且格式正確
      Given 系統中不存在名為 "MathBot" 的 Agent
      # API: POST /api/v1/agents
      When 使用者發送 POST 請求至 "/api/v1/agents":
        | field         | value            |
        | name          | MathBot          |
        | description   | 數學計算助手     |
        | system_prompt | 你是一個數學專家 |
        | model_id      | gpt-4o           |
      Then 請求應成功，回傳狀態碼 201
      And 資料庫應新增一筆 Agent 記錄:
        | field       | value           |
        | id          | (自動生成 UUID) |
        | name        | MathBot         |
        | description | 數學計算助手    |
        | owner_id    | user-001        |
        | status      | active          |
        | mode        | chat            |
        | created_at  | (當前時間)      |
        | updated_at  | (當前時間)      |

    Example: 失敗 - 名稱已存在
      Given 系統中已存在 Agent:
        | id        | name    | owner_id |
        | agent-001 | MathBot | user-002 |
      # API: POST /api/v1/agents
      When 使用者發送 POST 請求至 "/api/v1/agents":
        | field | value   |
        | name  | MathBot |
      Then 請求應失敗，回傳狀態碼 409
      And 錯誤訊息應為 "Agent name 'MathBot' already exists"
      And 資料庫 Agent 記錄數量應維持不變

    Example: 失敗 - 名稱格式不符（含特殊字元）
      # API: POST /api/v1/agents
      When 使用者發送 POST 請求至 "/api/v1/agents":
        | field | value      |
        | name  | Math@Bot#1 |
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "Agent name can only contain alphanumeric characters, hyphens, and underscores"

    Example: 失敗 - 名稱過長（超過 64 字元）
      # API: POST /api/v1/agents
      When 使用者發送 POST 請求至 "/api/v1/agents":
        | field | value                                                                  |
        | name  | ThisIsAVeryLongAgentNameThatExceedsTheMaximumAllowedLengthOfCharacters |
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "Agent name must be between 1 and 64 characters"
  # ============================================================
  # Rule: 模型配置驗證
  # ============================================================

  Rule: 必須指定有效且可用的 LLM 模型

    Example: 成功 - 指定有效模型
      # API: POST /api/v1/agents
      When 使用者發送 POST 請求至 "/api/v1/agents":
        | field    | value  |
        | name     | MyBot  |
        | model_id | gpt-4o |
      Then 請求應成功
      And Agent 的 model_config 應為:
        | field       | value  |
        | model_id    | gpt-4o |
        | provider    | openai |
        | temperature |    0.7 |
        | max_tokens  |   4096 |

    Example: 失敗 - 模型 ID 不存在
      # API: POST /api/v1/agents
      When 使用者發送 POST 請求至 "/api/v1/agents":
        | field    | value        |
        | name     | MyBot        |
        | model_id | non-existent |
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "Model 'non-existent' not found"

    Example: 失敗 - 模型已棄用
      # API: POST /api/v1/agents
      When 使用者發送 POST 請求至 "/api/v1/agents":
        | field    | value   |
        | name     | MyBot   |
        | model_id | gpt-3.5 |
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "Model 'gpt-3.5' is deprecated and cannot be used for new agents"

    Example: 成功 - 自訂模型參數
      # API: POST /api/v1/agents
      When 使用者發送 POST 請求至 "/api/v1/agents":
        | field       | value  |
        | name        | MyBot  |
        | model_id    | gpt-4o |
        | temperature |    0.3 |
        | max_tokens  |   2048 |
      Then 請求應成功
      And Agent 的 model_config 應為:
        | field       | value |
        | temperature |   0.3 |
        | max_tokens  |  2048 |

    Example: 失敗 - temperature 超出範圍
      # API: POST /api/v1/agents
      When 使用者發送 POST 請求至 "/api/v1/agents":
        | field       | value |
        | name        | MyBot |
        | temperature |   2.5 |
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "Temperature must be between 0 and 2"
  # ============================================================
  # Rule: 記憶模組配置
  # ============================================================

  Rule: Memory 配置決定對話歷史的儲存方式

    Example: 預設使用 in_memory 記憶
      # API: POST /api/v1/agents
      When 使用者發送 POST 請求至 "/api/v1/agents"，未指定 memory_config:
        | field | value |
        | name  | MyBot |
      Then 請求應成功
      And Agent 的 memory_config 應為:
        | field | value     |
        | type  | in_memory |

    Example: 成功 - 啟用 database 持久化記憶
      # API: POST /api/v1/agents
      When 使用者發送 POST 請求至 "/api/v1/agents":
        | field              | value    |
        | name               | MyBot    |
        | memory_config.type | database |
      Then 請求應成功
      And Agent 的 memory_config 應為:
        | field          | value    |
        | type           | database |
        | retention_days |       30 |
      And 系統應建立對應的 conversation_history 資料表分區

    Example: 成功 - 設定記憶視窗大小
      # API: POST /api/v1/agents
      When 使用者發送 POST 請求至 "/api/v1/agents":
        | field                     | value    |
        | name                      | MyBot    |
        | memory_config.type        | database |
        | memory_config.window_size |       20 |
      Then 請求應成功
      And Agent 的 memory_config.window_size 應為 20
  # ============================================================
  # Rule: 權限控制
  # ============================================================

  Rule: 使用者必須擁有對應權限才能創建 Agent

    Example: 失敗 - 無創建權限
      Given 使用者 "guest-001" 已登入但無 "create:agent" 權限
      # API: POST /api/v1/agents
      When 該使用者發送 POST 請求至 "/api/v1/agents":
        | field | value |
        | name  | MyBot |
      Then 請求應失敗，回傳狀態碼 403
      And 錯誤訊息應為 "Insufficient permissions to create agent"

    Example: 失敗 - 超過配額限制
      Given 使用者 "user-001" 的 Agent 配額為 5
      And 該使用者已建立 5 個 Agent
      # API: POST /api/v1/agents
      When 該使用者發送 POST 請求至 "/api/v1/agents":
        | field | value  |
        | name  | NewBot |
      Then 請求應失敗，回傳狀態碼 429
      And 錯誤訊息應為 "Agent quota exceeded. Maximum: 5"
