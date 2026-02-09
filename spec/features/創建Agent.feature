Feature: 創建 Agent
  使用低程式碼界面配置並創建 Agent

  Background:
    Given 系統中存在以下 LLM 模型:
      | model_id | provider  | status     |
      | gpt-4o   | openai    | active     |
      | claude-3 | anthropic | active     |
      | gpt-3.5  | openai    | deprecated |
    And 使用者 "user-001" 已登入且擁有 "create:agent" 權限

  Rule: Agent 名稱必須唯一且符合格式規範

    Example: 成功創建 - 名稱唯一且格式正確
      Given 系統中不存在名為 "MathBot" 的 Agent
      When 使用者創建 Agent:
        | field         | value            |
        | name          | MathBot          |
        | description   | 數學計算助手     |
        | system_prompt | 你是一個數學專家 |
        | model_id      | gpt-4o           |
      Then Agent "MathBot" 應成功建立
      And 資料庫應包含 Agent 記錄:
        | field       | value        |
        | name        | MathBot      |
        | description | 數學計算助手 |
        | owner_id    | user-001     |
        | status      | active       |
        | mode        | chat         |

    Example: 失敗 - 名稱已存在
      Given 系統中已存在 Agent:
        | id        | name    | owner_id |
        | agent-001 | MathBot | user-002 |
      When 使用者嘗試創建名稱為 "MathBot" 的 Agent
      Then 創建應失敗
      And 錯誤訊息應包含名稱已存在的提示
      And 資料庫 Agent 記錄數量應維持不變

    Example: 失敗 - 名稱格式不符
      When 使用者嘗試創建名稱為 "Math@Bot#1" 的 Agent
      Then 創建應失敗
      And 錯誤訊息應提示名稱僅能包含英數字、底線與連字號

    Example: 失敗 - 名稱過長
      When 使用者嘗試創建名稱超過 64 字元的 Agent
      Then 創建應失敗
      And 錯誤訊息應提示名稱長度限制

  Rule: 必須指定有效且可用的 LLM 模型

    Example: 成功 - 指定有效模型
      When 使用者創建 Agent 並指定 model_id 為 "gpt-4o"
      Then Agent 應成功建立
      And Agent 的 model_config 應包含:
        | field       | value  |
        | model_id    | gpt-4o |
        | provider    | openai |
        | temperature |    0.7 |
        | max_tokens  |   4096 |

    Example: 失敗 - 模型 ID 不存在
      When 使用者嘗試創建 Agent 並指定 model_id 為 "non-existent"
      Then 創建應失敗
      And 錯誤訊息應提示模型不存在

    Example: 失敗 - 模型已棄用
      When 使用者嘗試創建 Agent 並指定 model_id 為 "gpt-3.5"
      Then 創建應失敗
      And 錯誤訊息應提示模型已棄用

    Example: 成功 - 自訂模型參數
      When 使用者創建 Agent 並自訂參數:
        | temperature |  0.3 |
        | max_tokens  | 2048 |
      Then Agent 應成功建立
      And Agent 的 model_config 應反映自訂參數

    Example: 失敗 - temperature 超出範圍
      When 使用者嘗試創建 Agent 並設定 temperature 為 2.5
      Then 創建應失敗
      And 錯誤訊息應提示參數範圍錯誤

  Rule: Memory 配置決定對話歷史的儲存方式

    Example: 預設使用 in_memory 記憶
      When 使用者創建 Agent 未指定 memory_config
      Then Agent 的 memory_config 預設為:
        | field | value     |
        | type  | in_memory |

    Example: 成功 - 啟用 database 持久化記憶
      When 使用者創建 Agent 並指定 memory_config type 為 "database"
      Then Agent 應成功建立
      And Agent 的 memory_config 應包含:
        | field          | value    |
        | type           | database |
        | retention_days |       30 |

  Rule: 使用者必須擁有對應權限才能創建 Agent

    Example: 失敗 - 無創建權限
      Given 使用者 "guest-001" 已登入但無 "create:agent" 權限
      When 該使用者嘗試創建 Agent
      Then 創建應失敗
      And 錯誤訊息應提示權限不足

    Example: 失敗 - 超過配額限制
      Given 使用者 "user-001" 的 Agent 配額為 5
      And 該使用者已建立 5 個 Agent
      When 該使用者嘗試創建第 6 個 Agent
      Then 創建應失敗
      And 錯誤訊息應提示已達配額上限
