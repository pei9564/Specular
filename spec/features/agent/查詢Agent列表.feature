Feature: 查詢 Agent 列表
  查詢系統中已建立的 Agent 清單，包含狀態與基礎配置摘要

  Background:
    Given 系統中存在以下 Agent:
      | id        | name      | owner_id  | status   | mode     | visibility | model_id | skills_count | mcp_count |
      | agent-001 | MathBot   | user-001  | active   | chat     | public     | gpt-4o   |            2 |         0 |
      | agent-002 | CodeBot   | user-001  | active   | chat     | private    | claude-3 |            1 |         1 |
      | agent-003 | ChatBot   | user-002  | active   | chat     | public     | gpt-4o   |            0 |         0 |
      | agent-004 | SystemBot | admin-001 | active   | triggers | private    | gpt-4o   |            3 |         2 |
      | agent-005 | OldBot    | user-001  | inactive | chat     | public     | gpt-3.5  |            0 |         0 |
      | agent-006 | TestBot   | user-002  | draft    | chat     | private    | gpt-4o   |            0 |         0 |
    And 使用者角色定義:
      | user_id   | role  |
      | user-001  | user  |
      | user-002  | user  |
      | admin-001 | admin |
  # ============================================================
  # Rule: 基本列表查詢
  # ============================================================

  Rule: 回傳使用者可見的 Agent 列表與摘要資訊

    Example: 成功 - 查詢所有可見 Agent
      Given 使用者 "user-001" 已登入
      # API: GET /api/v1/agents
      When 使用者發送 GET 請求至 "/api/v1/agents"，不帶任何篩選條件
      Then 請求應成功，回傳狀態碼 200
      And 回傳結果應包含:
        | id        | name    | model    | mode | capabilities      | status   |
        | agent-001 | MathBot | gpt-4o   | chat | Skills: 2, MCP: 0 | active   |
        | agent-002 | CodeBot | claude-3 | chat | Skills: 1, MCP: 1 | active   |
        | agent-003 | ChatBot | gpt-4o   | chat | Skills: 0, MCP: 0 | active   |
        | agent-005 | OldBot  | gpt-3.5  | chat | Skills: 0, MCP: 0 | inactive |
      And 回傳結果不應包含 "SystemBot"（private 且非擁有者）
      And 回傳結果不應包含 "TestBot"（private 且非擁有者）

    Example: 成功 - 管理員可見所有 Agent
      Given 使用者 "admin-001" 已登入
      # API: GET /api/v1/agents
      When 使用者發送 GET 請求至 "/api/v1/agents"
      Then 回傳結果應包含 6 筆 Agent
      And 應包含所有 private Agent
  # ============================================================
  # Rule: 分頁功能
  # ============================================================

  Rule: 支援分頁查詢以處理大量 Agent

    Example: 成功 - 預設分頁（第一頁）
      Given 使用者 "admin-001" 已登入
      # API: GET /api/v1/agents?page=1&page_size=2
      When 使用者發送 GET 請求至 "/api/v1/agents":
        | page      | 1 |
        | page_size | 2 |
      Then 請求應成功
      And 回傳結果應包含:
        | total | page | page_size | total_pages |
        |     6 |    1 |         2 |           3 |
      And data 陣列應包含 2 筆 Agent

    Example: 成功 - 查詢第二頁
      Given 使用者 "admin-001" 已登入
      # API: GET /api/v1/agents?page=2&page_size=2
      When 使用者發送 GET 請求至 "/api/v1/agents":
        | page      | 2 |
        | page_size | 2 |
      Then 回傳的 data 應從第 3 筆 Agent 開始
      And data 陣列應包含 2 筆 Agent

    Example: 成功 - 查詢超出範圍的頁數
      Given 使用者 "admin-001" 已登入
      # API: GET /api/v1/agents?page=100&page_size=10
      When 使用者發送 GET 請求至 "/api/v1/agents":
        | page      | 100 |
        | page_size |  10 |
      Then 請求應成功
      And data 陣列應為空
      And total 應為 6

    Example: 失敗 - 無效的分頁參數
      # API: GET /api/v1/agents?page=-1&page_size=0
      When 使用者發送 GET 請求至 "/api/v1/agents":
        | page      | -1 |
        | page_size |  0 |
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "Invalid pagination parameters"
  # ============================================================
  # Rule: 關鍵字搜尋
  # ============================================================

  Rule: 支援依名稱與描述進行關鍵字搜尋

    Example: 成功 - 搜尋名稱包含關鍵字
      Given 使用者 "user-001" 已登入
      # API: GET /api/v1/agents?search=Bot
      When 使用者發送 GET 請求至 "/api/v1/agents":
        | search | Bot |
      Then 回傳結果應包含所有名稱含 "Bot" 的可見 Agent:
        | name    |
        | MathBot |
        | CodeBot |
        | ChatBot |
        | OldBot  |

    Example: 成功 - 搜尋特定名稱
      Given 使用者 "user-001" 已登入
      # API: GET /api/v1/agents?search=Code
      When 使用者發送 GET 請求至 "/api/v1/agents":
        | search | Code |
      Then 回傳結果應僅包含:
        | name    |
        | CodeBot |

    Example: 成功 - 無符合結果
      Given 使用者 "user-001" 已登入
      # API: GET /api/v1/agents?search=NonExistent
      When 使用者發送 GET 請求至 "/api/v1/agents":
        | search | NonExistent |
      Then 請求應成功
      And data 陣列應為空
      And total 應為 0

    Example: 成功 - 搜尋不區分大小寫
      Given 使用者 "user-001" 已登入
      # API: GET /api/v1/agents?search=mathbot
      When 使用者發送 GET 請求至 "/api/v1/agents":
        | search | mathbot |
      Then 回傳結果應包含 "MathBot"
  # ============================================================
  # Rule: 狀態篩選
  # ============================================================

  Rule: 支援依 Agent 狀態篩選

    Example: 成功 - 只查詢 active Agent
      Given 使用者 "user-001" 已登入
      # API: GET /api/v1/agents?status=active
      When 使用者發送 GET 請求至 "/api/v1/agents":
        | status | active |
      Then 回傳結果不應包含 status 為 "inactive" 的 Agent
      And 回傳結果不應包含 "OldBot"

    Example: 成功 - 只查詢 inactive Agent
      Given 使用者 "user-001" 已登入
      # API: GET /api/v1/agents?status=inactive
      When 使用者發送 GET 請求至 "/api/v1/agents":
        | status | inactive |
      Then 回傳結果應僅包含:
        | name   | status   |
        | OldBot | inactive |

    Example: 成功 - 查詢多種狀態
      Given 使用者 "user-001" 已登入
      # API: GET /api/v1/agents?status=active,inactive
      When 使用者發送 GET 請求至 "/api/v1/agents":
        | status | active,inactive |
      Then 回傳結果應包含 status 為 "active" 或 "inactive" 的 Agent
  # ============================================================
  # Rule: 權限過濾
  # ============================================================

  Rule: 依據使用者權限過濾可見的 Agent

    Example: 一般使用者只能看見公開或自己的 Agent
      Given 使用者 "user-002" 已登入
      # API: GET /api/v1/agents
      When 使用者發送 GET 請求至 "/api/v1/agents"
      Then 回傳結果應包含:
        | name    | reason                   |
        | MathBot | public                   |
        | ChatBot | 自己擁有且 public        |
        | OldBot  | public                   |
        | TestBot | 自己擁有（即使 private） |
      And 回傳結果不應包含:
        | name      | reason             |
        | CodeBot   | private 且非擁有者 |
        | SystemBot | private 且非擁有者 |

    Example: 使用 owner_id 篩選只看自己的 Agent
      Given 使用者 "user-001" 已登入
      # API: GET /api/v1/agents?owner_id=user-001
      When 使用者發送 GET 請求至 "/api/v1/agents":
        | owner_id | user-001 |
      Then 回傳結果應僅包含:
        | name    | owner_id |
        | MathBot | user-001 |
        | CodeBot | user-001 |
        | OldBot  | user-001 |

    Example: 失敗 - 一般使用者無法查詢他人的 private Agent
      Given 使用者 "user-001" 已登入
      # API: GET /api/v1/agents?owner_id=user-002
      When 使用者發送 GET 請求至 "/api/v1/agents":
        | owner_id | user-002 |
      Then 回傳結果應僅包含 user-002 的公開 Agent:
        | name    |
        | ChatBot |
      And 回傳結果不應包含 "TestBot"（private）
  # ============================================================
  # Rule: 排序功能
  # ============================================================

  Rule: 支援依不同欄位排序

    Example: 預設依建立時間降序
      Given 使用者 "user-001" 已登入
      # API: GET /api/v1/agents
      When 使用者發送 GET 請求至 "/api/v1/agents"，不指定排序
      Then 回傳結果應依 created_at 降序排列

    Example: 依名稱升序排序
      Given 使用者 "user-001" 已登入
      # API: GET /api/v1/agents?sort_by=name&order=asc
      When 使用者發送 GET 請求至 "/api/v1/agents":
        | sort_by | name |
        | order   | asc  |
      Then 回傳結果第一筆應為 "ChatBot"
      And 回傳結果最後一筆應為 "OldBot"

    Example: 依更新時間降序排序
      Given 使用者 "user-001" 已登入
      # API: GET /api/v1/agents?sort_by=updated_at&order=desc
      When 使用者發送 GET 請求至 "/api/v1/agents":
        | sort_by | updated_at |
        | order   | desc       |
      Then 回傳結果應依最近更新的 Agent 優先
  # ============================================================
  # Rule: 回傳欄位
  # ============================================================

  Rule: 列表回傳摘要資訊，詳細資訊需呼叫單一查詢 API

    Example: 列表項目包含必要摘要欄位
      Given 使用者 "user-001" 已登入
      # API: GET /api/v1/agents
      When 使用者發送 GET 請求至 "/api/v1/agents"
      Then 每筆 Agent 應包含以下欄位:
        | field        | type     | description                 |
        | id           | string   | Agent UUID                  |
        | name         | string   | Agent 名稱                  |
        | description  | string   | Agent 描述（截斷至 100 字） |
        | model_id     | string   | 使用的 LLM 模型             |
        | mode         | string   | chat 或 triggers            |
        | status       | string   | active/inactive/draft       |
        | skills_count | number   | 綁定的 Skills 數量          |
        | mcp_count    | number   | 綁定的 MCP Server 數量      |
        | owner_id     | string   | 擁有者 ID                   |
        | created_at   | datetime | 建立時間                    |
        | updated_at   | datetime | 最後更新時間                |
      And 每筆 Agent 不應包含 system_prompt（安全考量）
      And 每筆 Agent 不應包含 model_config 詳細參數
