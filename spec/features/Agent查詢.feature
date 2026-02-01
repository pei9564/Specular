Feature: Agent 探索與能力檢視 (Agent Discovery & Inspection)
  Rule: 提供 Agent 清單與基礎摘要
    # List View Rule - 讓使用者快速瀏覽系統中有哪些可用角色
    Example: 查詢包含能力標籤的 Agent 清單
      Given Aggregate: 系統中存在以下 Agent：
        | Name           | LLM    | Tools        | Description          |
        | MathGuru       | gpt-4o | [Calculator] | 數學專家             |
        | Generic Helper | null   | []           | 通用助手 (未綁定)    |
      When Query: 執行 ListAvailableAgents
      Then Read Model: 回傳清單應包含 2 筆資料
      And Read Model: "MathGuru" 應標示 capabilities=["Calculator"]
      And Read Model: "Generic Helper" 應標示 status="Unbound"
  Rule: 檢視單一 Agent 的完整詳細規格
    # Detail View Rule - 當使用者點擊特定 Agent 時，顯示完整的 Prompt 與配置細節
    Example: 檢視具備完整能力的 Agent 詳情
      Given Aggregate: Agent "MathGuru" 配置如下：
        * System Prompt: "You are a helpful math tutor. Use python for complex calc."
        * LLM: "gpt-4o" (Context Window: 128k)
        * Tools: ["Calculator", "CodeInterpreter"]
      When Query: 執行 GetAgentDetails
        With arguments: agent_id="MathGuru"
      Then Read Model: 應回傳完整的 System Prompt 文字
      And Read Model: 應列出已綁定的工具 ["Calculator", "CodeInterpreter"]
      And Read Model: 應顯示底層模型資訊 (Model: gpt-4o)
    Example: 檢視未綁定模型的通用 Agent 詳情
      Given Aggregate: Agent "Generic Helper" 僅定義了 System Prompt，無 LLM 與 Tools
      When Query: 執行 GetAgentDetails
        With arguments: agent_id="Generic Helper"
      Then Read Model: LLM 欄位應為 null 或 "Pending"
      And Read Model: Tools 清單應為空
      And Read Model: 介面應提示 "此 Agent 需在對話時指定模型"