Feature: 建立初始管理員帳號
  系統啟動時自動檢查並建立初始管理員，確保系統至少有一位管理者 (Bootstrap Rule)
  # ============================================================
  # Rule: 首次啟動自動建立
  # ============================================================

  Rule: 系統首次啟動時應自動建立初始管理員帳號

    Example: 成功 - 首次啟動使用預設值建立管理員
      Given 系統資料庫 users 表為空（記錄數 = 0）
      And 環境變數未設定 INITIAL_ADMIN_EMAIL
      And 環境變數未設定 INITIAL_ADMIN_PASSWORD
      When 系統啟動完成
      Then users 表應新增一筆記錄:
        | field           | value                         |
        | id              | (自動生成 UUID)               |
        | email           | admin@pegatron.com            |
        | full_name       | System Administrator          |
        | role            | admin                         |
        | is_active       | true                          |
        | hashed_password | (bcrypt 雜湊，明碼為 "admin") |
        | created_at      | (當前時間)                    |
        | created_by      | system                        |
      And 系統日誌應記錄:
        | level | message                                           |
        | INFO  | Initial admin account created: admin@pegatron.com |
      And 系統日誌應記錄警告:
        | level   | message                                                             |
        | WARNING | Default admin password is being used. Please change it immediately. |

    Example: 成功 - 首次啟動使用環境變數配置
      Given 系統資料庫 users 表為空
      And 環境變數設定:
        | variable               | value             |
        | INITIAL_ADMIN_EMAIL    | super@example.com |
        | INITIAL_ADMIN_PASSWORD | SecurePass123!    |
        | INITIAL_ADMIN_NAME     | Super Admin       |
      When 系統啟動完成
      Then users 表應新增一筆記錄:
        | field           | value                                  |
        | email           | super@example.com                      |
        | full_name       | Super Admin                            |
        | role            | admin                                  |
        | hashed_password | (bcrypt 雜湊，可驗證 "SecurePass123!") |
      And 系統日誌應記錄:
        | level | message                                          |
        | INFO  | Initial admin account created: super@example.com |
      And 系統日誌不應記錄預設密碼警告

    Example: 成功 - 只設定 Email 環境變數
      Given 系統資料庫 users 表為空
      And 環境變數設定:
        | variable            | value              |
        | INITIAL_ADMIN_EMAIL | custom@example.com |
      And 環境變數未設定 INITIAL_ADMIN_PASSWORD
      When 系統啟動完成
      Then users 表應新增一筆記錄:
        | field           | value                         |
        | email           | custom@example.com            |
        | hashed_password | (bcrypt 雜湊，明碼為 "admin") |
      And 系統日誌應記錄預設密碼警告
  # ============================================================
  # Rule: 已有帳號時不建立
  # ============================================================

  Rule: 系統已有任何帳號時不應建立初始管理員

    Example: 跳過 - 已存在用戶帳號
      Given 系統資料庫 users 表已存在記錄:
        | id       | email            | role |
        | user-001 | user@example.com | user |
      When 系統啟動完成
      Then users 表記錄數量應維持為 1
      And 系統日誌應記錄:
        | level | message                                                |
        | INFO  | Existing users found. Skipping initial admin creation. |

    Example: 跳過 - 已存在管理員帳號
      Given 系統資料庫 users 表已存在記錄:
        | id        | email             | role  |
        | admin-001 | admin@example.com | admin |
      When 系統啟動完成
      Then users 表記錄數量應維持為 1
      And 不應建立新的管理員帳號
  # ============================================================
  # Rule: 環境變數驗證
  # ============================================================

  Rule: 系統應驗證環境變數的有效性

    Example: 失敗 - Email 格式無效
      Given 系統資料庫 users 表為空
      And 環境變數設定:
        | variable            | value         |
        | INITIAL_ADMIN_EMAIL | invalid-email |
      When 系統啟動
      Then 系統應啟動失敗
      And 錯誤訊息應為 "Invalid INITIAL_ADMIN_EMAIL format"
      And users 表應維持為空

    Example: 失敗 - 密碼不符合強度要求
      Given 系統資料庫 users 表為空
      And 環境變數設定:
        | variable               | value          |
        | INITIAL_ADMIN_EMAIL    | admin@test.com |
        | INITIAL_ADMIN_PASSWORD | weak           |
      When 系統啟動
      Then 系統應啟動失敗
      And 錯誤訊息應為 "INITIAL_ADMIN_PASSWORD does not meet security requirements"

    Example: 成功 - 允許簡單密碼在開發環境
      Given 系統資料庫 users 表為空
      And 環境變數設定:
        | variable               | value          |
        | NODE_ENV               | development    |
        | INITIAL_ADMIN_EMAIL    | admin@test.com |
        | INITIAL_ADMIN_PASSWORD | simple         |
      When 系統啟動完成
      Then 用戶應成功建立
      And 系統日誌應記錄警告:
        | level   | message                                         |
        | WARNING | Weak admin password allowed in development mode |
  # ============================================================
  # Rule: 冪等性
  # ============================================================

  Rule: 重複啟動不應重複建立管理員

    Example: 重複啟動 - 不重複建立
      Given 系統首次啟動已建立管理員 "admin@pegatron.com"
      And users 表記錄數量為 1
      When 系統重新啟動
      Then users 表記錄數量應維持為 1
      And 系統日誌應記錄:
        | level | message                                                |
        | INFO  | Existing users found. Skipping initial admin creation. |
  # ============================================================
  # Rule: 審計日誌
  # ============================================================

  Rule: 初始管理員建立應記錄審計日誌

    Example: 記錄初始管理員建立
      Given 系統資料庫 users 表為空
      When 系統啟動完成並建立初始管理員
      Then audit_logs 表應新增一筆記錄:
        | field       | value                                                  |
        | action      | system.bootstrap.admin                                 |
        | actor_id    | system                                                 |
        | target_type | user                                                   |
        | target_id   | (新管理員 ID)                                          |
        | details     | {"email": "admin@pegatron.com", "source": "bootstrap"} |
        | created_at  | (當前時間)                                             |
  # ============================================================
  # Rule: 安全考量
  # ============================================================

  Rule: 初始管理員建立應符合安全要求

    Example: 密碼不應出現在日誌中
      Given 系統資料庫 users 表為空
      And 環境變數設定:
        | variable               | value           |
        | INITIAL_ADMIN_PASSWORD | MySecretPass123 |
      When 系統啟動完成
      Then 系統日誌不應包含 "MySecretPass123"
      And 系統日誌不應包含任何密碼明文

    Example: 預設密碼應強制變更
      Given 系統使用預設密碼建立初始管理員
      When 管理員使用預設密碼登入
      Then 登入應成功
      And 回傳應包含標記:
        | field                    | value |
        | password_change_required | true  |
      And 管理員嘗試存取其他 API 時應被重導向至密碼變更頁面
