Feature: 工具庫存取 (Tool Registry Access)
  Rule: 查詢系統支援的外部工具
    # 這個查詢是執行 Rule 1 (定義 Agent) 的前置需求。
    Example: 取得定義 Agent 時可用的工具清單
      # Given = Aggregate State
      Given Aggregate: 系統已註冊以下工具 (Tools)：
        | Tool Name   | Capabilities |
        | Calculator  | Math         |
        | WebSearch   | Internet     |
      When Query: 執行 GetAvailableTools (取得可用工具)
      # Then = Read Model
      Then Read Model: 回傳的工具清單應包含 "Calculator" 與 "WebSearch"