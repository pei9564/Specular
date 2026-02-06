Feature: 用戶註冊
  新用戶註冊流程與安全儲存

  Background:
    # Given 系統中存在以下用戶:
    #   | id       | email                | role  | status | created_at          |
    #   | user-001 | existing@example.com | user  | active | 2024-01-01 00:00:00 |
    #   | user-002 | admin@pegatron.com   | admin | active | 2024-01-01 00:00:00 |
    Given 系統中存在以下用戶:
      | id       | email                | username | role  | is_active | created_at          |
      | user-001 | existing@example.com | user1    | user  | true      | 2024-01-01 00:00:00 |
      | user-002 | admin@pegatron.com   | admin    | admin | true      | 2024-01-01 00:00:00 |
  # ============================================================
  # Rule: 基本註冊流程
  # ============================================================

  Rule: 用戶可以使用有效的 Email、Username 與密碼完成註冊

    Example: 成功 - 一般用戶註冊
      Given 系統中不存在 Email 為 "newuser@example.com" 的用戶
      # When 用戶提交註冊請求:
      #   | field    | value               |
      #   | email    | newuser@example.com |
      #   | password | SecurePass123!      |
      #   | name     | New User            |
      # API: POST /api/v1/auth/register
      # Content-Type: application/json
      # Body: {"email": "newuser@example.com", "username": "newuser", "password": "SecurePass123!", "full_name": "New User"}
      When 用戶發送 POST 請求至 "/api/v1/auth/register":
        | field     | value               |
        | email     | newuser@example.com |
        | username  | newuser             |
        | password  | SecurePass123!      |
        | full_name | New User            |
      Then 請求應成功，回傳狀態碼 201
      # And users 表應新增一筆記錄:
      #   | field         | value                   |
      #   | ...           | ...                     |
      And users 表應新增一筆記錄:
        | field           | value                   |
        | id              | (自動生成 UUID)         |
        | email           | newuser@example.com     |
        | username        | newuser                 |
        | full_name       | New User                |
        | role            | user                    |
        | is_active       | true                    |
        | hashed_password | (bcrypt 雜湊值，非明碼) |
        | created_at      | (當前時間)              |
        | updated_at      | (當前時間)              |
        | last_login_at   | null                    |
      And 資料庫中不應存在明碼密碼 "SecurePass123!"
      # And 回傳結果應包含:
      #   | field | value               |
      #   | ...   | ...                 |
      And 回傳結果應包含:
        | field     | value               |
        | id        | (新用戶 UUID)       |
        | email     | newuser@example.com |
        | username  | newuser             |
        | full_name | New User            |
        | role      | user                |
      And 回傳結果不應包含 hashed_password

    Example: 成功 - 密碼使用 bcrypt 加密儲存
      # API: POST /api/v1/auth/register
      When 用戶發送 POST 請求至 "/api/v1/auth/register":
        | email    | test@example.com |
        | username | testuser         |
        | password | MyPassword123    |
      Then 請求應成功
      And 新用戶的 hashed_password 應符合 bcrypt 格式（以 "$2b$" 開頭）
      And hashed_password 長度應為 60 字元
      And 使用 bcrypt.verify("MyPassword123", hashed_password) 應回傳 true
  # ============================================================
  # Rule: Email 與 Username 驗證
  # ============================================================

  Rule: Email 與 Username 必須唯一且格式正確

    Example: 失敗 - Email 已存在
      Given users 表中已存在:
        | email                |
        | existing@example.com |
      # API: POST /api/v1/auth/register
      When 用戶發送 POST 請求至 "/api/v1/auth/register":
        | email    | existing@example.com |
        | username | newuser2             |
        | password | SomePassword123      |
      Then 請求應失敗，回傳狀態碼 409
      And 錯誤訊息應為 "Email 'existing@example.com' is already registered"

    Example: 失敗 - Username 已存在
      Given users 表中已存在:
        | username |
        | user1    |
      # API: POST /api/v1/auth/register
      When 用戶發送 POST 請求至 "/api/v1/auth/register":
        | email    | unique@example.com |
        | username | user1              |
        | password | SomePassword123    |
      Then 請求應失敗，回傳狀態碼 409
      And 錯誤訊息應為 "Username 'user1' is already taken"

    Example: 失敗 - Email 格式無效
      # API: POST /api/v1/auth/register
      When 用戶發送 POST 請求至 "/api/v1/auth/register":
        | email    | invalid-email   |
        | username | validuser       |
        | password | SomePassword123 |
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "Invalid email format"

    Example: 失敗 - Email 為空
      # API: POST /api/v1/auth/register
      When 用戶發送 POST 請求至 "/api/v1/auth/register":
        | email    |                 |
        | username | validuser       |
        | password | SomePassword123 |
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "Email is required"

    Example: 成功 - Email 自動轉為小寫儲存
      # API: POST /api/v1/auth/register
      When 用戶發送 POST 請求至 "/api/v1/auth/register":
        | email    | NewUser@EXAMPLE.COM |
        | password | SomePassword123     |
      Then 請求應成功
      And 新用戶的 email 應儲存為 "newuser@example.com"
  # ============================================================
  # Rule: 密碼強度驗證
  # ============================================================

  Rule: 密碼必須符合安全強度要求

    Example: 失敗 - 密碼過短（少於 8 字元）
      # API: POST /api/v1/auth/register
      When 用戶發送 POST 請求至 "/api/v1/auth/register":
        | email    | test@example.com |
        | password | Short1!          |
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "Password must be at least 8 characters long"

    Example: 失敗 - 密碼缺少數字
      # API: POST /api/v1/auth/register
      When 用戶發送 POST 請求至 "/api/v1/auth/register":
        | email    | test@example.com |
        | password | NoDigitsHere!    |
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "Password must contain at least one digit"

    Example: 失敗 - 密碼缺少大寫字母
      # API: POST /api/v1/auth/register
      When 用戶發送 POST 請求至 "/api/v1/auth/register":
        | email    | test@example.com |
        | password | nouppercase123!  |
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "Password must contain at least one uppercase letter"

    Example: 失敗 - 密碼為空
      # API: POST /api/v1/auth/register
      When 用戶發送 POST 請求至 "/api/v1/auth/register":
        | email    | test@example.com |
        | password |                  |
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "Password is required"

    Example: 成功 - 符合所有密碼要求
      # API: POST /api/v1/auth/register
      When 用戶發送 POST 請求至 "/api/v1/auth/register":
        | email    | strong@example.com |
        | password | StrongPass123!     |
      Then 請求應成功
      And 新用戶應成功建立
  # ============================================================
  # Rule: 註冊限流
  # ============================================================

  Rule: 系統應防止註冊濫用

    Example: 失敗 - 同一 IP 短時間內註冊過多次
      Given 來自 IP "192.168.1.100" 在過去 1 小時內已註冊 10 個帳號
      When 來自同一 IP 的用戶提交註冊請求:
        | email    | another@example.com |
        | password | Password123!        |
      Then 請求應失敗，回傳狀態碼 429
      And 錯誤訊息應為 "Too many registration attempts. Please try again later."
      And 回傳標頭應包含 "Retry-After: 3600"
  # ============================================================
  # Rule: 審計日誌
  # ============================================================

  Rule: 註冊行為應記錄審計日誌

    Example: 成功註冊應記錄審計日誌
      # API: POST /api/v1/auth/register
      When 用戶發送 POST 請求至 "/api/v1/auth/register":
        | email    | audit@example.com |
        | password | Password123!      |
      Then 請求應成功
      And audit_logs 表應新增一筆記錄:
        | field       | value             |
        | action      | user.register     |
        | actor_id    | (新用戶 ID)       |
        | actor_email | audit@example.com |
        | ip_address  | (請求來源 IP)     |
        | user_agent  | (請求 User-Agent) |
        | status      | success           |
        | created_at  | (當前時間)        |

    Example: 失敗註冊應記錄審計日誌
      # API: POST /api/v1/auth/register
      When 用戶發送 POST 請求至 "/api/v1/auth/register":
        | email    | existing@example.com |
        | password | Password123!         |
      Then 請求應失敗
      And audit_logs 表應新增一筆記錄:
        | field       | value                |
        | action      | user.register        |
        | actor_email | existing@example.com |
        | status      | failed               |
        | error_code  | EMAIL_ALREADY_EXISTS |
