Feature: 用戶註冊
  # 新用戶註冊流程與安全儲存

  Rule: 用戶註冊 的核心邏輯
    # 定義 用戶註冊 的相關規則與行為

    Example: 一般用戶註冊成功
      When 用戶提交註冊請求 "user@example.com" 與密碼 "password123"
      Then 系統應成功創建帳號
      And 該帳號的角色應預設為 "user"
      And 密碼應使用 "bcrypt" 雜湊加密儲存
      And 資料庫中不應儲存明碼密碼

    Example: 註冊重複的 Email
      Given 系統中已存在 Email 為 "user@example.com" 的用戶
      When 用戶嘗試使用 "user@example.com" 註冊
      Then 系統應拒絕註冊請求
      And 回傳 Email 已存在的錯誤訊息
