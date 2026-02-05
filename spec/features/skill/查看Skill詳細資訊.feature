Feature: 查看 Skill 詳細資訊
  提供 Skill 的完整資訊展示與管理

  Background:
    Given 系統中存在以下 Skills:
      | id        | name       | display_name | owner_id | status | visibility | version |
      | skill-001 | calculator | Calculator   | system   | active | public     |   1.2.0 |
      | skill-002 | email      | Email Sender | user-001 | active | private    |   1.0.0 |
      | skill-003 | private    | Private Tool | user-002 | active | private    |   1.0.0 |
    And Skill "skill-001" 的 SKILL.md 內容為:
      """markdown
      # Calculator
      
      A powerful calculation tool for mathematical operations.
      
      ## Features
      - Basic arithmetic: add, subtract, multiply, divide
      - Advanced functions: power, sqrt, log
      
      ## Usage
      ```python
      result = add(1, 2)  # Returns 3
      ```
      """
    And Skill "skill-001" 的檔案結構為:
      | path               | size_bytes |
      | SKILL.md           |        512 |
      | __init__.py        |         64 |
      | functions.py       |       2048 |
      | requirements.txt   |        128 |
      | tests/test_calc.py |       1024 |
    And Skill "skill-001" 的函數定義:
      | function_name | description | parameters_schema                                  |
      | add           | 加法運算    | {"a": {"type": "number"}, "b": {"type": "number"}} |
      | subtract      | 減法運算    | {"a": {"type": "number"}, "b": {"type": "number"}} |
      | multiply      | 乘法運算    | {"a": {"type": "number"}, "b": {"type": "number"}} |
    And 使用者 "user-001" 已登入
  # ============================================================
  # Rule: 查詢 Skill 詳情
  # ============================================================

  Rule: 用戶可以查看自己有權限存取的 Skill 詳情

    Example: 成功 - 查看公開 Skill 詳情
      When 使用者發送 GET 請求至 "/api/skills/skill-001"
      Then 請求應成功，回傳狀態碼 200
      And 回傳結果應包含基本資訊:
        | field        | value                          |
        | id           | skill-001                      |
        | name         | calculator                     |
        | display_name | Calculator                     |
        | description  | A powerful calculation tool... |
        | version      |                          1.2.0 |
        | owner_id     | system                         |
        | owner_type   | system                         |
        | status       | active                         |
        | visibility   | public                         |
        | created_at   | (時間)                         |
        | updated_at   | (時間)                         |

    Example: 成功 - 包含函數詳情
      When 使用者發送 GET 請求至 "/api/skills/skill-001"
      Then 回傳結果應包含 functions 陣列:
        | function_name | description | return_type |
        | add           | 加法運算    | number      |
        | subtract      | 減法運算    | number      |
        | multiply      | 乘法運算    | number      |
      And 每個 function 應包含完整的 parameters_schema

    Example: 成功 - 查看自己的私有 Skill
      When 使用者 "user-001" 發送 GET 請求至 "/api/skills/skill-002"
      Then 請求應成功
      And 回傳結果應包含 skill-002 的完整詳情

    Example: 失敗 - 查看他人的私有 Skill
      When 使用者 "user-001" 發送 GET 請求至 "/api/skills/skill-003"
      Then 請求應失敗，回傳狀態碼 403
      And 錯誤訊息應為 "You do not have permission to access this skill"

    Example: 失敗 - Skill 不存在
      When 使用者發送 GET 請求至 "/api/skills/non-existent"
      Then 請求應失敗，回傳狀態碼 404
      And 錯誤訊息應為 "Skill not found"
  # ============================================================
  # Rule: 查看 SKILL.md 內容
  # ============================================================

  Rule: 可以獲取 Skill 的說明文件內容

    Example: 成功 - 查看 SKILL.md
      When 使用者發送 GET 請求至 "/api/skills/skill-001/readme"
      Then 請求應成功
      And 回傳結果應包含:
        | field   | value                           |
        | content | (SKILL.md 的完整 Markdown 內容) |
        | format  | markdown                        |

    Example: 成功 - 渲染為 HTML（可選）
      When 使用者發送 GET 請求至 "/api/skills/skill-001/readme":
        | render | html |
      Then 回傳結果應包含:
        | field   | value                |
        | content | (渲染後的 HTML 內容) |
        | format  | html                 |
  # ============================================================
  # Rule: 查看檔案結構
  # ============================================================

  Rule: 可以查看 Skill 的檔案結構

    Example: 成功 - 列出檔案結構
      When 使用者發送 GET 請求至 "/api/skills/skill-001/files"
      Then 請求應成功
      And 回傳結果應包含檔案樹:
        | path               | type   | size_bytes |
        | SKILL.md           | file   |        512 |
        | __init__.py        | file   |         64 |
        | functions.py       | file   |       2048 |
        | requirements.txt   | file   |        128 |
        | tests/             | folder | null       |
        | tests/test_calc.py | file   |       1024 |

    Example: 成功 - 查看特定檔案內容（擁有者）
      Given 使用者 "user-001" 為 skill-002 的擁有者
      When 使用者發送 GET 請求至 "/api/skills/skill-002/files/functions.py"
      Then 請求應成功
      And 回傳結果應包含檔案內容:
        | field    | value        |
        | path     | functions.py |
        | content  | (檔案內容)   |
        | encoding | utf-8        |

    Example: 失敗 - 非擁有者無法查看程式碼
      When 使用者 "user-001" 發送 GET 請求至 "/api/skills/skill-001/files/functions.py"
      Then 請求應失敗，回傳狀態碼 403
      And 錯誤訊息應為 "Only the skill owner can view source files"
  # ============================================================
  # Rule: 下載 Skill
  # ============================================================

  Rule: 擁有者可以下載完整的 Skill 包

    Example: 成功 - 下載 Skill ZIP
      Given 使用者 "user-001" 為 skill-002 的擁有者
      When 使用者發送 GET 請求至 "/api/skills/skill-002/download"
      Then 請求應成功
      And Content-Type 應為 "application/zip"
      And Content-Disposition 應為 "attachment; filename=\"email-1.0.0.zip\""
      And 回傳的 ZIP 應包含 Skill 的所有檔案

    Example: 失敗 - 非擁有者無法下載
      When 使用者 "user-001" 發送 GET 請求至 "/api/skills/skill-001/download"
      Then 請求應失敗，回傳狀態碼 403
      And 錯誤訊息應為 "Only the skill owner can download the source package"

    Example: 成功 - 管理員可以下載任何 Skill
      Given 使用者 "admin@example.com" 已登入（角色為 admin）
      When 使用者發送 GET 請求至 "/api/skills/skill-001/download"
      Then 請求應成功
  # ============================================================
  # Rule: 版本歷史
  # ============================================================

  Rule: 可以查看 Skill 的版本歷史

    Example: 成功 - 查看版本歷史
      Given Skill "skill-001" 有以下版本:
        | version | created_at          | changes         |
        |   1.2.0 | 2024-01-15 00:00:00 | Added multiply  |
        |   1.1.0 | 2024-01-10 00:00:00 | Added subtract  |
        |   1.0.0 | 2024-01-01 00:00:00 | Initial release |
      When 使用者發送 GET 請求至 "/api/skills/skill-001/versions"
      Then 請求應成功
      And 回傳結果應包含所有版本:
        | version | is_latest | created_at          |
        |   1.2.0 | true      | 2024-01-15 00:00:00 |
        |   1.1.0 | false     | 2024-01-10 00:00:00 |
        |   1.0.0 | false     | 2024-01-01 00:00:00 |

    Example: 成功 - 查看特定版本詳情
      When 使用者發送 GET 請求至 "/api/skills/skill-001/versions/1.0.0"
      Then 請求應成功
      And 回傳結果應為版本 1.0.0 的詳情
  # ============================================================
  # Rule: 使用統計
  # ============================================================

  Rule: 可以查看 Skill 的使用統計（擁有者或管理員）

    Example: 成功 - 查看使用統計
      Given 使用者 "user-001" 為 skill-002 的擁有者
      When 使用者發送 GET 請求至 "/api/skills/skill-002/stats"
      Then 請求應成功
      And 回傳結果應包含:
        | field                 | value |
        | bound_agents_count    |     5 |
        | total_invocations     |  1234 |
        | invocations_today     |    56 |
        | avg_execution_time_ms |   150 |
        | error_rate_percent    |   2.5 |

    Example: 成功 - 查看呼叫趨勢
      When 使用者發送 GET 請求至 "/api/skills/skill-002/stats":
        | period | 7d |
      Then 回傳結果應包含每日呼叫趨勢:
        | date       | invocations | errors |
        | 2024-01-15 |         100 |      2 |
        | 2024-01-14 |          95 |      3 |
        | ...        | ...         | ...    |
  # ============================================================
  # Rule: 依賴資訊
  # ============================================================

  Rule: 顯示 Skill 的依賴套件資訊

    Example: 成功 - 查看依賴資訊
      When 使用者發送 GET 請求至 "/api/skills/skill-001"
      Then 回傳結果應包含 dependencies:
        | package | version_spec | installed_version |
        | numpy   | >=1.20.0     |            1.24.0 |
        | pandas  | >=2.0.0      |             2.1.0 |
