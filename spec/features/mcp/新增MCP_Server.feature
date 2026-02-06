Feature: 新增 MCP Server
  管理外部 MCP Server 連接

  Background:
    Given 系統支援以下 MCP 傳輸類型:
      | transport_type | description             |
      | sse            | Server-Sent Events      |
      | stdio          | Standard I/O (本地進程) |
      | websocket      | WebSocket 連接          |
    And 系統中存在以下用戶:
      | id        | email             | role  |
      | user-001  | user@example.com  | user  |
      | admin-001 | admin@example.com | admin |
    And 使用者 "user@example.com" 已登入
  # ============================================================
  # Rule: 新增 SSE 類型 MCP Server
  # ============================================================

  Rule: 用戶可以新增 SSE 類型的 MCP Server

    Example: 成功 - 新增 SSE MCP Server
      When 使用者發送 POST 請求至 "/api/mcp-servers":
        | field          | value                               |
        | name           | Weather Service                     |
        | description    | 天氣查詢服務                        |
        | transport_type | sse                                 |
        | url            | https://weather-api.example.com/mcp |
        | visibility     | private                             |
      Then 請求應成功，回傳狀態碼 201
      And mcp_servers 表應新增一筆記錄:
        | field          | value                               |
        | id             | (自動生成 UUID)                     |
        | name           | Weather Service                     |
        | description    | 天氣查詢服務                        |
        | transport_type | sse                                 |
        | url            | https://weather-api.example.com/mcp |
        | owner_id       | user-001                            |
        | visibility     | private                             |
        | status         | pending                             |
        | created_at     | (當前時間)                          |
      And 回傳結果應包含新建的 MCP Server 資訊

    Example: 成功 - 新增並自動測試連線
      When 使用者發送 POST 請求至 "/api/mcp-servers":
        | name            | Weather Service                     |
        | transport_type  | sse                                 |
        | url             | https://weather-api.example.com/mcp |
        | test_connection | true                                |
      Then 系統應先測試 MCP Server 連線
      And 若連線成功，status 應設為 "active"
      And 若連線失敗，status 應設為 "error"
      And 回傳應包含連線測試結果
  # ============================================================
  # Rule: 新增 stdio 類型 MCP Server
  # ============================================================

  Rule: 用戶可以新增本地 stdio 類型的 MCP Server

    Example: 成功 - 新增 stdio MCP Server
      When 使用者發送 POST 請求至 "/api/mcp-servers":
        | field          | value                     |
        | name           | Local File Manager        |
        | transport_type | stdio                     |
        | command        | python                    |
        | args           | ["-m", "file_mcp_server"] |
        | working_dir    | /app/mcp-servers          |
      Then 請求應成功
      And mcp_servers 表應新增一筆記錄:
        | field          | value                     |
        | transport_type | stdio                     |
        | command        | python                    |
        | args           | ["-m", "file_mcp_server"] |
        | working_dir    | /app/mcp-servers          |

    Example: 成功 - stdio 帶環境變數
      When 使用者發送 POST 請求至 "/api/mcp-servers":
        | name           | Database Tool                               |
        | transport_type | stdio                                       |
        | command        | node                                        |
        | args           | ["db-mcp-server.js"]                        |
        | env            | {"DB_HOST": "localhost", "DB_PORT": "5432"} |
      Then 請求應成功
      And mcp_servers 記錄的 env 應儲存（敏感值加密）
  # ============================================================
  # Rule: 新增 WebSocket 類型 MCP Server
  # ============================================================

  Rule: 用戶可以新增 WebSocket 類型的 MCP Server

    Example: 成功 - 新增 WebSocket MCP Server
      When 使用者發送 POST 請求至 "/api/mcp-servers":
        | name           | Real-time Analytics             |
        | transport_type | websocket                       |
        | url            | wss://analytics.example.com/mcp |
      Then 請求應成功
      And mcp_servers 記錄的 transport_type 應為 "websocket"
  # ============================================================
  # Rule: 配置預設參數
  # ============================================================

  Rule: 可以為 MCP Server 配置預設參數

    Example: 成功 - 配置 preset_kwargs
      When 使用者發送 POST 請求至 "/api/mcp-servers":
        | name           | Slack Integration                          |
        | transport_type | sse                                        |
        | url            | https://slack-mcp.example.com              |
        | preset_kwargs  | {"channel": "#general", "username": "bot"} |
      Then 請求應成功
      And mcp_servers 記錄的 preset_kwargs 應儲存:
        | channel  | #general |
        | username | bot      |
      And 當 Agent 調用此 MCP 時，preset_kwargs 應自動合併到調用參數

    Example: 成功 - 配置敏感參數（加密儲存）
      When 使用者發送 POST 請求至 "/api/mcp-servers":
        | name           | GitHub Integration             |
        | transport_type | sse                            |
        | url            | https://github-mcp.example.com |
        | secrets        | {"api_token": "ghp_xxxx"}      |
      Then 請求應成功
      And mcp_servers 記錄的 secrets 應加密儲存
      And 回傳結果不應包含 secrets 明文
  # ============================================================
  # Rule: 認證配置
  # ============================================================

  Rule: 可以為 MCP Server 配置認證方式

    Example: 成功 - 配置 Bearer Token 認證
      When 使用者發送 POST 請求至 "/api/mcp-servers":
        | name           | Secure API                     |
        | transport_type | sse                            |
        | url            | https://secure-mcp.example.com |
        | auth_type      | bearer                         |
        | auth_token     | my-secret-token                |
      Then 請求應成功
      And mcp_servers 記錄應包含:
        | auth_type            | bearer         |
        | auth_token_encrypted | (加密的 token) |

    Example: 成功 - 配置 API Key 認證
      When 使用者發送 POST 請求至 "/api/mcp-servers":
        | name           | API Service                 |
        | transport_type | sse                         |
        | url            | https://api-mcp.example.com |
        | auth_type      | api_key                     |
        | auth_header    | X-API-Key                   |
        | auth_token     | my-api-key                  |
      Then 請求應成功
      And MCP 連線時應在 header 加入 "X-API-Key: my-api-key"
  # ============================================================
  # Rule: 欄位驗證
  # ============================================================

  Rule: 系統應驗證必要欄位

    Example: 失敗 - 缺少 name
      When 使用者發送 POST 請求至 "/api/mcp-servers":
        | transport_type | sse                     |
        | url            | https://example.com/mcp |
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "name is required"

    Example: 失敗 - 缺少 transport_type
      When 使用者發送 POST 請求至 "/api/mcp-servers":
        | name | Test Server             |
        | url  | https://example.com/mcp |
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "transport_type is required"

    Example: 失敗 - 無效的 transport_type
      When 使用者發送 POST 請求至 "/api/mcp-servers":
        | name           | Test Server |
        | transport_type | invalid     |
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "Invalid transport_type. Allowed: sse, stdio, websocket"

    Example: 失敗 - SSE 類型缺少 url
      When 使用者發送 POST 請求至 "/api/mcp-servers":
        | name           | Test Server |
        | transport_type | sse         |
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "url is required for SSE transport"

    Example: 失敗 - stdio 類型缺少 command
      When 使用者發送 POST 請求至 "/api/mcp-servers":
        | name           | Test Server |
        | transport_type | stdio       |
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "command is required for stdio transport"

    Example: 失敗 - 名稱已存在
      Given mcp_servers 表已存在 name 為 "Weather Service" 且 owner_id 為 "user-001" 的記錄
      When 使用者發送 POST 請求至 "/api/mcp-servers":
        | name           | Weather Service     |
        | transport_type | sse                 |
        | url            | https://new-url.com |
      Then 請求應失敗，回傳狀態碼 409
      And 錯誤訊息應為 "An MCP Server named 'Weather Service' already exists"
  # ============================================================
  # Rule: 數量限制
  # ============================================================

  Rule: 用戶的 MCP Server 數量有限制

    Example: 失敗 - 超過 MCP Server 數量上限
      Given 使用者 "user-001" 已建立 10 個 MCP Server（達到上限）
      When 使用者發送 POST 請求新增 MCP Server
      Then 請求應失敗，回傳狀態碼 429
      And 錯誤訊息應為 "MCP Server quota exceeded. Maximum: 10 per user."
  # ============================================================
  # Rule: 審計日誌
  # ============================================================

  Rule: 新增操作應記錄審計日誌

    Example: 記錄新增操作
      When 使用者新增 MCP Server
      Then audit_logs 表應新增一筆記錄:
        | field       | value                                                |
        | action      | mcp_server.create                                    |
        | actor_id    | user-001                                             |
        | target_type | mcp_server                                           |
        | target_id   | (新 MCP Server ID)                                   |
        | details     | {"name": "Weather Service", "transport_type": "sse"} |
        | created_at  | (當前時間)                                           |
