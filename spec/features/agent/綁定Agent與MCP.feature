Feature: 綁定 Agent 與 MCP
  連接 MCP Server 賦予 Agent 外部工具能力

  Background:
    Given 系統中存在以下 Agent:
      | id        | name    | owner_id | status |
      | agent-001 | MathBot | user-001 | active |
      | agent-002 | CodeBot | user-002 | active |
    And 系統中存在以下 MCP Server:
      | id      | name           | status | owner_id | visibility | tools                     |
      | mcp-001 | WeatherService | active | user-001 | public     | get_weather, get_forecast |
      | mcp-002 | DatabaseTool   | active | user-001 | private    | query, insert, update     |
      | mcp-003 | EmailService   | active | user-002 | public     | send_email, list_emails   |
      | mcp-004 | BrokenService  | error  | user-001 | public     | broken_tool               |
      | mcp-005 | PrivateTool    | active | user-002 | private    | secret_operation          |
    And 使用者 "user-001" 已登入
  # ============================================================
  # Rule: 建立綁定關係
  # ============================================================

  Rule: 使用者可以將 MCP Server 綁定到自己的 Agent

    Example: 成功 - 綁定單一 MCP Server
      Given Agent "agent-001" 尚未綁定任何 MCP Server
      And agent_mcp_bindings 表中無 agent_id 為 "agent-001" 的記錄
      When 使用者 "user-001" 提交綁定請求:
        | agent_id | agent-001 |
        | mcp_ids  | mcp-001   |
      Then 請求應成功，回傳狀態碼 201
      And agent_mcp_bindings 表應新增一筆記錄:
        | agent_id  | mcp_id  | created_at |
        | agent-001 | mcp-001 | (當前時間) |
      And Agent "agent-001" 應能存取以下工具:
        | tool         | source         |
        | get_weather  | WeatherService |
        | get_forecast | WeatherService |

    Example: 成功 - 綁定多個 MCP Server
      When 使用者 "user-001" 提交綁定請求:
        | agent_id | agent-001       |
        | mcp_ids  | mcp-001,mcp-002 |
      Then 請求應成功
      And agent_mcp_bindings 表應新增兩筆記錄
      And Agent "agent-001" 可存取的工具數量應為 5

    Example: 成功 - 綁定公開的 MCP Server（非自己擁有）
      When 使用者 "user-001" 提交綁定請求:
        | agent_id | agent-001 |
        | mcp_ids  | mcp-003   |
      Then 請求應成功
      And Agent "agent-001" 應能存取 EmailService 的工具

    Example: 失敗 - 無法綁定 private MCP Server（非擁有者）
      When 使用者 "user-001" 提交綁定請求:
        | agent_id | agent-001 |
        | mcp_ids  | mcp-005   |
      Then 請求應失敗，回傳狀態碼 403
      And 錯誤訊息應為 "MCP Server 'PrivateTool' is private and not accessible"
      And agent_mcp_bindings 表應無新增記錄

    Example: 失敗 - 無法綁定狀態為 error 的 MCP Server
      When 使用者 "user-001" 提交綁定請求:
        | agent_id | agent-001 |
        | mcp_ids  | mcp-004   |
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "MCP Server 'BrokenService' is not available (status: error)"

    Example: 失敗 - MCP Server 不存在
      When 使用者 "user-001" 提交綁定請求:
        | agent_id | agent-001       |
        | mcp_ids  | non-existent-id |
      Then 請求應失敗，回傳狀態碼 404
      And 錯誤訊息應為 "MCP Server 'non-existent-id' not found"

    Example: 失敗 - 非 Agent 擁有者無法綁定
      When 使用者 "user-001" 提交綁定請求:
        | agent_id | agent-002 |
        | mcp_ids  | mcp-001   |
      Then 請求應失敗，回傳狀態碼 403
      And 錯誤訊息應為 "You do not have permission to modify this agent"
  # ============================================================
  # Rule: 重複綁定處理
  # ============================================================

  Rule: 系統應正確處理重複綁定的情況

    Example: 冪等性 - 重複綁定相同 MCP Server 不產生錯誤
      Given Agent "agent-001" 已綁定 MCP Server "mcp-001"
      And agent_mcp_bindings 表中有 1 筆 agent-001 與 mcp-001 的記錄
      When 使用者 "user-001" 再次提交綁定請求:
        | agent_id | agent-001 |
        | mcp_ids  | mcp-001   |
      Then 請求應成功，回傳狀態碼 200
      And agent_mcp_bindings 表中應維持 1 筆記錄（不新增重複）
      And 回傳訊息應標示 "already_bound": ["mcp-001"]

    Example: 部分新增 - 混合已綁定與未綁定的 MCP
      Given Agent "agent-001" 已綁定 MCP Server "mcp-001"
      When 使用者 "user-001" 提交綁定請求:
        | agent_id | agent-001       |
        | mcp_ids  | mcp-001,mcp-003 |
      Then 請求應成功
      And 回傳應標示:
        | already_bound | mcp-001 |
        | newly_bound   | mcp-003 |
      And agent_mcp_bindings 表應只新增 mcp-003 的記錄
  # ============================================================
  # Rule: 解除綁定
  # ============================================================

  Rule: 使用者可以解除 Agent 與 MCP Server 的綁定

    Example: 成功 - 解除單一綁定
      Given Agent "agent-001" 已綁定 MCP Server:
        | mcp_id  |
        | mcp-001 |
        | mcp-002 |
      When 使用者 "user-001" 提交解除綁定請求:
        | agent_id | agent-001 |
        | mcp_ids  | mcp-001   |
      Then 請求應成功，回傳狀態碼 200
      And agent_mcp_bindings 表應刪除 agent-001 與 mcp-001 的記錄
      And agent_mcp_bindings 表應保留 agent-001 與 mcp-002 的記錄
      And Agent "agent-001" 應無法再存取 WeatherService 的工具

    Example: 成功 - 解除所有綁定
      Given Agent "agent-001" 已綁定 3 個 MCP Server
      When 使用者 "user-001" 提交解除綁定請求:
        | agent_id   | agent-001 |
        | unbind_all | true      |
      Then 請求應成功
      And agent_mcp_bindings 表中 agent_id 為 "agent-001" 的記錄應全部刪除

    Example: 冪等性 - 解除不存在的綁定不產生錯誤
      Given Agent "agent-001" 未綁定 MCP Server "mcp-003"
      When 使用者 "user-001" 提交解除綁定請求:
        | agent_id | agent-001 |
        | mcp_ids  | mcp-003   |
      Then 請求應成功，回傳狀態碼 200
      And 回傳訊息應標示 "not_bound": ["mcp-003"]
  # ============================================================
  # Rule: 查詢綁定狀態
  # ============================================================

  Rule: 可以查詢 Agent 目前綁定的 MCP Server

    Example: 成功 - 查詢 Agent 的 MCP 綁定列表
      Given Agent "agent-001" 已綁定 MCP Server:
        | mcp_id  | bound_at            |
        | mcp-001 | 2024-01-01 10:00:00 |
        | mcp-002 | 2024-01-02 15:30:00 |
      When 使用者 "user-001" 查詢 Agent "agent-001" 的 MCP 綁定
      Then 請求應成功
      And 回傳結果應包含:
        | mcp_id  | name           | status | tools_count | bound_at            |
        | mcp-001 | WeatherService | active |           2 | 2024-01-01 10:00:00 |
        | mcp-002 | DatabaseTool   | active |           3 | 2024-01-02 15:30:00 |

    Example: 成功 - 查詢無綁定的 Agent
      Given Agent "agent-001" 未綁定任何 MCP Server
      When 使用者 "user-001" 查詢 Agent "agent-001" 的 MCP 綁定
      Then 請求應成功
      And 回傳的 data 陣列應為空
  # ============================================================
  # Rule: 綁定限制
  # ============================================================

  Rule: 系統對綁定數量有上限限制

    Example: 失敗 - 超過 MCP 綁定上限
      Given Agent "agent-001" 已綁定 10 個 MCP Server（達到上限）
      When 使用者 "user-001" 提交綁定請求:
        | agent_id | agent-001  |
        | mcp_ids  | new-mcp-id |
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "Agent has reached the maximum MCP binding limit (10)"
  # ============================================================
  # Rule: 工具衝突處理
  # ============================================================

  Rule: 當多個 MCP Server 有相同名稱的工具時需處理衝突

    Example: 警告 - 工具名稱衝突
      Given 系統中新增 MCP Server:
        | id      | name           | tools       |
        | mcp-006 | AnotherWeather | get_weather |
      And Agent "agent-001" 已綁定 MCP Server "mcp-001"（有 get_weather 工具）
      When 使用者 "user-001" 提交綁定請求:
        | agent_id | agent-001 |
        | mcp_ids  | mcp-006   |
      Then 請求應成功，但回傳警告:
        | warning   | Tool name conflict detected                                                |
        | conflicts | [{"tool": "get_weather", "sources": ["WeatherService", "AnotherWeather"]}] |
      And Agent 執行時應優先使用最後綁定的 MCP Server 的工具
