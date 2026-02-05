Feature: 登入系統
  # 使用者透過 OAuth2 Password Flow 獲取存取憑證

  Rule: 登入系統 的核心邏輯
    # 定義 登入系統 的相關規則與行為

    Example: 用戶使用正確密碼登入
      Given 系統中存在用戶 "user@example.com" 且密碼為 "password123"
      When 用戶發送 POST 請求至 "/auth/token"
      Then 系統應回應 200 OK
      And 回應內容應包含 "access_token"
      And token_type 應為 "bearer"

    Example: 登入失敗時顯示統一錯誤訊息
      When 用戶使用錯誤的密碼嘗試登入
      Then 系統應回應 401 Unauthorized
      And 回傳統一的錯誤訊息 "Incorrect email or password"
      And 不應透露帳號是否存在 (防止帳號枚舉)
