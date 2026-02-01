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