Feature: 查詢可用模型

  Rule: 依據使用者權限過濾可見模型 (Visibility)
    # Visibility Rule - 確保使用者只能看到他們有權存取的模型

    Example: 一般使用者查詢混合權限的模型列表
      Given Aggregate: LLM Registry 目前包含以下模型狀態：
        | Model ID                 | Status | Access     |
        | gpt-4o                   | Active | Public     |
        | internal-finetuned-model | Active | Admin-Only |
      And Context: 使用者角色為 "Standard User"
      When Query: 執行 CheckUsableLLMs (查詢可用模型)
      Then Read Model: 回傳的 Active LLM Menu 應包含 "gpt-4o"
      And Read Model: 回傳清單 **不應** 包含 "internal-finetuned-model" <- 驗證私有模型對一般用戶隱藏

    Example: 管理員查詢所有可用模型
      Given Aggregate: LLM Registry 目前包含以下模型狀態：
        | Model ID                 | Status | Access     |
        | gpt-4o                   | Active | Public     |
        | internal-finetuned-model | Active | Admin-Only |
      And Context: 使用者角色為 "Admin"
      When Query: 執行 CheckUsableLLMs (查詢可用模型)
      Then Read Model: 回傳清單應包含 "gpt-4o" 與 "internal-finetuned-model" <- 驗證管理員擁有完整視野

  Rule: 無符合權限模型時回傳空集合 (Empty State)
    # Empty State Rule - 當過濾後無結果時，應回傳空清單而非錯誤

    Example: 一般使用者查詢僅含私有模型的環境
      Given Aggregate: LLM Registry 僅包含 "internal-finetuned-model" (Admin-Only)
      And Context: 使用者角色為 "Standard User"
      When Query: 執行 CheckUsableLLMs (查詢可用模型)
      Then Read Model: 回傳的 Active LLM Menu 應為 "Empty List" <- 驗證系統優雅處理無資料狀況

  Rule: 基礎設施異常時回傳明確失敗訊息 (Exception Handling)
    # Failure Rule - 當依賴服務不可用時，需明確告知使用者

    Example: 查詢時發生資料庫連線逾時
      Given Event: 資料庫連線發生 `ConnectionTimeout` 或 `ServiceUnavailable`
      When Query: 執行 CheckUsableLLMs (查詢可用模型)
      Then Return: 系統應回傳 "Service Unavailable" 失敗訊息 <- 驗證例外狀況未導致系統崩潰