Feature: 查詢可用的 Skills 列表
  列出系統中已註冊且有效的 Skill

  Background:
    Given 系統中存在以下 Skills:
      | id        | name        | display_name | owner_id | status     | visibility | version | functions_count | created_at          |
      | skill-001 | calculator  | Calculator   | system   | active     | public     |   1.0.0 |               3 | 2024-01-01 00:00:00 |
      | skill-002 | web_search  | Web Search   | system   | active     | public     |   2.1.0 |               1 | 2024-01-02 00:00:00 |
      | skill-003 | email       | Email Sender | user-001 | active     | private    |   1.0.0 |               2 | 2024-01-03 00:00:00 |
      | skill-004 | deprecated  | Old Tool     | system   | deprecated | public     |   0.9.0 |               1 | 2023-01-01 00:00:00 |
      | skill-005 | broken      | Broken Skill | user-001 | error      | private    |   1.0.0 |               0 | 2024-01-04 00:00:00 |
      | skill-006 | private_sys | Private Tool | user-002 | active     | private    |   1.0.0 |               2 | 2024-01-05 00:00:00 |
    And skills 表的 functions 關聯:
      | skill_id  | function_name | description |
      | skill-001 | add           | 加法運算    |
      | skill-001 | subtract      | 減法運算    |
      | skill-001 | multiply      | 乘法運算    |
      | skill-002 | search_web    | 搜尋網頁    |
      | skill-003 | send_email    | 發送郵件    |
      | skill-003 | list_emails   | 列出郵件    |
    And 使用者 "user-001" 已登入
  # ============================================================
  # Rule: 查詢可用 Skills
  # ============================================================

  Rule: 用戶可以查詢自己可使用的 Skills

    Example: 成功 - 查詢所有可用 Skills
      When 使用者發送 GET 請求至 "/api/skills"
      Then 請求應成功，回傳狀態碼 200
      And 回傳結果應包含:
        | field | value |
        | total |     3 |
      And data 陣列應包含（公開 + 自己的 private）:
        | id        | name       | visibility |
        | skill-001 | calculator | public     |
        | skill-002 | web_search | public     |
        | skill-003 | email      | private    |
      And 回傳結果不應包含:
        | id        | reason               |
        | skill-004 | status 為 deprecated |
        | skill-005 | status 為 error      |
        | skill-006 | private 且非擁有者   |

    Example: 回傳欄位應包含基本資訊
      When 使用者發送 GET 請求至 "/api/skills"
      Then 每筆 Skill 應包含以下欄位:
        | field           | type     | description              |
        | id              | string   | Skill UUID               |
        | name            | string   | Skill 名稱（程式碼用）   |
        | display_name    | string   | 顯示名稱                 |
        | description     | string   | 描述（從 SKILL.md 摘取） |
        | version         | string   | 版本號                   |
        | owner_id        | string   | 擁有者 ID                |
        | owner_type      | string   | system 或 user           |
        | visibility      | string   | public 或 private        |
        | functions_count | number   | 工具函數數量             |
        | tags            | array    | 標籤（用於分類）         |
        | created_at      | datetime | 建立時間                 |
  # ============================================================
  # Rule: 分頁功能
  # ============================================================

  Rule: Skills 列表支援分頁

    Example: 成功 - 分頁查詢
      Given 系統中有 25 個可用的 Skills
      When 使用者發送 GET 請求至 "/api/skills":
        | page      |  2 |
        | page_size | 10 |
      Then 請求應成功
      And 回傳結果應包含:
        | total       | 25 |
        | page        |  2 |
        | page_size   | 10 |
        | total_pages |  3 |
      And data 陣列應包含 10 筆 Skill
  # ============================================================
  # Rule: 篩選功能
  # ============================================================

  Rule: 支援依條件篩選 Skills

    Example: 依擁有者類型篩選 - 系統 Skills
      When 使用者發送 GET 請求至 "/api/skills":
        | owner_type | system |
      Then 回傳結果應只包含 owner_type 為 "system" 的 Skills:
        | name       |
        | calculator |
        | web_search |

    Example: 依擁有者類型篩選 - 用戶 Skills
      When 使用者發送 GET 請求至 "/api/skills":
        | owner_type | user |
      Then 回傳結果應只包含用戶上傳的 Skills

    Example: 只查詢自己的 Skills
      When 使用者發送 GET 請求至 "/api/skills":
        | owner_id | me |
      Then 回傳結果應只包含使用者 "user-001" 擁有的 Skills:
        | name  |
        | email |

    Example: 依標籤篩選
      Given Skills 有以下標籤:
        | skill_id  | tags              |
        | skill-001 | math, calculation |
        | skill-002 | search, web       |
      When 使用者發送 GET 請求至 "/api/skills":
        | tags | math |
      Then 回傳結果應只包含帶有 "math" 標籤的 Skills

    Example: 依 visibility 篩選
      When 使用者發送 GET 請求至 "/api/skills":
        | visibility | public |
      Then 回傳結果應只包含 visibility 為 "public" 的 Skills
  # ============================================================
  # Rule: 搜尋功能
  # ============================================================

  Rule: 支援關鍵字搜尋 Skills

    Example: 搜尋名稱或描述
      When 使用者發送 GET 請求至 "/api/skills":
        | search | calc |
      Then 回傳結果應包含 name 或 description 含有 "calc" 的 Skills:
        | name       |
        | calculator |

    Example: 搜尋不區分大小寫
      When 使用者發送 GET 請求至 "/api/skills":
        | search | CALCULATOR |
      Then 回傳結果應包含 "calculator"

    Example: 搜尋函數名稱
      When 使用者發送 GET 請求至 "/api/skills":
        | search        | send_email |
        | search_fields | functions  |
      Then 回傳結果應包含包含 "send_email" 函數的 Skill:
        | name  |
        | email |
  # ============================================================
  # Rule: 排序功能
  # ============================================================

  Rule: 支援依不同欄位排序

    Example: 預設依名稱排序
      When 使用者發送 GET 請求至 "/api/skills"
      Then 回傳結果應依 display_name 字母順序排列

    Example: 依建立時間排序
      When 使用者發送 GET 請求至 "/api/skills":
        | sort_by | created_at |
        | order   | desc       |
      Then 回傳結果應依 created_at 降序排列

    Example: 依使用量排序（最熱門）
      When 使用者發送 GET 請求至 "/api/skills":
        | sort_by | usage_count |
        | order   | desc        |
      Then 回傳結果應依被 Agent 綁定次數降序排列
  # ============================================================
  # Rule: 管理員查詢
  # ============================================================

  Rule: 管理員可以查詢所有 Skills 包含非活躍狀態

    Example: 管理員查詢所有 Skills
      Given 使用者 "admin@example.com" 已登入（角色為 admin）
      When 使用者發送 GET 請求至 "/api/admin/skills"
      Then 請求應成功
      And 回傳結果應包含所有 Skills（含 deprecated 和 error 狀態）:
        | id        | status     |
        | skill-001 | active     |
        | skill-002 | active     |
        | skill-003 | active     |
        | skill-004 | deprecated |
        | skill-005 | error      |
        | skill-006 | active     |

    Example: 管理員篩選特定狀態
      Given 使用者 "admin@example.com" 已登入
      When 使用者發送 GET 請求至 "/api/admin/skills":
        | status | deprecated,error |
      Then 回傳結果應只包含 status 為 deprecated 或 error 的 Skills
  # ============================================================
  # Rule: 包含函數列表
  # ============================================================

  Rule: 可選擇性包含函數詳情

    Example: 包含函數列表
      When 使用者發送 GET 請求至 "/api/skills":
        | include_functions | true |
      Then 每筆 Skill 應包含 functions 陣列:
        | skill_id  | functions                                |
        | skill-001 | [{name: "add"}, {name: "subtract"}, ...] |
      And 每個 function 應包含:
        | field             | type   |
        | function_name     | string |
        | description       | string |
        | parameters_schema | object |
  # ============================================================
  # Rule: 相容性標籤
  # ============================================================

  Rule: Skills 應包含相容性資訊供 Agent 選擇

    Example: 回傳相容性資訊
      When 使用者發送 GET 請求至 "/api/skills"
      Then 每筆 Skill 應包含:
        | field                | description        |
        | python_version       | 支援的 Python 版本 |
        | dependencies         | 依賴套件列表       |
        | runtime_requirements | 執行環境需求       |
