Feature: 登入系統
  使用者透過 OAuth2 Password Flow 獲取存取憑證

  Background:
    Given 系統中存在以下用戶:
      | id       | email                | hashed_password                                              | role  | is_active | failed_login_count | locked_until |
      | user-001 | active@example.com   | $2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/X4s5aNqWpFqJXqJGm | user  | true      |                  0 | null         |
      | user-002 | admin@example.com    | $2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/X4s5aNqWpFqJXqJGm | admin | true      |                  0 | null         |
      | user-003 | inactive@example.com | $2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/X4s5aNqWpFqJXqJGm | user  | false     |                  0 | null         |
      | user-004 | locked@example.com   | $2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/X4s5aNqWpFqJXqJGm | user  | true      |                  5 | (未來時間)   |
    # 所有用戶的明碼密碼為 "Password123!"
  # ============================================================
  # Rule: 成功登入
  # ============================================================

  Rule: 使用正確的 Email 與密碼可獲取 Access Token

    Example: 成功 - 一般用戶登入
      Given 用戶 "active@example.com" 的密碼為 "Password123!"
      When 用戶發送 POST 請求至 "/auth/token":
        | field    | value              |
        | email    | active@example.com |
        | password | Password123!       |
      Then 請求應成功，回傳狀態碼 200
      And 回傳結果應包含:
        | field        | value       |
        | access_token | (JWT Token) |
        | token_type   | bearer      |
        | expires_in   |       86400 |
      And users 表中 user-001 應更新:
        | field              | old_value | new_value  |
        | last_login_at      | null      | (當前時間) |
        | failed_login_count |         0 |          0 |
      And token_registry 表應新增一筆記錄:
        | field      | value             |
        | user_id    | user-001          |
        | jti        | (token 的 ID)     |
        | ip_address | (請求來源 IP)     |
        | user_agent | (請求 User-Agent) |
        | created_at | (當前時間)        |
        | expires_at | (24小時後)        |

    Example: 成功 - 管理員登入
      When 用戶發送 POST 請求至 "/auth/token":
        | email    | admin@example.com |
        | password | Password123!      |
      Then 請求應成功
      And 回傳的 access_token 解碼後應包含:
        | claim | value             |
        | sub   | user-002          |
        | email | admin@example.com |
        | role  | admin             |

    Example: 成功 - Email 大小寫不敏感
      When 用戶發送 POST 請求至 "/auth/token":
        | email    | ACTIVE@EXAMPLE.COM |
        | password | Password123!       |
      Then 請求應成功
      And 回傳 access_token 應為有效 JWT
  # ============================================================
  # Rule: 登入失敗 - 統一錯誤訊息
  # ============================================================

  Rule: 登入失敗時應回傳統一錯誤訊息以防止帳號枚舉攻擊

    Example: 失敗 - 密碼錯誤
      When 用戶發送 POST 請求至 "/auth/token":
        | email    | active@example.com |
        | password | WrongPassword      |
      Then 請求應失敗，回傳狀態碼 401
      And 錯誤訊息應為 "Incorrect email or password"
      And users 表中 user-001 的 failed_login_count 應增加 1

    Example: 失敗 - Email 不存在
      When 用戶發送 POST 請求至 "/auth/token":
        | email    | nonexistent@example.com |
        | password | AnyPassword123          |
      Then 請求應失敗，回傳狀態碼 401
      And 錯誤訊息應為 "Incorrect email or password"
      And 錯誤訊息不應透露帳號不存在

    Example: 失敗 - Email 格式無效
      When 用戶發送 POST 請求至 "/auth/token":
        | email    | invalid-email |
        | password | Password123!  |
      Then 請求應失敗，回傳狀態碼 401
      And 錯誤訊息應為 "Incorrect email or password"
  # ============================================================
  # Rule: 帳號狀態檢查
  # ============================================================

  Rule: 只有 active 狀態的帳號可以登入

    Example: 失敗 - 帳號已停用
      Given 用戶 "inactive@example.com" 的 is_active 為 false
      When 用戶發送 POST 請求至 "/auth/token":
        | email    | inactive@example.com |
        | password | Password123!         |
      Then 請求應失敗，回傳狀態碼 403
      And 錯誤訊息應為 "Account is deactivated. Please contact support."

    Example: 失敗 - 帳號已鎖定
      Given 用戶 "locked@example.com" 的 locked_until 為未來時間
      When 用戶發送 POST 請求至 "/auth/token":
        | email    | locked@example.com |
        | password | Password123!       |
      Then 請求應失敗，回傳狀態碼 403
      And 錯誤訊息應為 "Account is locked due to too many failed login attempts. Please try again later."
      And 回傳應包含 locked_until 時間戳
  # ============================================================
  # Rule: 帳號鎖定機制
  # ============================================================

  Rule: 連續登入失敗達到門檻後應鎖定帳號

    Example: 連續失敗 5 次後鎖定帳號
      Given 用戶 "active@example.com" 的 failed_login_count 為 4
      When 用戶發送 POST 請求至 "/auth/token":
        | email    | active@example.com |
        | password | WrongPassword      |
      Then 請求應失敗，回傳狀態碼 401
      And users 表中 user-001 應更新:
        | field              | new_value  |
        | failed_login_count |          5 |
        | locked_until       | (30分鐘後) |
      And 回傳額外訊息: "Account has been locked for 30 minutes due to too many failed attempts."

    Example: 成功登入後重置失敗計數
      Given 用戶 "active@example.com" 的 failed_login_count 為 3
      When 用戶發送 POST 請求至 "/auth/token":
        | email    | active@example.com |
        | password | Password123!       |
      Then 請求應成功
      And users 表中 user-001 的 failed_login_count 應重置為 0

    Example: 鎖定時間到期後可重新登入
      Given 用戶 "locked@example.com" 的 locked_until 已過期（過去時間）
      When 用戶發送 POST 請求至 "/auth/token":
        | email    | locked@example.com |
        | password | Password123!       |
      Then 請求應成功
      And users 表中該用戶的 locked_until 應設為 null
      And users 表中該用戶的 failed_login_count 應重置為 0
  # ============================================================
  # Rule: 登入限流
  # ============================================================
  # (Keep Audit Logic - assuming it aligns with DBML AuditLogs)

  Rule: 登入行為應記錄審計日誌
      # ... (Assume rest is fine, just checks AuditLogs table)
  # ============================================================
  # Rule: 登入限流
  # ============================================================

  Rule: 系統應防止暴力破解攻擊

    Example: 同一 IP 短時間內登入請求過多
      Given 來自 IP "192.168.1.100" 在過去 1 分鐘內已發送 20 次登入請求
      When 來自同一 IP 發送登入請求
      Then 請求應失敗，回傳狀態碼 429
      And 錯誤訊息應為 "Too many login attempts. Please try again later."
      And 回傳標頭應包含 "Retry-After: 60"
  # ============================================================
  # Rule: 審計日誌
  # ============================================================

  Rule: 登入行為應記錄審計日誌

    Example: 成功登入應記錄審計日誌
      When 用戶發送成功的登入請求
      Then audit_logs 表應新增一筆記錄:
        | field       | value             |
        | action      | user.login        |
        | actor_id    | (用戶 ID)         |
        | actor_email | (用戶 Email)      |
        | ip_address  | (請求來源 IP)     |
        | user_agent  | (請求 User-Agent) |
        | status      | success           |
        | created_at  | (當前時間)        |

    Example: 失敗登入應記錄審計日誌
      When 用戶發送失敗的登入請求
      Then audit_logs 表應新增一筆記錄:
        | field       | value               |
        | action      | user.login          |
        | actor_email | (嘗試登入的 Email)  |
        | status      | failed              |
        | error_code  | INVALID_CREDENTIALS |
        | ip_address  | (請求來源 IP)       |
