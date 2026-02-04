Feature: 工具庫存取 (Tool Registry Access)
  # 本 Feature 定義如何查詢工具模板與工具實例，為建立 Agent 和綁定工具提供基礎

  Rule: 查詢可用工具模板 (Templates)
    # 這是建立新 Tool Instance 時的前置查詢

    Example: 取得系統支援的工具模板清單
      # 測試目標：驗證系統能返回所有可用的工具模板
      Given 系統中存在以下工具模板, in table "tool_templates":
        | id      | name        | description  | schema                                             | createdAt           |
        | tmpl_01 | Web Scraper | 網頁爬蟲工具 | { targetUrl: { type: "string", required: true } }  | 2026-01-01T00:00:00 |
        | tmpl_02 | Calculator  | 計算器工具   | { expression: { type: "string", required: true } } | 2026-01-01T00:00:00 |
      When 執行 API "GetToolTemplates", call:
        | endpoint            | method |
        | /api/tool-templates | GET    |
      Then 回應 HTTP 200, with table:
        | id      | name        | description  | schema                                             |
        | tmpl_01 | Web Scraper | 網頁爬蟲工具 | { targetUrl: { type: "string", required: true } }  |
        | tmpl_02 | Calculator  | 計算器工具   | { expression: { type: "string", required: true } } |
      And 回傳清單總數應為 2

    Example: 查詢單一工具模板的詳細資訊
      # 測試目標：驗證系統能返回特定工具模板的完整資訊
      Given 系統中存在以下工具模板, in table "tool_templates":
        | id      | name        | description  | schema                                            | version |
        | tmpl_01 | Web Scraper | 網頁爬蟲工具 | { targetUrl: { type: "string", required: true } } |     1.0 |
      When 執行 API "GetToolTemplateDetails", call:
        | endpoint                 | method | pathParams        |
        | /api/tool-templates/{id} | GET    | { id: "tmpl_01" } |
      Then 回應 HTTP 200, with data:
        | field       | value                                             | type   |
        | id          | tmpl_01                                           | string |
        | name        | Web Scraper                                       | string |
        | description | 網頁爬蟲工具                                      | string |
        | schema      | { targetUrl: { type: "string", required: true } } | object |
        | version     |                                               1.0 | string |

  Rule: 查詢已建立的工具實例 (Instances)
    # 這是 Agent 綁定工具時的查詢

    Example: 取得使用者已建立的工具實例
      # 測試目標：驗證系統能返回使用者建立的所有工具實例
      Given 使用者 userId="u_001" 已建立以下工具實例, in table "tool_instances":
        | id      | name         | templateId | config                    | userId | status | createdAt           |
        | inst_01 | PTT Crawler  | tmpl_01    | { targetUrl: "ptt.cc" }   | u_001  | ACTIVE | 2026-01-15T00:00:00 |
        | inst_02 | News Crawler | tmpl_01    | { targetUrl: "news.com" } | u_001  | ACTIVE | 2026-01-16T00:00:00 |
      When 執行 API "GetToolInstances", call:
        | endpoint            | method | queryParams         |
        | /api/tool-instances | GET    | { userId: "u_001" } |
      Then 回應 HTTP 200, with table:
        | id      | name         | templateId | config                    | status |
        | inst_01 | PTT Crawler  | tmpl_01    | { targetUrl: "ptt.cc" }   | ACTIVE |
        | inst_02 | News Crawler | tmpl_01    | { targetUrl: "news.com" } | ACTIVE |
      And 回傳清單總數應為 2
      And 兩者皆源自同一個 Template "tmpl_01" 但具備不同 config

    Example: 查詢特定工具實例的詳細資訊
      # 測試目標：驗證系統能返回特定工具實例的完整配置
      Given 系統中存在以下工具實例, in table "tool_instances":
        | id      | name        | templateId | config                  | userId | status | createdAt           |
        | inst_03 | PTT Crawler | tmpl_01    | { targetUrl: "ptt.cc" } | u_001  | ACTIVE | 2026-01-15T00:00:00 |
      When 執行 API "GetToolInstanceDetails", call:
        | endpoint                 | method | pathParams        |
        | /api/tool-instances/{id} | GET    | { id: "inst_03" } |
      Then 回應 HTTP 200, with data:
        | field      | value                   | type   |
        | id         | inst_03                 | string |
        | name       | PTT Crawler             | string |
        | templateId | tmpl_01                 | string |
        | config     | { targetUrl: "ptt.cc" } | object |
        | userId     | u_001                   | string |
        | status     | ACTIVE                  | string |
        | createdAt  |     2026-01-15T00:00:00 | string |

    Example: 過濾查詢特定模板的所有實例
      # 測試目標：驗證系統支援按模板 ID 過濾工具實例
      Given 系統中存在以下工具實例, in table "tool_instances":
        | id      | name         | templateId | userId |
        | inst_01 | PTT Crawler  | tmpl_01    | u_001  |
        | inst_02 | News Crawler | tmpl_01    | u_001  |
        | inst_03 | My Calc      | tmpl_02    | u_001  |
      When 執行 API "GetToolInstances", call:
        | endpoint            | method | queryParams                                |
        | /api/tool-instances | GET    | { userId: "u_001", templateId: "tmpl_01" } |
      Then 回應 HTTP 200, with table:
        | id      | name         | templateId |
        | inst_01 | PTT Crawler  | tmpl_01    |
        | inst_02 | News Crawler | tmpl_01    |
      And 回傳清單總數應為 2
      And 回傳結果不應包含 templateId="tmpl_02" 的實例

  Rule: 查詢結果為空時的處理 (Empty State)
    # 當使用者尚未建立任何工具實例時，應回傳空清單而非錯誤

    Example: 新使用者查詢工具實例（無結果）
      # 測試目標：驗證空結果的正確處理
      Given 使用者 userId="u_new" 尚未建立任何工具實例
      When 執行 API "GetToolInstances", call:
        | endpoint            | method | queryParams         |
        | /api/tool-instances | GET    | { userId: "u_new" } |
      Then 回應 HTTP 200, with table:
        | (empty) |
      And 回傳清單應為空陣列 []
      And 回傳清單總數應為 0
