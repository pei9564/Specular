Feature: Agent 探索與能力檢視 (Agent Discovery & Inspection)

  Rule: 提供 Agent 清單與基礎摘要
    # List View Rule - 讓使用者快速瀏覽系統中有哪些可用角色

    Example: 查詢包含能力標籤的 Agent 清單
      Given 系統中存在以下 Agent
        | Name           | Status  | LLM    | Tools        | Description       |
        | MathGuru       | Active  | gpt-4o | [Calculator] | 數學專家          |
        | Ghost Agent    | Deleted | gpt-4o | []           | 已刪除的代理人    |
        | Generic Helper | Active  | null   | []           | 通用助手 (未綁定) |
      When 執行 ListAvailableAgents
      Then 回傳清單應包含 2 筆資料
      And 回傳結果不應包含 "Ghost Agent"
      And "MathGuru" 應列出已綁定工具 Tools=["Calculator"]
      And "Generic Helper" 應顯示其 Tools 清單為空

  Rule: 檢視單一 Agent 的完整詳細規格
    # Detail View Rule - 當使用者點擊特定 Agent 時，顯示完整的 Prompt 與配置細節

    Example: 檢視具備完整能力的 Agent 詳情
      Given Agent "MathGuru" 配置如下：
      * System Prompt: "You are a helpful math tutor. Use python for complex calc."
      * LLM: "gpt-4o" (Context Window: 128k)
      * Tools: ["Calculator", "CodeInterpreter"]
      When 執行 GetAgentDetails，參數如下：
        | agent_id | MathGuru |
      Then 應包含該 Agent 的 System Prompt 內容
      And 應列出已綁定的工具 ["Calculator", "CodeInterpreter"]
      And 應顯示底層模型資訊 (Model: gpt-4o)

    Example: 檢視未綁定模型的通用 Agent 詳情
      Given Agent "Generic Helper" 僅定義了 System Prompt，無 LLM 與 Tools
      When 執行 GetAgentDetails，參數如下：
        | agent_id | Generic Helper |
      Then LLM 欄位應為 null
      And Tools 清單應為空
      And 介面應提示 "此 Agent 需在對話時指定模型"
