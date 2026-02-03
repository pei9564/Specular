Feature: 查詢可用模型

  Rule: 依據使用者權限過濾可見模型 (Visibility)
    # Visibility Rule - 確保使用者只能看到他們有權存取的模型

    Example: 一般使用者查詢混合權限的模型列表
      Given LLM Registry 目前包含以下模型狀態：
        | Model ID                 | Status | Access     |
        | gpt-4o                   | Active | Public     |
        | internal-finetuned-model | Active | Admin-Only |
      And 使用者角色為 "User"
      When 執行 CheckUsableLLMs (查詢可用模型)
      Then 回傳的 Active LLM Menu 應包含 "gpt-4o"
      And 回傳清單不應包含 "internal-finetuned-model"

    Example: 管理員查詢所有可用模型
      Given LLM Registry 目前包含以下模型狀態：
        | Model ID                 | Status | Access     |
        | gpt-4o                   | Active | Public     |
        | internal-finetuned-model | Active | Admin-Only |
      And 使用者角色為 "Admin"
      When 執行 CheckUsableLLMs (查詢可用模型)
      Then 回傳清單應包含 "gpt-4o" 與 "internal-finetuned-model"

  Rule: 無符合權限模型時回傳空集合 (Empty State)
    # Empty State Rule - 當過濾後無結果時，應回傳空清單而非錯誤

    Example: 一般使用者查詢僅含私有模型的環境
      Given LLM Registry 僅包含 "internal-finetuned-model" (Admin-Only)
      And 使用者角色為 "User"
      When 執行 CheckUsableLLMs (查詢可用模型)
      Then 回傳的 Active LLM Menu 應為 "Empty List"

  Rule: 基礎設施異常時回傳明確失敗訊息 (Exception Handling)
    # Failure Rule - 當依賴服務不可用時，需明確告知使用者

    Example: 查詢時發生資料庫連線逾時
      Given 資料庫連線發生 `ConnectionTimeout` 或 `ServiceUnavailable`
      When 執行 CheckUsableLLMs (查詢可用模型)
      Then 回傳 "Service Unavailable" 失敗訊息
