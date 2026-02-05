Feature: 查詢全系統用戶清單
  管理員專屬功能：查看系統中所有使用者

  Background:
    Given 系統中存在以下用戶:
      | id       | email              | full_name    | role  | is_active | created_at          | last_login_at       |
      | user-001 | alice@example.com  | Alice Chen   | user  | true      | 2024-01-01 10:00:00 | 2024-01-15 08:30:00 |
      | user-002 | bob@example.com    | Bob Wang     | user  | true      | 2024-01-02 11:00:00 | 2024-01-14 09:00:00 |
      | user-003 | carol@example.com  | Carol Liu    | user  | false     | 2024-01-03 12:00:00 | 2024-01-10 10:00:00 |
      | user-004 | david@example.com  | David Lee    | admin | true      | 2024-01-04 13:00:00 | 2024-01-15 11:00:00 |
      | user-005 | admin@pegatron.com | System Admin | admin | true      | 2024-01-01 00:00:00 | 2024-01-15 12:00:00 |
  # ============================================================
  # Rule: 權限控制
  # ============================================================

  Rule: 只有管理員可以查詢全系統用戶清單

    Example: 成功 - 管理員查詢用戶列表
      Given 使用者 "admin@pegatron.com" 已登入（角色為 admin）
      When 使用者發送 GET 請求至 "/api/admin/users"
      Then 請求應成功，回傳狀態碼 200
      And 回傳結果應包含所有用戶:
        | id       | email              | full_name    | role  | is_active |
        | user-001 | alice@example.com  | Alice Chen   | user  | true      |
        | user-002 | bob@example.com    | Bob Wang     | user  | true      |
        | user-003 | carol@example.com  | Carol Liu    | user  | false     |
        | user-004 | david@example.com  | David Lee    | admin | true      |
        | user-005 | admin@pegatron.com | System Admin | admin | true      |

    Example: 失敗 - 一般用戶禁止查詢
      Given 使用者 "alice@example.com" 已登入（角色為 user）
      When 使用者發送 GET 請求至 "/api/admin/users"
      Then 請求應失敗，回傳狀態碼 403
      And 錯誤訊息應為 "Admin access required"

    Example: 失敗 - 未登入禁止查詢
      Given 使用者未登入（無 Authorization 標頭）
      When 發送 GET 請求至 "/api/admin/users"
      Then 請求應失敗，回傳狀態碼 401
      And 錯誤訊息應為 "Authorization header is required"
  # ============================================================
  # Rule: 分頁功能
  # ============================================================

  Rule: 支援分頁查詢以處理大量用戶

    Example: 成功 - 預設分頁（第一頁）
      Given 使用者 "admin@pegatron.com" 已登入
      When 使用者發送 GET 請求至 "/api/admin/users":
        | page      | 1 |
        | page_size | 2 |
      Then 請求應成功
      And 回傳結果應包含:
        | field       | value |
        | total       |     5 |
        | page        |     1 |
        | page_size   |     2 |
        | total_pages |     3 |
      And data 陣列應包含 2 筆用戶

    Example: 成功 - 查詢最後一頁
      Given 使用者 "admin@pegatron.com" 已登入
      When 使用者發送 GET 請求至 "/api/admin/users":
        | page      | 3 |
        | page_size | 2 |
      Then 請求應成功
      And data 陣列應包含 1 筆用戶

    Example: 成功 - 預設分頁大小
      Given 使用者 "admin@pegatron.com" 已登入
      When 使用者發送 GET 請求至 "/api/admin/users"，不指定分頁參數
      Then 預設 page 應為 1
      And 預設 page_size 應為 20

    Example: 失敗 - 分頁參數無效
      Given 使用者 "admin@pegatron.com" 已登入
      When 使用者發送 GET 請求至 "/api/admin/users":
        | page      |  -1 |
        | page_size | 200 |
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應包含 "page must be positive" 或 "page_size must be between 1 and 100"
  # ============================================================
  # Rule: 篩選功能
  # ============================================================

  Rule: 支援依據條件篩選用戶

    Example: 成功 - 依角色篩選
      Given 使用者 "admin@pegatron.com" 已登入
      When 使用者發送 GET 請求至 "/api/admin/users":
        | role | admin |
      Then 請求應成功
      And 回傳結果應僅包含角色為 admin 的用戶:
        | email              |
        | david@example.com  |
        | admin@pegatron.com |
      And total 應為 2

    Example: 成功 - 依狀態篩選
      Given 使用者 "admin@pegatron.com" 已登入
      When 使用者發送 GET 請求至 "/api/admin/users":
        | is_active | false |
      Then 請求應成功
      And 回傳結果應僅包含:
        | email             | is_active |
        | carol@example.com | false     |

    Example: 成功 - 依關鍵字搜尋（Email 或名稱）
      Given 使用者 "admin@pegatron.com" 已登入
      When 使用者發送 GET 請求至 "/api/admin/users":
        | search | alice |
      Then 請求應成功
      And 回傳結果應包含 email 或 full_name 含有 "alice" 的用戶

    Example: 成功 - 組合篩選條件
      Given 使用者 "admin@pegatron.com" 已登入
      When 使用者發送 GET 請求至 "/api/admin/users":
        | role      | user |
        | is_active | true |
      Then 請求應成功
      And 回傳結果應僅包含角色為 user 且狀態為 active (true) 的用戶:
        | email             |
        | alice@example.com |
        | bob@example.com   |
  # ============================================================
  # Rule: 排序功能
  # ============================================================

  Rule: 支援依不同欄位排序

    Example: 預設依建立時間降序
      Given 使用者 "admin@pegatron.com" 已登入
      When 使用者發送 GET 請求至 "/api/admin/users"，不指定排序
      Then 回傳結果應依 created_at 降序排列
      And 第一筆應為最近建立的用戶

    Example: 成功 - 依名稱升序排序
      Given 使用者 "admin@pegatron.com" 已登入
      When 使用者發送 GET 請求至 "/api/admin/users":
        | sort_by | full_name |
        | order   | asc       |
      Then 回傳結果應依 full_name 升序排列
      And 第一筆應為 "Alice Chen"

    Example: 成功 - 依最後登入時間排序
      Given 使用者 "admin@pegatron.com" 已登入
      When 使用者發送 GET 請求至 "/api/admin/users":
        | sort_by | last_login_at |
        | order   | desc          |
      Then 回傳結果應依最近登入時間優先
  # ============================================================
  # Rule: 回傳欄位
  # ============================================================

  Rule: 回傳適當的用戶資訊，排除敏感資料

    Example: 回傳欄位應包含必要資訊
      Given 使用者 "admin@pegatron.com" 已登入
      When 使用者發送 GET 請求至 "/api/admin/users"
      Then 每筆用戶應包含以下欄位:
        | field         | type     | description               |
        | id            | string   | 用戶 UUID                 |
        | email         | string   | 用戶 Email                |
        | full_name     | string   | 用戶名稱                  |
        | role          | string   | 角色 (user/admin)         |
        | is_active     | boolean  | 狀態 (true/false)         |
        | created_at    | datetime | 建立時間                  |
        | last_login_at | datetime | 最後登入時間（可為 null） |
        | agent_count   | number   | 該用戶擁有的 Agent 數量   |

    Example: 回傳欄位不應包含敏感資料
      Given 使用者 "admin@pegatron.com" 已登入
      When 使用者發送 GET 請求至 "/api/admin/users"
      Then 每筆用戶不應包含以下欄位:
        | field           |
        | password        |
        | hashed_password |
        | refresh_token   |
  # ============================================================
  # Rule: 統計資訊
  # ============================================================

  Rule: 可選擇性回傳用戶統計資訊

    Example: 成功 - 包含統計資訊
      Given 使用者 "admin@pegatron.com" 已登入
      When 使用者發送 GET 請求至 "/api/admin/users":
        | include_stats | true |
      Then 回傳結果應包含 stats 物件:
        | field          | value |
        | total_users    |     5 |
        | active_users   |     4 |
        | inactive_users |     1 |
        | admin_count    |     2 |
        | user_count     |     3 |
  # ============================================================
  # Rule: 審計日誌
  # ============================================================

  Rule: 管理員查詢用戶清單應記錄審計日誌

    Example: 記錄查詢行為
      Given 使用者 "admin@pegatron.com" 已登入
      When 使用者發送 GET 請求至 "/api/admin/users"
      Then 請求應成功
      And audit_logs 表應新增一筆記錄:
        | field       | value                                       |
        | action      | admin.users.list                            |
        | actor_id    | user-005                                    |
        | actor_email | admin@pegatron.com                          |
        | details     | {"filters": {}, "page": 1, "page_size": 20} |
        | ip_address  | (請求來源 IP)                               |
        | created_at  | (當前時間)                                  |
