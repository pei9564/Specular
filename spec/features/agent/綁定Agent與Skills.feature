Feature: 綁定 Agent 與 Skills
  選擇已註冊的 Skills 賦予 Agent 能力

  Background:
    Given 系統中存在以下 Agent:
      | id        | name    | owner_id | status |
      | agent-001 | MathBot | user-001 | active |
      | agent-002 | CodeBot | user-002 | active |
    And 系統中存在以下 Skills:
      | id        | name        | status     | owner_id | visibility | function_name    | parameters_schema                     |
      | skill-001 | Calculator  | active     | system   | public     | calculate        | {"expression": "string"}              |
      | skill-002 | WebSearch   | active     | system   | public     | search_web       | {"query": "string", "limit": "int"}   |
      | skill-003 | SendEmail   | active     | user-001 | private    | send_email       | {"to": "string", "subject": "string"} |
      | skill-004 | CustomTool  | active     | user-002 | private    | custom_operation | {"input": "string"}                   |
      | skill-005 | Deprecated  | deprecated | system   | public     | old_function     | {"param": "string"}                   |
      | skill-006 | BrokenSkill | error      | system   | public     | broken_function  | {"param": "string"}                   |
    And 使用者 "user-001" 已登入
  # ============================================================
  # Rule: 建立綁定關係
  # ============================================================

  Rule: 使用者可以將 Skills 綁定到自己的 Agent

    Example: 成功 - 綁定單一 Skill
      Given Agent "agent-001" 尚未綁定任何 Skill
      And agent_skill_bindings 表中無 agent_id 為 "agent-001" 的記錄
      When 使用者 "user-001" 提交綁定請求:
        | agent_id  | agent-001 |
        | skill_ids | skill-001 |
      Then 請求應成功，回傳狀態碼 201
      And agent_skill_bindings 表應新增一筆記錄:
        | agent_id  | skill_id  | created_at | enabled |
        | agent-001 | skill-001 | (當前時間) | true    |
      And Agent "agent-001" 執行時應能調用 calculate 函數

    Example: 成功 - 綁定多個 Skills
      When 使用者 "user-001" 提交綁定請求:
        | agent_id  | agent-001           |
        | skill_ids | skill-001,skill-002 |
      Then 請求應成功
      And agent_skill_bindings 表應新增兩筆記錄
      And Agent "agent-001" 可用的函數應為:
        | function_name | source     |
        | calculate     | Calculator |
        | search_web    | WebSearch  |

    Example: 成功 - 綁定公開的系統 Skill
      When 使用者 "user-001" 提交綁定請求:
        | agent_id  | agent-001 |
        | skill_ids | skill-002 |
      Then 請求應成功
      And Agent "agent-001" 應能調用 WebSearch 的 search_web 函數

    Example: 成功 - 綁定自己的 private Skill
      When 使用者 "user-001" 提交綁定請求:
        | agent_id  | agent-001 |
        | skill_ids | skill-003 |
      Then 請求應成功
      And Agent "agent-001" 應能調用 SendEmail 的 send_email 函數

    Example: 失敗 - 無法綁定他人的 private Skill
      When 使用者 "user-001" 提交綁定請求:
        | agent_id  | agent-001 |
        | skill_ids | skill-004 |
      Then 請求應失敗，回傳狀態碼 403
      And 錯誤訊息應為 "Skill 'CustomTool' is private and not accessible"

    Example: 失敗 - 無法綁定 deprecated Skill
      When 使用者 "user-001" 提交綁定請求:
        | agent_id  | agent-001 |
        | skill_ids | skill-005 |
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "Skill 'Deprecated' is deprecated and cannot be used for new bindings"

    Example: 失敗 - 無法綁定狀態為 error 的 Skill
      When 使用者 "user-001" 提交綁定請求:
        | agent_id  | agent-001 |
        | skill_ids | skill-006 |
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "Skill 'BrokenSkill' is not available (status: error)"

    Example: 失敗 - Skill 不存在
      When 使用者 "user-001" 提交綁定請求:
        | agent_id  | agent-001       |
        | skill_ids | non-existent-id |
      Then 請求應失敗，回傳狀態碼 404
      And 錯誤訊息應為 "Skill 'non-existent-id' not found"

    Example: 失敗 - 非 Agent 擁有者無法綁定
      When 使用者 "user-001" 提交綁定請求:
        | agent_id  | agent-002 |
        | skill_ids | skill-001 |
      Then 請求應失敗，回傳狀態碼 403
      And 錯誤訊息應為 "You do not have permission to modify this agent"
  # ============================================================
  # Rule: 重複綁定處理
  # ============================================================

  Rule: 系統應正確處理重複綁定的情況

    Example: 冪等性 - 重複綁定相同 Skill 不產生錯誤
      Given Agent "agent-001" 已綁定 Skill "skill-001"
      When 使用者 "user-001" 再次提交綁定請求:
        | agent_id  | agent-001 |
        | skill_ids | skill-001 |
      Then 請求應成功，回傳狀態碼 200
      And agent_skill_bindings 表中應維持 1 筆記錄（不新增重複）
      And 回傳訊息應標示 "already_bound": ["skill-001"]
  # ============================================================
  # Rule: 解除綁定
  # ============================================================

  Rule: 使用者可以解除 Agent 與 Skill 的綁定

    Example: 成功 - 解除單一綁定
      Given Agent "agent-001" 已綁定 Skills:
        | skill_id  |
        | skill-001 |
        | skill-002 |
      When 使用者 "user-001" 提交解除綁定請求:
        | agent_id  | agent-001 |
        | skill_ids | skill-001 |
      Then 請求應成功，回傳狀態碼 200
      And agent_skill_bindings 表應刪除 agent-001 與 skill-001 的記錄
      And Agent "agent-001" 應無法再調用 calculate 函數
      And Agent "agent-001" 應仍能調用 search_web 函數

    Example: 成功 - 解除所有綁定
      Given Agent "agent-001" 已綁定 3 個 Skills
      When 使用者 "user-001" 提交解除綁定請求:
        | agent_id   | agent-001 |
        | unbind_all | true      |
      Then 請求應成功
      And agent_skill_bindings 表中 agent_id 為 "agent-001" 的記錄應全部刪除
  # ============================================================
  # Rule: 啟用/停用綁定
  # ============================================================

  Rule: 可以暫時停用已綁定的 Skill 而不解除綁定

    Example: 成功 - 停用已綁定的 Skill
      Given Agent "agent-001" 已綁定 Skill "skill-001"，且 enabled 為 true
      When 使用者 "user-001" 提交更新綁定請求:
        | agent_id | agent-001 |
        | skill_id | skill-001 |
        | enabled  | false     |
      Then 請求應成功
      And agent_skill_bindings 記錄應更新:
        | field   | old_value | new_value |
        | enabled | true      | false     |
      And Agent "agent-001" 執行時應無法調用 calculate 函數
      And Agent 的 tools 列表中不應包含 calculate

    Example: 成功 - 重新啟用已停用的 Skill
      Given Agent "agent-001" 已綁定 Skill "skill-001"，且 enabled 為 false
      When 使用者 "user-001" 提交更新綁定請求:
        | agent_id | agent-001 |
        | skill_id | skill-001 |
        | enabled  | true      |
      Then 請求應成功
      And Agent "agent-001" 執行時應能調用 calculate 函數
  # ============================================================
  # Rule: 查詢綁定狀態
  # ============================================================

  Rule: 可以查詢 Agent 目前綁定的 Skills

    Example: 成功 - 查詢 Agent 的 Skill 綁定列表
      Given Agent "agent-001" 已綁定 Skills:
        | skill_id  | bound_at            | enabled |
        | skill-001 | 2024-01-01 10:00:00 | true    |
        | skill-002 | 2024-01-02 15:30:00 | false   |
      When 使用者 "user-001" 查詢 Agent "agent-001" 的 Skill 綁定
      Then 請求應成功
      And 回傳結果應包含:
        | skill_id  | name       | function_name | enabled | bound_at            |
        | skill-001 | Calculator | calculate     | true    | 2024-01-01 10:00:00 |
        | skill-002 | WebSearch  | search_web    | false   | 2024-01-02 15:30:00 |

    Example: 成功 - 只查詢啟用中的 Skills
      Given Agent "agent-001" 已綁定 2 個 Skills，其中 1 個 enabled
      When 使用者 "user-001" 查詢 Agent "agent-001" 的 Skill 綁定:
        | enabled_only | true |
      Then 回傳結果應只包含 enabled 為 true 的 Skills
  # ============================================================
  # Rule: 綁定限制
  # ============================================================

  Rule: 系統對綁定數量有上限限制

    Example: 失敗 - 超過 Skill 綁定上限
      Given Agent "agent-001" 已綁定 20 個 Skills（達到上限）
      When 使用者 "user-001" 提交綁定請求:
        | agent_id  | agent-001    |
        | skill_ids | new-skill-id |
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "Agent has reached the maximum skill binding limit (20)"
  # ============================================================
  # Rule: 函數名稱衝突處理
  # ============================================================

  Rule: 當多個 Skills 有相同函數名稱時需處理衝突

    Example: 失敗 - 函數名稱衝突
      Given 系統中新增 Skill:
        | id        | name        | function_name |
        | skill-007 | AnotherCalc | calculate     |
      And Agent "agent-001" 已綁定 Skill "skill-001"（function_name 為 calculate）
      When 使用者 "user-001" 提交綁定請求:
        | agent_id  | agent-001 |
        | skill_ids | skill-007 |
      Then 請求應失敗，回傳狀態碼 409
      And 錯誤訊息應為 "Function name conflict: 'calculate' is already bound from skill 'Calculator'"

    Example: 成功 - 使用別名解決衝突
      Given 系統中新增 Skill:
        | id        | name        | function_name |
        | skill-007 | AnotherCalc | calculate     |
      And Agent "agent-001" 已綁定 Skill "skill-001"（function_name 為 calculate）
      When 使用者 "user-001" 提交綁定請求:
        | agent_id       | agent-001          |
        | skill_ids      | skill-007          |
        | function_alias | advanced_calculate |
      Then 請求應成功
      And Agent 可用的函數應為:
        | function_name      | source      |
        | calculate          | Calculator  |
        | advanced_calculate | AnotherCalc |
