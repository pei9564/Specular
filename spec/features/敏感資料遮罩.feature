Feature: 敏感資料遮罩 (Sensitive Data Sanitization)
  Rule: 自動遮罩日誌中的敏感資訊
    Example: 防止密碼與 API Key 明文寫入日誌
      Given Context: 使用者發送的 Request Body 包含：
        | Field    | Value        |
        | username | admin        |
        | password | MySecret123  |
        | api_key  | sk-proj-xxxx |
      When Command: 系統執行 InterceptAndLogRequest (寫入日誌)
      Then Aggregate: Audit Log 中的紀錄內容應為：
        | Field    | Value        |
        | username | admin        |
        | password | ****** |
        | api_key  | sk-proj-*** |
      And Check: 原始值 "MySecret123" 絕不應存在於日誌儲存體中

  Rule: 依據設定檔定義遮罩欄位 (Configuration Based)
    # Config Rule - 敏感欄位清單由系統靜態配置決定

    Example: 設定檔定義的欄位應被遮罩
      Given Context: 系統配置檔 (Config) 定義 SENSITIVE_FIELDS = ["credit_card", "ssn"]
      And Context: 請求內容包含 credit_card="4444-5555-6666-7777"
      When Command: 系統執行 InterceptAndLogRequest
      Then Aggregate: Audit Log 中的 credit_card 值應為 "******"
    
    Example: 未在設定檔中的欄位應保留明文
      Given Context: 系統配置檔 SENSITIVE_FIELDS 不包含 "address"
      And Context: 請求內容包含 address="123 Main St"
      When Command: 系統執行 InterceptAndLogRequest
      Then Aggregate: Audit Log 中的 address 值應為 "123 Main St"