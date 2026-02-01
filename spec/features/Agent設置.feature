Feature: Agent 設置 (Agent Configuration)
  Rule: 支援完整與彈性的 Agent 配置策略
    # Configuration Rule - 允許建立綁定特定 LLM 或未綁定的通用 Agent
    Example: 成功建立完整配置的 Agent
      Given Context: 使用者擁有 "gpt-4o" 的使用權限
      And Aggregate: 系統中已存在 Tool "Calculator"
      When Command: 執行 CreateAgent
        With arguments: name="MathGuru", tools=["Calculator"], llm_id="gpt-4o"
      Then Aggregate: 應建立一個新的 Agent Entity
        And Name: "MathGuru", LLM: "gpt-4o"
      And Event: 系統應發布 Agent_Created 事件
    Example: 建立未綁定 LLM 的通用 Agent
      Given Context: 使用者已登入
      When Command: 執行 CreateAgent
        With arguments: name="Generic Helper", llm_id=null
      Then Aggregate: 應建立一個新的 Agent Entity
        And LLM: null
      And Event: 系統應發布 Agent_Created 事件
  Rule: 安全權限與存取控制驗證
    # Security Rule - 防止使用者綁定其無權使用的資源
    Example: 嘗試綁定無權限的模型 (權限拒絕)
      Given Context: 使用者無權限使用 "gpt-4o" (僅限 Admin)
      And Aggregate: 系統中 "gpt-4o" 狀態為 Active
      When Command: 執行 CreateAgent
        With arguments: name="SecretBot", llm_id="gpt-4o"
      Then Return: 系統應回傳 Error "Permission Denied"
      And Aggregate: Agent 不應被建立
  Rule: 技術相容性與依賴檢核
    # Validation Rule - 確保 Agent 的配置在技術上可行且依賴存在
    Example: 嘗試使用不支援工具的模型 (相容性錯誤)
      Given Aggregate: 模型 "gpt-3.5-turbo-instruct" 設定為不支援 Tool Use
      When Command: 執行 CreateAgent
        With arguments: tools=["Calculator"], llm_id="gpt-3.5-turbo-instruct"
      Then Return: 系統應回傳 Error "Model Capability Mismatch"
      And Aggregate: Agent 不應被建立
    Example: 嘗試綁定系統中不存在的工具 (依賴錯誤)
      Given Aggregate: 系統中尚未註冊 Tool "StockPredictor"
      When Command: 執行 CreateAgent
        With arguments: name="FinanceBot", tools=["StockPredictor"]
      Then Return: 系統應回傳 Error "Tool Not Found"
      And Aggregate: Agent 不應被建立

  Rule: Agent 生命週期管理 (軟刪除)
    # Lifecycle Rule - Agent 不支援物理刪除，僅能停用以保留歷史紀錄

    Example: 停用 (Archive) 一個現有的 Agent
      Given Aggregate: 系統中存在 Active Agent "OldBot"
      When Command: 執行 DisableAgent
        With arguments: name="OldBot"
      Then Aggregate: "OldBot" 的狀態應變更為 "Retired"
      And Event: 系統應發布 Agent_Retired 事件

    Example: 嘗試物理刪除 Agent (被拒絕)
      Given Aggregate: 系統中存在 Agent "AnyBot"
      When Command: 執行 DeleteAgent
        With arguments: name="AnyBot"
      Then Return: 系統應回傳 Error "Physical Deletion Not Supported"
      And Aggregate: Agent "AnyBot" 應仍存在於系統中