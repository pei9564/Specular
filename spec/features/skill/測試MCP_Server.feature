Feature: 測試 MCP Server
  驗證 MCP Server 連接有效性

  Background:
    Given 系統中存在以下 MCP Servers:
      | id      | name            | owner_id | status | transport_type | url                         | command |
      | mcp-001 | Weather Service | user-001 | active | sse            | https://weather.example.com | null    |
      | mcp-002 | File Manager    | user-001 | active | stdio          | null                        | python  |
      | mcp-003 | WS Service      | user-001 | active | websocket      | wss://ws.example.com/mcp    | null    |
      | mcp-004 | Broken Service  | user-001 | error  | sse            | https://broken.example.com  | null    |
      | mcp-005 | Private MCP     | user-002 | active | sse            | https://private.example.com | null    |
    And 使用者 "user-001" 已登入
  # ============================================================
  # Rule: SSE 連線測試
  # ============================================================

  Rule: 測試 SSE 類型 MCP Server 連線

    Example: 成功 - SSE 連線測試通過
      When 使用者發送 POST 請求至 "/api/mcp-servers/mcp-001/test"
      Then 系統應嘗試連接 MCP Server:
        | step | action                                      |
        |    1 | 建立 SSE 連線到 https://weather.example.com |
        |    2 | 發送 initialize 請求                        |
        |    3 | 等待 initialized 回應                       |
        |    4 | 發送 tools/list 請求驗證                    |
      And 若所有步驟成功，請求應成功，回傳狀態碼 200
      And 回傳結果應包含:
        | field       | value                 |
        | status      | success               |
        | message     | Connection successful |
        | latency_ms  | (連線延遲毫秒)        |
        | tools_count | (工具數量)            |
        | server_info | (MCP Server 資訊)     |
      And mcp_servers 表中 mcp-001 應更新:
        | field            | value      |
        | status           | active     |
        | last_tested_at   | (當前時間) |
        | last_test_status | success    |
        | last_error       | null       |

    Example: 失敗 - SSE 連線逾時
      Given MCP Server "mcp-001" 在 30 秒內無回應
      When 使用者發送 POST 請求至 "/api/mcp-servers/mcp-001/test"
      Then 請求應成功（測試本身執行完成），回傳狀態碼 200
      And 回傳結果應包含:
        | field         | value                          |
        | status        | failed                         |
        | error_code    | CONNECTION_TIMEOUT             |
        | error_message | Connection timed out after 30s |
      And mcp_servers 表中 mcp-001 應更新:
        | field            | value                |
        | status           | error                |
        | last_test_status | failed               |
        | last_error       | Connection timed out |

    Example: 失敗 - SSE 連線被拒絕
      Given MCP Server URL 無法連接
      When 使用者發送 POST 請求至 "/api/mcp-servers/mcp-001/test"
      Then 回傳結果應包含:
        | field         | value                       |
        | status        | failed                      |
        | error_code    | CONNECTION_REFUSED          |
        | error_message | Unable to connect to server |

    Example: 失敗 - 認證失敗
      Given MCP Server 需要認證但提供的 token 無效
      When 使用者發送 POST 請求至 "/api/mcp-servers/mcp-001/test"
      Then 回傳結果應包含:
        | field         | value                              |
        | status        | failed                             |
        | error_code    | AUTHENTICATION_FAILED              |
        | error_message | Invalid authentication credentials |
  # ============================================================
  # Rule: stdio 連線測試
  # ============================================================

  Rule: 測試 stdio 類型 MCP Server 連線

    Example: 成功 - stdio 連線測試通過
      Given MCP Server "mcp-002" 的配置:
        | command     | python                    |
        | args        | ["-m", "file_mcp_server"] |
        | working_dir | /app/mcp-servers          |
      When 使用者發送 POST 請求至 "/api/mcp-servers/mcp-002/test"
      Then 系統應嘗試啟動進程:
        | step | action                             |
        |    1 | 在 working_dir 執行 command + args |
        |    2 | 通過 stdin/stdout 發送 initialize  |
        |    3 | 等待 initialized 回應              |
        |    4 | 發送 tools/list 驗證               |
        |    5 | 終止測試進程                       |
      And 若成功，回傳 status: "success"

    Example: 失敗 - 進程啟動失敗
      Given MCP Server "mcp-002" 的 command 不存在
      When 使用者發送 POST 請求至 "/api/mcp-servers/mcp-002/test"
      Then 回傳結果應包含:
        | field         | value                                      |
        | status        | failed                                     |
        | error_code    | PROCESS_START_FAILED                       |
        | error_message | Failed to start process: command not found |

    Example: 失敗 - 進程異常退出
      Given MCP Server 進程啟動後立即退出（exit code 1）
      When 使用者發送 POST 請求至 "/api/mcp-servers/mcp-002/test"
      Then 回傳結果應包含:
        | field         | value                      |
        | status        | failed                     |
        | error_code    | PROCESS_EXITED             |
        | error_message | Process exited with code 1 |
        | stderr        | (錯誤輸出)                 |
  # ============================================================
  # Rule: WebSocket 連線測試
  # ============================================================

  Rule: 測試 WebSocket 類型 MCP Server 連線

    Example: 成功 - WebSocket 連線測試通過
      When 使用者發送 POST 請求至 "/api/mcp-servers/mcp-003/test"
      Then 系統應嘗試 WebSocket 連接:
        | step | action                        |
        |    1 | 建立 WebSocket 連線           |
        |    2 | 發送 initialize JSON-RPC 訊息 |
        |    3 | 等待 initialized 回應         |
        |    4 | 關閉連線                      |
      And 若成功，回傳 status: "success"

    Example: 失敗 - WebSocket 握手失敗
      Given WebSocket URL 回傳 403
      When 使用者發送 POST 請求至 "/api/mcp-servers/mcp-003/test"
      Then 回傳結果應包含:
        | field         | value                           |
        | status        | failed                          |
        | error_code    | WEBSOCKET_HANDSHAKE_FAILED      |
        | error_message | WebSocket handshake failed: 403 |
  # ============================================================
  # Rule: 測試特定工具
  # ============================================================

  Rule: 可以測試特定工具的執行

    Example: 成功 - 測試工具呼叫
      When 使用者發送 POST 請求至 "/api/mcp-servers/mcp-001/test-tool":
        | tool_name | get_weather        |
        | input     | {"city": "Taipei"} |
      Then 系統應調用 MCP Server 的 get_weather 工具
      And 回傳結果應包含:
        | field       | value              |
        | status      | success            |
        | tool_name   | get_weather        |
        | input       | {"city": "Taipei"} |
        | output      | (工具回傳結果)     |
        | duration_ms | (執行時間)         |

    Example: 失敗 - 工具不存在
      When 使用者發送 POST 請求至 "/api/mcp-servers/mcp-001/test-tool":
        | tool_name | non_existent_tool |
      Then 請求應失敗，回傳狀態碼 404
      And 錯誤訊息應為 "Tool 'non_existent_tool' not found"

    Example: 失敗 - 工具執行錯誤
      When 使用者發送 POST 請求至 "/api/mcp-servers/mcp-001/test-tool":
        | tool_name | get_weather  |
        | input     | {"city": ""} |
      Then 回傳結果應包含:
        | field         | value                |
        | status        | failed               |
        | error_code    | TOOL_EXECUTION_ERROR |
        | error_message | (工具錯誤訊息)       |
  # ============================================================
  # Rule: 批次測試
  # ============================================================

  Rule: 支援批次測試多個 MCP Server

    Example: 成功 - 批次測試所有 MCP Server
      When 使用者發送 POST 請求至 "/api/mcp-servers/test-all"
      Then 系統應依序測試所有使用者擁有的 MCP Server
      And 回傳結果應包含每個 MCP Server 的測試結果:
        | mcp_id  | name            | status  |
        | mcp-001 | Weather Service | success |
        | mcp-002 | File Manager    | success |
        | mcp-003 | WS Service      | success |
        | mcp-004 | Broken Service  | failed  |
      And 回傳應包含摘要:
        | total   | 4 |
        | success | 3 |
        | failed  | 1 |

    Example: 批次測試特定 MCP Servers
      When 使用者發送 POST 請求至 "/api/mcp-servers/test-batch":
        | mcp_ids | ["mcp-001", "mcp-002"] |
      Then 系統應只測試指定的 MCP Server
  # ============================================================
  # Rule: 權限控制
  # ============================================================

  Rule: 只能測試自己有權限的 MCP Server

    Example: 失敗 - 測試他人的 MCP Server
      When 使用者 "user-001" 發送 POST 請求至 "/api/mcp-servers/mcp-005/test"
      Then 請求應失敗，回傳狀態碼 403
      And 錯誤訊息應為 "You do not have permission to test this MCP Server"

    Example: 失敗 - MCP Server 不存在
      When 使用者發送 POST 請求至 "/api/mcp-servers/non-existent/test"
      Then 請求應失敗，回傳狀態碼 404
  # ============================================================
  # Rule: 測試歷史記錄
  # ============================================================

  Rule: 測試結果應記錄歷史

    Example: 記錄測試歷史
      When 使用者測試 MCP Server
      Then mcp_connection_tests 表應新增一筆記錄:
        | field         | value      |
        | mcp_server_id | mcp-001    |
        | status        | success    |
        | latency_ms    | (延遲毫秒) |
        | tools_count   | (工具數量) |
        | error_code    | null       |
        | error_message | null       |
        | tested_by     | user-001   |
        | tested_at     | (當前時間) |

    Example: 查詢測試歷史
      When 使用者發送 GET 請求至 "/api/mcp-servers/mcp-001/test-history":
        | limit | 10 |
      Then 回傳結果應包含最近 10 筆測試記錄
  # ============================================================
  # Rule: 自動健康檢查
  # ============================================================

  Rule: 系統可配置定期自動測試

    Example: 配置自動測試
      When 使用者發送 PATCH 請求至 "/api/mcp-servers/mcp-001":
        | auto_test_enabled  | true |
        | auto_test_interval |  300 |
      Then mcp_servers 表應更新:
        | field              | value |
        | auto_test_enabled  | true  |
        | auto_test_interval |   300 |
      And 系統應每 5 分鐘自動測試該 MCP Server

    Example: 自動測試失敗告警
      Given MCP Server "mcp-001" 配置自動測試
      And 連續 3 次自動測試失敗
      Then 系統應發送告警通知給擁有者
      And mcp_servers 的 status 應更新為 "error"
