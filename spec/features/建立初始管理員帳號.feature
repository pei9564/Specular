Feature: 建立初始管理員帳號
  系統啟動時自動檢查並建立初始管理員，確保系統至少有一位管理者 (Bootstrap Rule)

  Rule: 系統首次啟動時應自動建立初始管理員帳號

    Example: 成功 - 首次啟動使用預設值建立管理員
      Given 系統資料庫 users 表為空（記錄數 = 0）
      And 未配置自訂管理員環境變數
      When 系統啟動完成
      Then users 表應新增一筆記錄:
        | field     | value                |
        | email     | admin@pegatron.com   |
        | full_name | System Administrator |
        | role      | admin                |
        | is_active | true                 |
      And 系統日誌應記錄初始帳號建立事件
      And 系統日誌應警告使用預設密碼

    Example: 成功 - 首次啟動使用自訂配置
      Given 系統資料庫 users 表為空
      And 已配置自訂管理員 Email 與 Password
      When 系統啟動完成
      Then users 表應新增一筆對應自訂 Email 的管理員記錄
      And 系統日誌應記錄初始帳號建立事件
      And 系統日誌不應出現預設密碼警告

  Rule: 系統已有任何帳號時不應建立初始管理員

    Example: 跳過 - 已存在用戶帳號
      Given 系統資料庫 users 表已存在記錄
      When 系統啟動完成
      Then users 表記錄數量應維持不變
      And 系統日誌應記錄跳過初始帳號建立

  Rule: 系統應驗證環境變數的有效性

    Example: 失敗 - Email 格式無效
      Given 系統資料庫 users 表為空
      And 配置了無效格式的管理員 Email
      When 系統啟動
      Then 系統應啟動失敗並提示 Email 格式錯誤

    Example: 失敗 - 密碼強度不足
      Given 系統資料庫 users 表為空
      And 配置了強度不足的密碼
      When 系統啟動
      Then 系統應啟動失敗並提示密碼安全性不足

  Rule: 重複啟動不應重複建立管理員

    Example: 重複啟動 - 保持既有狀態
      Given 系統首次啟動已建立初始管理員
      When 系統重新啟動
      Then users 表記錄數量應維持不變
      And 系統日誌應記錄跳過初始帳號建立

  Rule: 初始管理員建立應記錄審計日誌

    Example: 記錄初始管理員建立
      When 系統啟動完成並建立初始管理員
      Then audit_logs 表應新增一筆記錄:
        | field       | value                  |
        | action      | system.bootstrap.admin |
        | actor_id    | system                 |
        | target_type | user                   |

  Rule: 初始管理員建立應符合安全要求

    Example: 密碼不應出現在日誌中
      When 系統啟動完成
      Then 系統日誌不應包含密碼明文

    Example: 預設密碼應強制變更
      Given 系統使用預設密碼建立初始管理員
      When 管理員使用預設密碼登入
      Then 系統應強制要求變更密碼
