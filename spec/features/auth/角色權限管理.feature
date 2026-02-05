Feature: 角色權限管理
  定義不同角色的權限邊界

  Background:
    Given 系統定義以下角色:
      | role  | description |
      | user  | 一般使用者  |
      | admin | 系統管理員  |
    And 系統定義以下權限:
      | permission      | description              |
      | agent:create    | 創建 Agent               |
      | agent:read      | 查看 Agent               |
      | agent:update    | 編輯 Agent               |
      | agent:delete    | 刪除 Agent               |
      | agent:read:all  | 查看所有 Agent（含他人） |
      | model:create    | 新增 LLM 供應商配置      |
      | model:read      | 查看 LLM 供應商配置      |
      | model:update    | 編輯 LLM 供應商配置      |
      | model:delete    | 刪除 LLM 供應商配置      |
      | user:read:all   | 查看所有用戶             |
      | user:update:all | 編輯所有用戶             |
      | system:config   | 系統設定                 |
      | audit:read      | 查看審計日誌             |
    And 角色權限對應:
      | role  | permissions                                                      |
      | user  | agent:create, agent:read, agent:update, agent:delete, model:read |
      | admin | (所有權限)                                                       |
    And 系統中存在以下用戶:
      | id        | email             | role  | status |
      | user-001  | user@example.com  | user  | active |
      | admin-001 | admin@example.com | admin | active |
  # ============================================================
  # Rule: User 角色權限
  # ============================================================

  Rule: User 角色只能管理自己的資源

    Example: User 可以創建 Agent
      Given 使用者 "user@example.com" 已登入（角色為 user）
      When 使用者發送 POST 請求至 "/api/agents":
        | name | MyAgent |
      Then 請求應成功，回傳狀態碼 201
      And 新建的 Agent 的 owner_id 應為 "user-001"

    Example: User 可以查看自己的 Agent
      Given 使用者 "user@example.com" 已登入
      And 系統中存在 Agent:
        | id        | name    | owner_id |
        | agent-001 | MyAgent | user-001 |
      When 使用者發送 GET 請求至 "/api/agents/agent-001"
      Then 請求應成功

    Example: User 無法查看他人的 private Agent
      Given 使用者 "user@example.com" 已登入
      And 系統中存在 Agent:
        | id        | name       | owner_id  | visibility |
        | agent-002 | OtherAgent | admin-001 | private    |
      When 使用者發送 GET 請求至 "/api/agents/agent-002"
      Then 請求應失敗，回傳狀態碼 403
      And 錯誤訊息應為 "You do not have permission to access this agent"

    Example: User 可以編輯自己的 Agent
      Given 使用者 "user@example.com" 已登入
      And 系統中存在 Agent:
        | id        | owner_id |
        | agent-001 | user-001 |
      When 使用者發送 PATCH 請求至 "/api/agents/agent-001":
        | name | UpdatedName |
      Then 請求應成功

    Example: User 無法編輯他人的 Agent
      Given 使用者 "user@example.com" 已登入
      And 系統中存在 Agent:
        | id        | owner_id  |
        | agent-002 | admin-001 |
      When 使用者發送 PATCH 請求至 "/api/agents/agent-002":
        | name | HackedName |
      Then 請求應失敗，回傳狀態碼 403

    Example: User 無法管理 LLM 模型供應商
      Given 使用者 "user@example.com" 已登入
      When 使用者發送 POST 請求至 "/api/admin/models":
        | provider | openai   |
        | api_key  | sk-xxxxx |
      Then 請求應失敗，回傳狀態碼 403
      And 錯誤訊息應為 "Admin access required"

    Example: User 可以查看可用的 LLM 模型列表
      Given 使用者 "user@example.com" 已登入
      When 使用者發送 GET 請求至 "/api/models"
      Then 請求應成功
      And 回傳結果應僅包含公開的模型資訊（不含 API Key）

    Example: User 無法查看全系統用戶列表
      Given 使用者 "user@example.com" 已登入
      When 使用者發送 GET 請求至 "/api/admin/users"
      Then 請求應失敗，回傳狀態碼 403

    Example: User 無法查看審計日誌
      Given 使用者 "user@example.com" 已登入
      When 使用者發送 GET 請求至 "/api/admin/audit-logs"
      Then 請求應失敗，回傳狀態碼 403
  # ============================================================
  # Rule: Admin 角色權限
  # ============================================================

  Rule: Admin 角色擁有完整系統管理權限

    Example: Admin 可以使用所有 Agent 功能
      Given 使用者 "admin@example.com" 已登入（角色為 admin）
      When 使用者發送 POST 請求至 "/api/agents":
        | name | AdminAgent |
      Then 請求應成功

    Example: Admin 可以查看所有 Agent（含他人）
      Given 使用者 "admin@example.com" 已登入
      And 系統中存在 Agent:
        | id        | owner_id | visibility |
        | agent-001 | user-001 | private    |
      When 使用者發送 GET 請求至 "/api/agents/agent-001"
      Then 請求應成功

    Example: Admin 可以編輯任何 Agent
      Given 使用者 "admin@example.com" 已登入
      And 系統中存在 Agent:
        | id        | owner_id |
        | agent-001 | user-001 |
      When 使用者發送 PATCH 請求至 "/api/agents/agent-001":
        | name | AdminUpdated |
      Then 請求應成功
      And Agent 應被更新

    Example: Admin 可以管理 LLM 模型供應商
      Given 使用者 "admin@example.com" 已登入
      When 使用者發送 POST 請求至 "/api/admin/models":
        | provider | openai   |
        | api_key  | sk-xxxxx |
        | enabled  | true     |
      Then 請求應成功，回傳狀態碼 201
      And model_providers 表應新增一筆記錄

    Example: Admin 可以查看全系統用戶列表
      Given 使用者 "admin@example.com" 已登入
      When 使用者發送 GET 請求至 "/api/admin/users"
      Then 請求應成功
      And 回傳結果應包含所有用戶

    Example: Admin 可以查看審計日誌
      Given 使用者 "admin@example.com" 已登入
      When 使用者發送 GET 請求至 "/api/admin/audit-logs"
      Then 請求應成功

    Example: Admin 可以修改系統設定
      Given 使用者 "admin@example.com" 已登入
      When 使用者發送 PUT 請求至 "/api/admin/settings":
        | max_agents_per_user | 10 |
      Then 請求應成功
  # ============================================================
  # Rule: 權限檢查 API
  # ============================================================

  Rule: 提供 API 讓前端檢查用戶權限

    Example: 查詢當前用戶權限
      Given 使用者 "user@example.com" 已登入
      When 使用者發送 GET 請求至 "/api/auth/permissions"
      Then 請求應成功
      And 回傳結果應包含:
        | field       | value                                                                        |
        | role        | user                                                                         |
        | permissions | ["agent:create", "agent:read", "agent:update", "agent:delete", "model:read"] |

    Example: 檢查特定權限
      Given 使用者 "user@example.com" 已登入
      When 使用者發送 GET 請求至 "/api/auth/permissions/check":
        | permission | model:create |
      Then 請求應成功
      And 回傳結果應為:
        | field   | value |
        | allowed | false |
  # ============================================================
  # Rule: 權限繼承與覆寫
  # ============================================================

  Rule: 資源層級權限可覆寫角色預設權限

    Example: Agent 共享給特定用戶
      Given 使用者 "user@example.com" 已登入
      And 系統中存在 Agent:
        | id        | owner_id  | visibility |
        | agent-002 | admin-001 | private    |
      And agent_shares 表中存在:
        | agent_id  | user_id  | permission |
        | agent-002 | user-001 | read       |
      When 使用者發送 GET 請求至 "/api/agents/agent-002"
      Then 請求應成功
      And 用戶應能查看該 Agent

    Example: 共享的 Agent 權限限制
      Given 使用者 "user@example.com" 已登入
      And agent_shares 表中存在:
        | agent_id  | user_id  | permission |
        | agent-002 | user-001 | read       |
      When 使用者發送 PATCH 請求至 "/api/agents/agent-002":
        | name | TryToUpdate |
      Then 請求應失敗，回傳狀態碼 403
      And 錯誤訊息應為 "You only have read permission for this agent"
  # ============================================================
  # Rule: 權限變更審計
  # ============================================================

  Rule: 權限相關操作應記錄審計日誌

    Example: 記錄權限拒絕事件
      Given 使用者 "user@example.com" 已登入
      When 使用者嘗試存取無權限的 API "/api/admin/users"
      Then 請求應失敗
      And audit_logs 表應新增一筆記錄:
        | field    | value                                                                    |
        | action   | permission.denied                                                        |
        | actor_id | user-001                                                                 |
        | details  | {"resource": "/api/admin/users", "required_permission": "user:read:all"} |
        | status   | denied                                                                   |

    Example: 記錄 Admin 越權操作
      Given 使用者 "admin@example.com" 已登入
      When 使用者編輯他人的 Agent
      Then 操作應成功
      And audit_logs 表應新增一筆記錄:
        | field      | value                    |
        | action     | agent.update             |
        | actor_id   | admin-001                |
        | actor_role | admin                    |
        | target_id  | (Agent ID)               |
        | details    | {"admin_override": true} |
  # ============================================================
  # Rule: 權限矩陣總覽
  # ============================================================

  Rule: 權限矩陣定義

    Example: 完整權限矩陣
      Then 系統權限矩陣應為:
        | API Endpoint          | Method | user       | admin |
        | /api/agents           | GET    | ✓          | ✓     |
        | /api/agents           | POST   | ✓          | ✓     |
        | /api/agents/:id       | GET    | own/public | ✓     |
        | /api/agents/:id       | PATCH  | own        | ✓     |
        | /api/agents/:id       | DELETE | own        | ✓     |
        | /api/models           | GET    | ✓          | ✓     |
        | /api/admin/models     | GET    | ✗          | ✓     |
        | /api/admin/models     | POST   | ✗          | ✓     |
        | /api/admin/models/:id | PATCH  | ✗          | ✓     |
        | /api/admin/models/:id | DELETE | ✗          | ✓     |
        | /api/admin/users      | GET    | ✗          | ✓     |
        | /api/admin/users/:id  | PATCH  | ✗          | ✓     |
        | /api/admin/audit-logs | GET    | ✗          | ✓     |
        | /api/admin/settings   | GET    | ✗          | ✓     |
        | /api/admin/settings   | PUT    | ✗          | ✓     |
