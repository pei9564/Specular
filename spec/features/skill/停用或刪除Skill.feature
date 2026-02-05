Feature: 停用或刪除 Skill
  管理與維護已上傳的 Skill

  Background:
    Given 系統中存在以下 Skills:
      | id        | name       | display_name | owner_id | status     | visibility |
      | skill-001 | calculator | Calculator   | system   | active     | public     |
      | skill-002 | email      | Email Sender | user-001 | active     | private    |
      | skill-003 | search     | Web Search   | user-001 | active     | public     |
      | skill-004 | deprecated | Old Tool     | user-001 | deprecated | public     |
      | skill-005 | other_user | Other Skill  | user-002 | active     | private    |
    And 系統中存在以下 Agent-Skill 綁定:
      | agent_id  | skill_id  |
      | agent-001 | skill-001 |
      | agent-002 | skill-001 |
      | agent-003 | skill-002 |
    And 使用者 "user-001" 已登入
  # ============================================================
  # Rule: 停用 Skill
  # ============================================================

  Rule: 擁有者或管理員可以停用 Skill

    Example: 成功 - 停用自己的 Skill
      Given Skill "skill-002" 的 status 為 "active"
      When 使用者發送 PATCH 請求至 "/api/skills/skill-002":
        | status | disabled |
      Then 請求應成功，回傳狀態碼 200
      And skills 表中 skill-002 應更新:
        | field       | old_value | new_value  |
        | status      | active    | disabled   |
        | disabled_at | null      | (當前時間) |
        | disabled_by | null      | user-001   |
        | updated_at  | (原時間)  | (當前時間) |
      And 回傳結果應包含:
        | field   | value                       |
        | status  | disabled                    |
        | message | Skill disabled successfully |

    Example: 停用後 Skill 不可被新 Agent 綁定
      Given Skill "skill-002" 的 status 為 "disabled"
      When 使用者嘗試將 Agent 綁定到 skill-002
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "Skill 'Email Sender' is disabled and cannot be bound to agents"

    Example: 停用後已綁定的 Agent 仍可使用（但顯示警告）
      Given Skill "skill-002" 被 Agent "agent-003" 使用
      When 使用者停用 skill-002
      Then 請求應成功
      And Agent "agent-003" 仍可調用該 Skill
      And 回傳應包含警告:
        | warning         | 1 agent is still using this skill |
        | affected_agents | ["agent-003"]                     |

    Example: 成功 - 管理員停用系統 Skill
      Given 使用者 "admin@example.com" 已登入（角色為 admin）
      When 使用者發送 PATCH 請求至 "/api/skills/skill-001":
        | status | disabled |
      Then 請求應成功
      And skills 表中 skill-001 的 status 應為 "disabled"

    Example: 失敗 - 非擁有者無法停用
      When 使用者 "user-001" 發送 PATCH 請求至 "/api/skills/skill-005":
        | status | disabled |
      Then 請求應失敗，回傳狀態碼 403
      And 錯誤訊息應為 "You do not have permission to modify this skill"
  # ============================================================
  # Rule: 重新啟用 Skill
  # ============================================================

  Rule: 已停用的 Skill 可以重新啟用

    Example: 成功 - 重新啟用 Skill
      Given Skill "skill-004" 的 status 為 "deprecated"
      When 使用者發送 PATCH 請求至 "/api/skills/skill-004":
        | status | active |
      Then 請求應成功
      And skills 表中 skill-004 應更新:
        | field       | old_value  | new_value |
        | status      | deprecated | active    |
        | disabled_at | (時間)     | null      |
        | disabled_by | (用戶)     | null      |
  # ============================================================
  # Rule: 軟刪除 Skill
  # ============================================================

  Rule: 未被使用的 Skill 可以軟刪除

    Example: 成功 - 刪除未被使用的 Skill
      Given Skill "skill-003" 未被任何 Agent 使用
      When 使用者發送 DELETE 請求至 "/api/skills/skill-003"
      Then 請求應成功，回傳狀態碼 200
      And skills 表中 skill-003 應更新:
        | field      | value      |
        | status     | deleted    |
        | deleted_at | (當前時間) |
        | deleted_by | user-001   |
      And Skill 不應出現在任何列表查詢中

    Example: 失敗 - 無法刪除被使用的 Skill
      Given Skill "skill-002" 被 Agent "agent-003" 使用
      When 使用者發送 DELETE 請求至 "/api/skills/skill-002"
      Then 請求應失敗，回傳狀態碼 409
      And 錯誤訊息應為 "Cannot delete skill: 1 agent is using this skill"
      And 回傳應包含:
        | affected_agents | ["agent-003"] |

    Example: 成功 - 強制刪除並解除綁定
      Given Skill "skill-002" 被 Agent "agent-003" 使用
      When 使用者發送 DELETE 請求至 "/api/skills/skill-002":
        | force | true |
      Then 請求應成功
      And skills 表中 skill-002 的 status 應為 "deleted"
      And agent_skill_bindings 表中 skill_id 為 "skill-002" 的記錄應被刪除
      And 回傳應包含:
        | message          | Skill deleted and 1 binding removed |
        | removed_bindings |                                   1 |
  # ============================================================
  # Rule: 硬刪除 Skill
  # ============================================================

  Rule: 管理員可以永久刪除 Skill

    Example: 成功 - 永久刪除（硬刪除）
      Given 使用者 "admin@example.com" 已登入
      And Skill "skill-003" 未被使用
      When 使用者發送 DELETE 請求至 "/api/skills/skill-003":
        | permanent | true |
        | confirm   | true |
      Then 請求應成功
      And skills 表中應不存在 id 為 "skill-003" 的記錄
      And skill_functions 表中 skill_id 為 "skill-003" 的記錄應被刪除
      And Skill 檔案應從儲存中刪除

    Example: 失敗 - 硬刪除需要確認
      When 使用者發送 DELETE 請求至 "/api/skills/skill-003":
        | permanent | true |
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "Permanent deletion requires confirmation. Set confirm=true to proceed."
  # ============================================================
  # Rule: 恢復已刪除的 Skill
  # ============================================================

  Rule: 軟刪除的 Skill 可以恢復

    Example: 成功 - 恢復已刪除的 Skill
      Given Skill "skill-003" 已被軟刪除（status = deleted）
      When 使用者發送 POST 請求至 "/api/skills/skill-003/restore"
      Then 請求應成功
      And skills 表中 skill-003 應更新:
        | field      | old_value | new_value |
        | status     | deleted   | active    |
        | deleted_at | (時間)    | null      |
        | deleted_by | user-001  | null      |

    Example: 查詢已刪除的 Skill（用於恢復）
      Given 有 Skill 被軟刪除
      When 使用者發送 GET 請求至 "/api/skills":
        | include_deleted | true |
      Then 回傳結果應包含已刪除的 Skill
      And 已刪除 Skill 的 status 應為 "deleted"
  # ============================================================
  # Rule: 批次操作
  # ============================================================

  Rule: 支援批次停用或刪除

    Example: 成功 - 批次停用
      When 使用者發送 PATCH 請求至 "/api/skills/batch":
        | ids    | ["skill-002", "skill-003"] |
        | status | disabled                   |
      Then 請求應成功
      And skill-002 和 skill-003 的 status 應為 "disabled"
      And 回傳結果應包含:
        | updated_count | 2 |

    Example: 批次刪除部分失敗
      When 使用者發送 DELETE 請求至 "/api/skills/batch":
        | ids | ["skill-002", "skill-003", "skill-005"] |
      Then 請求應部分成功，回傳狀態碼 207
      And 回傳結果應包含:
        | deleted_count | 1 |
        | failed_count  | 2 |
      And failed 陣列應包含:
        | id        | reason            |
        | skill-002 | Skill is in use   |
        | skill-005 | Permission denied |
  # ============================================================
  # Rule: 權限控制
  # ============================================================

  Rule: 只有擁有者或管理員可以停用/刪除 Skill

    Example: 失敗 - 一般用戶無法操作系統 Skill
      When 使用者 "user-001" 發送 PATCH 請求至 "/api/skills/skill-001":
        | status | disabled |
      Then 請求應失敗，回傳狀態碼 403

    Example: 失敗 - 無法操作他人的 Skill
      When 使用者 "user-001" 發送 DELETE 請求至 "/api/skills/skill-005"
      Then 請求應失敗，回傳狀態碼 403
  # ============================================================
  # Rule: 審計日誌
  # ============================================================

  Rule: 停用和刪除操作應記錄審計日誌

    Example: 記錄停用操作
      When 使用者停用 Skill
      Then audit_logs 表應新增一筆記錄:
        | field       | value                         |
        | action      | skill.disable                 |
        | actor_id    | user-001                      |
        | target_type | skill                         |
        | target_id   | skill-002                     |
        | details     | {"previous_status": "active"} |

    Example: 記錄刪除操作
      When 使用者刪除 Skill
      Then audit_logs 表應新增一筆記錄:
        | field   | value                                    |
        | action  | skill.delete                             |
        | details | {"type": "soft", "affected_bindings": 0} |

    Example: 記錄強制刪除
      When 使用者強制刪除被使用的 Skill
      Then audit_logs 記錄的 details 應包含:
        | force            | true          |
        | removed_bindings |             1 |
        | affected_agents  | ["agent-003"] |
