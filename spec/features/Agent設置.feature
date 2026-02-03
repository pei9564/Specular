Feature: Agent 設置 (Agent Configuration)

  Rule: 支援完整與彈性的 Agent 配置策略
    # Configuration Rule - 允許建立綁定特定 LLM 或未綁定的通用 Agent

    Example: 成功建立完整配置的 Agent
      Given 使用者擁有 "gpt-4o" 的使用權限
      And 系統中已存在 Tool Instance "tool_calc_v1" (Calculator)
      When 執行 CreateAgent，參數如下：
        | name   | MathGuru       |
        | tools  | [tool_calc_v1] |
        | llm_id | gpt-4o         |
      Then 建立一個新的 Agent Entity
      And Check: Name: "MathGuru", LLM: "gpt-4o"
      And Event: 系統應發布 Agent_Created 事件

    Example: 建立未綁定 LLM 的通用 Agent
      Given 使用者已登入
      When 執行 CreateAgent，參數如下：
        | name   | Generic Helper |
        | llm_id | null           |
      Then 建立一個新的 Agent Entity
      And Check: LLM: null
      And Event: 系統應發布 Agent_Created 事件

    Example: 未提供 System Prompt 時自動賦予預設值 (Default Prompt)
      Given 使用者已登入
      When 執行 CreateAgent，參數如下：
        | name          | DefaultBot |
        | system_prompt | null       |
      Then 建立一個名為 "DefaultBot" 的 Agent
      And Check: 其 System Prompt 應自動填入系統預設值 (如 "You are a helpful AI assistant.")

  Rule: 安全權限與存取控制驗證
    # Security Rule - 防止使用者綁定其無權使用的資源

    Example: 嘗試綁定無權限的模型 (權限拒絕)
      Given 使用者無權限使用 "gpt-4o" (僅限 Admin)
      And 系統中 "gpt-4o" 狀態為 Active
      When 執行 CreateAgent，參數如下：
        | name   | SecretBot |
        | llm_id | gpt-4o    |
      Then 回傳 Error "Permission Denied"
      And Agent 不應被建立

  Rule: 技術相容性與依賴檢核
    # Validation Rule - 確保 Agent 的配置在技術上可行且依賴存在

    Example: 嘗試使用不支援工具的模型 (相容性錯誤)
      Given 模型 "gpt-3.5-turbo-instruct" 設定為不支援 Tool Use
      When 執行 CreateAgent，參數如下：
        | tools  | [tool_calc_v1]         |
        | llm_id | gpt-3.5-turbo-instruct |
      Then 回傳 Error "Model Capability Mismatch"
      And Agent 不應被建立

    Example: 嘗試綁定系統中不存在的工具 (依賴錯誤)
      Given 系統中尚未註冊 Tool Instance "tool_stock_prediction"
      When 執行 CreateAgent，參數如下：
        | name  | FinanceBot              |
        | tools | [tool_stock_prediction] |
      Then 回傳 Error "Tool Instance Not Found"
      And Agent 不應被建立

  Rule: Agent 生命週期管理 (軟刪除)
    # Lifecycle Rule - Agent 不支援物理刪除，刪除後將變更狀態為 Deleted 以保留歷史紀錄

    Example: 刪除 (Delete) 一個現有的 Agent
      Given 系統中存在 Active Agent "OldBot"
      When 執行 DeleteAgent，參數如下：
        | name | OldBot |
      Then "OldBot" 的狀態應變更為 "Deleted"
      And 系統應發布 Agent_Deleted 事件

    Example: Agent 刪除後，既存 Topic 變更為唯讀模式
      Given Agent "OldBot" 狀態為 "Deleted"
      And 存在基於 "OldBot" 的 Chat Topic "Topic-A"
      When 使用者在 "Topic-A" 發送新訊息
      Then 回傳 Error "Agent Deleted"
      And Topic "Topic-A" 應不允許新增對話紀錄，但可查詢歷史清單

    Example: 還原 (Restore) 一個已刪除的 Agent
      Given Agent "OldBot" 狀態為 "Deleted"
      And 請求者為管理員 (Admin)
      When 執行 RestoreAgent (name: "OldBot")
      Then "OldBot" 的狀態應變更回 "Active"
      And 系統應發布 Agent_Restored 事件
      And 使用者現在應能基於 "OldBot" 建立新的 Topic
