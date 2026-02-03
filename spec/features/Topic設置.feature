Feature: 對話主題配置管理

  Rule: 初始化策略 - 支援繼承 Agent 或直接指定 LLM
    # Initialization Rule - 定義 Topic 誕生時的初始狀態來源

    Example: 從現有 Agent 建立 Topic
      Given 存在 Agent "MathGuru" (綁定 Tool Instance "tool_calc_v1")
      And Agent LLM 為 "gpt-4o"
      When 執行 InitializeTopic (初始化 Topic)，參數如下：
        | agent_id | MathGuru |
      Then 建立一個新的 Chat Topic
      And Topic 資料記錄應僅儲存 agent_id="MathGuru"
      And 實際對話時之模型與工具應動態參照 Agent "MathGuru" 的最新狀態
      And stm_window 應自動設為預設值 10
      And 系統應發布 Topic_Initialized 事件

    Example: 不使用 Agent 直接指定 LLM 建立 Topic (Raw Mode)
      Given 使用者擁有 "claude-3-opus" 的使用權限
      When 執行 InitializeTopic (初始化 Topic)，參數如下：
        | agent_id | null          |
        | llm_id   | claude-3-opus |
      Then 建立一個新的 Chat Topic
      And Topic 資料記錄應儲存 current_llm_id="claude-3-opus", agent_id=null
      And 系統應發布 Topic_Initialized 事件

    Example: 嘗試建立不具備模型的 Topic (失敗)
      Given 系統中存在 Agent "Generic Helper" (LLM: null)
      When 執行 InitializeTopic，參數如下：
        | agent_id | Generic Helper |
        | llm_id   | null           |
      Then 回傳 Error "Model Missing"
      And 系統提示「話題或代理人必須指定模型」
      And Topic 不應被建立

  Rule: 運行時變更與隔離 - 允許覆寫但不影響原始 Agent
    # Override Rule - 確保 Topic 的修改是獨立的 (Instance Level)，不會汙染 Agent Template

    Example: 更新 Topic 的模型設定 (覆寫)
      Given 存在一個 Chat Topic (源自 "Generic Helper")
      And 使用者擁有 "gpt-3.5-turbo" 的使用權限
      When 執行 UpdateTopicConfig (更新 Topic 配置)，參數如下：
        | llm_id     | gpt-3.5-turbo |
        | stm_window |            10 |
      Then 該 Chat Topic 之資料庫記錄更新為 current_llm_id="gpt-3.5-turbo", stm_window=10
      And 原始 Agent "Generic Helper" 的資料表記錄應不變 (解耦)
      And 系統應發布 Topic_Config_Updated 事件

  Rule: 安全與權限驗證 - 防止未授權的模型使用
    # Security Rule - 無論是初始化還是更新，都必須檢查模型存取權限

    Example: 嘗試切換至無權限的模型 (更新失敗)
      Given 使用者無權限使用 "gpt-4o" (僅限 Admin)
      And 存在一個進行中的 Chat Topic
      When 執行 UpdateTopicConfig (更新 Topic 配置)，參數如下：
        | llm_id | gpt-4o |
      Then 回傳 Error "Permission Denied" (權限不足)
      And Topic 配置不應被變更

    Example: 使用者權限降級後嘗試在舊有 Topic 發送訊息 (強制降級模型)
      Given 存在一個 Chat Topic "AdminTopic"，當前配置為 "gpt-4o" (Admin-Only)
      And 使用者原為 Admin，現已降級為 "User"
      When 使用者在 "AdminTopic" 執行 SubmitChatMessage (發送訊息)
      Then 系統應偵測到模型存取權限失效
      And 系統應自動將該 Topic 的模型切換為預設的 Public 模型 (如 "gpt-3.5-turbo")
      And 系統應發布 Topic_Model_Downgraded 事件
      And 訊息應成功處理，但系統應提示使用者「模型已因權限變動自動切換」

  Rule: 重置對話主題 (Clear Topic) - 封存舊 Session 並開啟新 Session
    # Reset Rule - 清除視窗內的對話歷史，但不影響 Topic 配置

    Example: 使用者清除對話歷史
      Given Chat Topic (ID: t_123) 當前有一個活躍 Session (ID: s_1, is_active=true)
      And Session s_1 包含 5 則對話紀錄
      When 執行 ClearChatTopic (重置對話)，參數如下：
        | topic_id | t_123 |
      Then Session s_1 的 is_active 應變更為 false
      And 應為 Topic t_123 建立一個新的 Session (ID: s_2, is_active=true)
      And 新 Session s_2 的對話紀錄應為空
      And 系統應發布 Topic_Cleared 事件
