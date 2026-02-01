Feature: Topic 配置檢視 (Topic Configuration Inspection)
  Rule: 檢視 Topic 當前實際生效的配置 (Effective Config)
    # 這個查詢對於驗證 Rule 3 (繼承) 和 Rule 5 (覆寫) 的結果至關重要。
    Example: 查詢繼承自 Agent 的 Topic 配置
      # Given = Aggregate State (對應 Rule 3)
      Given Aggregate: 存在一個 Topic (ID: topic-123)
        And Source: 基於 Agent "MathGuru" (gpt-4o) 建立
        And Override: 尚未進行任何覆寫
      # When = Query
      When Query: 執行 GetTopicConfiguration (取得 Topic 配置)
        With arguments: topic_id="topic-123"
      # Then = Read Model (驗證繼承邏輯)
      Then Read Model: 回傳的 Runtime Details 應顯示：
        | Current LLM | gpt-4o     |
        | Source Agent| MathGuru   |
    Example: 查詢已被覆寫的 Topic 配置
      # Given = Aggregate State (對應 Rule 5)
      Given Aggregate: 存在一個 Topic (ID: topic-456)
        And Source: 基於 Agent "Generic Helper" (LLM=null)
        And Override: 使用者已手動將 LLM 更新為 "gpt-3.5-turbo"
      # When = Query
      When Query: 執行 GetTopicConfiguration (取得 Topic 配置)
        With arguments: topic_id="topic-456"
      # Then = Read Model (驗證覆寫邏輯)
      Then Read Model: 回傳的 Runtime Details 應顯示：
        | Current LLM | gpt-3.5-turbo  |
        | Source Agent| Generic Helper |
