Feature: 對話主題配置管理

  Rule: 初始化策略 - 支援繼承 Agent 或直接指定 LLM
    # Initialization Rule - 定義 Topic 誕生時的初始狀態來源

    Example: 從現有 Agent 繼承配置建立 Topic
      Given Aggregate: 存在 Agent "MathGuru"
        And Config: LLM="gpt-4o", Tools=["Calculator"]
      When Command: 執行 InitializeTopic (初始化 Topic)
        With arguments: agent_id="MathGuru"
      Then Aggregate: 應建立一個新的 Chat Topic
        And RuntimeConfig: LLM 應為 "gpt-4o", Tools 應包含 "Calculator"
      And Event: 系統應發布 Topic_Initialized_From_Agent 事件 <- 驗證繼承邏輯正確

    Example: 不使用 Agent 直接指定 LLM 建立 Topic (Raw Mode)
      Given Context: 使用者擁有 "claude-3-opus" 的使用權限
      When Command: 執行 InitializeTopic (初始化 Topic)
        With arguments: agent_id=null, llm_id="claude-3-opus"
      Then Aggregate: 應建立一個新的 Chat Topic
        And RuntimeConfig: LLM 應為 "claude-3-opus", AgentID 為 null
      And Event: 系統應發布 Topic_Initialized_Raw 事件 <- 驗證原生模式建立成功

  Rule: 運行時變更與隔離 - 允許覆寫但不影響原始 Agent
    # Override Rule - 確保 Topic 的修改是獨立的 (Instance Level)，不會汙染 Agent Template

    Example: 為未綁定 LLM 的 Topic 補充模型配置 (Late Binding)
      Given Aggregate: 存在一個 Chat Topic (源自 "Generic Helper")
        And RuntimeConfig: LLM 為 null (目前無模型)
      And Context: 使用者擁有 "gpt-3.5-turbo" 的使用權限
      When Command: 執行 UpdateTopicConfig (更新 Topic 配置)
        With arguments: llm_id="gpt-3.5-turbo"
      Then Aggregate: 該 Chat Topic 的 RuntimeConfig LLM 應更新為 "gpt-3.5-turbo"
      And Aggregate: 原始 Agent "Generic Helper" 的 LLM 設定應仍為 null <- 驗證 Template 與 Instance 隔離
      And Event: 系統應發布 Topic_Config_Updated 事件

  Rule: 安全與權限驗證 - 防止未授權的模型使用
    # Security Rule - 無論是初始化還是更新，都必須檢查模型存取權限

    Example: 嘗試切換至無權限的模型 (更新失敗)
      Given Context: 使用者 **無權限** 使用 "gpt-4o" (僅限 Admin)
      And Aggregate: 存在一個進行中的 Chat Topic
      When Command: 執行 UpdateTopicConfig (更新 Topic 配置)
        With arguments: llm_id="gpt-4o"
      Then Return: 系統應回傳 Error "Permission Denied" (權限不足)
      And Aggregate: Topic 配置不應被變更 <- 驗證狀態未被惡意修改