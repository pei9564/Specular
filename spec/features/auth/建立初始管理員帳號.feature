Feature: 建立初始管理員帳號
  # 系統啟動時自動檢查並建立初始管理員，確保系統至少有一位管理者 (Bootstrap Rule)

  Rule: 建立初始管理員帳號 的核心邏輯
    # 定義 建立初始管理員帳號 的相關規則與行為

    Example: 首次啟動系統時自動建立管理員
      Given 系統資料庫中沒有任何用戶帳號
      When 系統啟動完成
      Then 系統應自動建立一個管理員帳號
      And 該帳號的 Email 應為 "admin@pegatron.com"
      And 該帳號的密碼應設為 "admin"
      And 該帳號的角色應為 "admin"

    Example: 透過環境變數配置初始管理員
      Given 系統資料庫中沒有任何用戶帳號
      And 環境變數 "INITIAL_ADMIN_EMAIL" 設定為 "super@example.com"
      And 環境變數 "INITIAL_ADMIN_PASSWORD" 設定為 "secure123"
      When 系統啟動完成
      Then 系統應自動建立一個管理員帳號
      And 該帳號的 Email 應為 "super@example.com"
      And 該帳號的密碼應驗證通過 "secure123"

    Example: 系統已有帳號時不進行操作
      Given 系統資料庫中已經存在用戶帳號
      When 系統啟動完成
      Then 系統不應建立任何新帳號
