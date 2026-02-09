Feature: 新增 MCP Server
  管理外部 MCP Server 連接

  Background:
    Given 系統支援以下 MCP 傳輸類型:
      | transport_type | description             |
      | sse            | Server-Sent Events      |
      | stdio          | Standard I/O (本地進程) |
      | websocket      | WebSocket 連接          |
    And 使用者 "user@example.com" 已登入

  Rule: 用戶可以新增 SSE 類型的 MCP Server

    Example: 成功 - 新增 SSE MCP Server
      When 使用者新增 SSE 類型的 MCP Server:
        | field      | value                               |
        | name       | Weather Service                     |
        | url        | https://weather-api.example.com/mcp |
        | visibility | private                             |
      Then MCP Server 應成功建立
      And mcp_servers 表應新增記錄:
        | field          | value   |
        | transport_type | sse     |
        | status         | pending |

    Example: 成功 - 新增並自動測試連線
      When 使用者新增 MCP Server 並要求測試連線
      Then 系統應先測試連線
      And 若連線成功，狀態應設為 "active"
      And 若連線失敗，狀態應設為 "error"

  Rule: 用戶可以新增本地 stdio 類型的 MCP Server

    Example: 成功 - 新增 stdio MCP Server
      When 使用者新增 stdio 類型的 MCP Server:
        | field       | value            |
        | command     | python           |
        | args        | file_server.py   |
        | working_dir | /app/mcp-servers |
      Then MCP Server 應成功建立
      And mcp_servers 表應記錄 command 與 args

    Example: 成功 - stdio 帶環境變數
      When 使用者新增 stdio MCP Server 並設定環境變數
      Then 環境變數應加密儲存於 mcp_servers 表

  Rule: 用戶可以新增 WebSocket 類型的 MCP Server

    Example: 成功 - 新增 WebSocket MCP Server
      When 使用者新增 WebSocket 類型的 MCP Server:
        | url | wss://analytics.example.com/mcp |
      Then mcp_servers 記錄的 transport_type 應為 "websocket"

  Rule: 可以為 MCP Server 配置預設參數

    Example: 成功 - 配置 preset_kwargs
      When 使用者新增 MCP Server 並設定 preset_kwargs:
        | channel  | #general |
        | username | bot      |
      Then mcp_servers 記錄應包含此預設參數
      And Agent 調用此 MCP 時應自動套用這些參數

    Example: 成功 - 配置敏感參數（加密儲存）
      When 使用者新增 MCP Server 並設定 secrets
      Then secrets 應加密儲存

  Rule: 可以為 MCP Server 配置認證方式

    Example: 成功 - 配置 Bearer Token 認證
      When 使用者新增 MCP Server 並設定 Auth Type 為 Bearer Token
      Then Token 應加密儲存

    Example: 成功 - 配置 API Key 認證
      When 使用者新增 MCP Server 並設定 API Key Header 與 Key
      Then 連線設定應包含此 Header

  Rule: 系統應驗證必要欄位

    Example: 失敗 - 缺少名稱
      When 新增 MCP Server 未提供名稱
      Then 新增應失敗

    Example: 失敗 - 缺少 transport_type
      When 新增 MCP Server 未提供傳輸類型
      Then 新增應失敗

    Example: 失敗 - SSE 類型缺少 URL
      When 新增 SSE 類型 MCP Server 未提供 URL
      Then 新增應失敗

    Example: 失敗 - stdio 類型缺少 command
      When 新增 stdio 類型 MCP Server 未提供 command
      Then 新增應失敗

    Example: 失敗 - 名稱重複
      Given 已存在名為 "Weather Service" 的 MCP Server
      When 嘗試新增同名 MCP Server
      Then 新增應失敗

  Rule: 用戶的 MCP Server 數量有限制

    Example: 失敗 - 超過數量上限
      Given 使用者已達到 MCP Server 數量上限
      When 嘗試新增更多 MCP Server
      Then 新增應失敗並提示配額已滿

  Rule: 新增操作應記錄審計日誌

    Example: 記錄新增操作
      When 使用者成功新增 MCP Server
      Then audit_logs 表應新增一筆記錄:
        | field       | value             |
        | action      | mcp_server.create |
        | target_type | mcp_server        |
