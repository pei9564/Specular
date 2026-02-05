Feature: 查看 MCP Server 工具清單
  查看已連接 MCP Server 提供的工具函數

  Background:
    Given 系統中存在以下 MCP Servers:
      | id      | name            | owner_id | status | transport_type | url                         |
      | mcp-001 | Weather Service | user-001 | active | sse            | https://weather.example.com |
      | mcp-002 | File Manager    | user-001 | active | stdio          | (local command)             |
      | mcp-003 | Offline Service | user-001 | error  | sse            | https://offline.example.com |
      | mcp-004 | Private MCP     | user-002 | active | sse            | https://private.example.com |
    And MCP Server "mcp-001" 提供以下工具:
      | name         | description      | input_schema                                                            |
      | get_weather  | 查詢指定城市天氣 | {"city": {"type": "string", "required": true}}                          |
      | get_forecast | 查詢未來天氣預報 | {"city": {"type": "string"}, "days": {"type": "integer", "default": 7}} |
      | set_alert    | 設定天氣警報     | {"city": {"type": "string"}, "threshold": {"type": "number"}}           |
    And 使用者 "user-001" 已登入
  # ============================================================
  # Rule: 查詢 MCP Server 工具列表
  # ============================================================

  Rule: 用戶可以查詢 MCP Server 提供的工具

    Example: 成功 - 列出工具清單
      When 使用者發送 GET 請求至 "/api/mcp-servers/mcp-001/tools"
      Then 請求應成功，回傳狀態碼 200
      And 回傳結果應包含:
        | field | value |
        | total |     3 |
      And data 陣列應包含所有工具:
        | name         | description      |
        | get_weather  | 查詢指定城市天氣 |
        | get_forecast | 查詢未來天氣預報 |
        | set_alert    | 設定天氣警報     |
      And 每個工具應包含以下欄位:
        | field        | type   | description          |
        | name         | string | 工具名稱             |
        | description  | string | 工具描述             |
        | input_schema | object | 輸入參數 JSON Schema |

    Example: 成功 - 工具包含完整 Schema
      When 使用者發送 GET 請求至 "/api/mcp-servers/mcp-001/tools"
      Then 工具 "get_weather" 的 input_schema 應為:
        """json
        {
          "type": "object",
          "properties": {
            "city": {
              "type": "string",
              "description": "城市名稱"
            }
          },
          "required": ["city"]
        }
        """

    Example: 成功 - 從快取回傳（如有）
      Given MCP Server "mcp-001" 的工具清單已快取
      And 快取時間未超過 5 分鐘
      When 使用者發送 GET 請求至 "/api/mcp-servers/mcp-001/tools"
      Then 系統應直接回傳快取結果
      And 回傳標頭應包含:
        | X-Cache-Status | HIT |
  # ============================================================
  # Rule: 即時查詢工具列表
  # ============================================================

  Rule: 可以強制即時向 MCP Server 查詢工具列表

    Example: 成功 - 強制重新查詢
      When 使用者發送 GET 請求至 "/api/mcp-servers/mcp-001/tools":
        | refresh | true |
      Then 系統應向 MCP Server 發送 ListTools 請求
      And mcp_server_tools 表應更新工具快取
      And 回傳標頭應包含:
        | X-Cache-Status | MISS |

    Example: 成功 - 記錄工具查詢
      When 系統向 MCP Server 查詢工具列表
      Then mcp_servers 表中 mcp-001 應更新:
        | field            | value      |
        | tools_updated_at | (當前時間) |
        | tools_count      |          3 |
  # ============================================================
  # Rule: MCP Server 連線狀態
  # ============================================================

  Rule: 只有連線正常的 MCP Server 可以查詢工具

    Example: 失敗 - MCP Server 狀態為 error
      Given MCP Server "mcp-003" 的 status 為 "error"
      When 使用者發送 GET 請求至 "/api/mcp-servers/mcp-003/tools"
      Then 請求應失敗，回傳狀態碼 503
      And 錯誤訊息應為 "MCP Server 'Offline Service' is not available (status: error)"
      And 回傳應包含:
        | last_error | (上次錯誤訊息) |

    Example: 失敗 - MCP Server 連線逾時
      Given MCP Server "mcp-001" 無法在 30 秒內回應
      When 使用者發送 GET 請求至 "/api/mcp-servers/mcp-001/tools":
        | refresh | true |
      Then 請求應失敗，回傳狀態碼 504
      And 錯誤訊息應為 "MCP Server connection timed out"
      And mcp_servers 表中 mcp-001 的 status 應更新為 "error"

    Example: 成功 - 連線失敗時回傳快取（如有）
      Given MCP Server "mcp-001" 目前無法連線
      And 有先前快取的工具清單
      When 使用者發送 GET 請求至 "/api/mcp-servers/mcp-001/tools"
      Then 請求應成功
      And 回傳快取的工具清單
      And 回傳應包含警告:
        | warning   | Using cached tools list. Server may be temporarily unavailable. |
        | cached_at | (快取時間)                                                      |
  # ============================================================
  # Rule: 權限控制
  # ============================================================

  Rule: 用戶只能查詢自己有權限的 MCP Server

    Example: 失敗 - 查詢他人的 private MCP Server
      When 使用者 "user-001" 發送 GET 請求至 "/api/mcp-servers/mcp-004/tools"
      Then 請求應失敗，回傳狀態碼 403
      And 錯誤訊息應為 "You do not have permission to access this MCP Server"

    Example: 失敗 - MCP Server 不存在
      When 使用者發送 GET 請求至 "/api/mcp-servers/non-existent/tools"
      Then 請求應失敗，回傳狀態碼 404
      And 錯誤訊息應為 "MCP Server not found"
  # ============================================================
  # Rule: 工具詳情
  # ============================================================

  Rule: 可以查詢單一工具的詳細資訊

    Example: 成功 - 查詢特定工具詳情
      When 使用者發送 GET 請求至 "/api/mcp-servers/mcp-001/tools/get_weather"
      Then 請求應成功
      And 回傳結果應包含:
        | field        | value              |
        | name         | get_weather        |
        | description  | 查詢指定城市天氣   |
        | input_schema | (完整 JSON Schema) |
      And 回傳應包含使用範例（如 MCP Server 有提供）

    Example: 失敗 - 工具不存在
      When 使用者發送 GET 請求至 "/api/mcp-servers/mcp-001/tools/non_existent"
      Then 請求應失敗，回傳狀態碼 404
      And 錯誤訊息應為 "Tool 'non_existent' not found in this MCP Server"
  # ============================================================
  # Rule: 工具搜尋
  # ============================================================

  Rule: 支援搜尋工具

    Example: 成功 - 依名稱搜尋
      When 使用者發送 GET 請求至 "/api/mcp-servers/mcp-001/tools":
        | search | weather |
      Then 回傳結果應只包含名稱或描述含有 "weather" 的工具:
        | name         |
        | get_weather  |
        | get_forecast |
  # ============================================================
  # Rule: 工具變更追蹤
  # ============================================================

  Rule: 系統追蹤 MCP Server 工具變更

    Example: 偵測工具新增
      Given MCP Server "mcp-001" 先前有 3 個工具
      And MCP Server 現在新增了工具 "get_humidity"
      When 系統重新查詢工具列表
      Then mcp_server_tools 表應新增 "get_humidity" 記錄
      And 應記錄變更事件:
        | event_type | tool_added   |
        | tool_name  | get_humidity |
        | mcp_id     | mcp-001      |

    Example: 偵測工具移除
      Given MCP Server "mcp-001" 先前有工具 "deprecated_tool"
      And MCP Server 現在已移除該工具
      When 系統重新查詢工具列表
      Then mcp_server_tools 表中 "deprecated_tool" 應標記為 removed
      And 應檢查是否有 Agent 正在使用該工具
  # ============================================================
  # Rule: 批次查詢
  # ============================================================

  Rule: 支援查詢多個 MCP Server 的工具

    Example: 成功 - 查詢所有可用 MCP Server 的工具
      When 使用者發送 GET 請求至 "/api/mcp-servers/tools/all"
      Then 請求應成功
      And 回傳結果應包含使用者有權限的所有 MCP Server 工具
      And 每個工具應標示來源 MCP Server:
        | tool_name    | mcp_server_id | mcp_server_name |
        | get_weather  | mcp-001       | Weather Service |
        | get_forecast | mcp-001       | Weather Service |
        | ...          | ...           | ...             |
