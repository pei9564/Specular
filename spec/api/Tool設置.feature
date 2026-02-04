Feature: 工具實例管理 (Tool Instance Management)
  # 本 Feature 定義工具實例的完整生命週期管理，包含建立、更新、刪除與層聯影響

  Rule: 基於模板建立新的工具實例 (Instantiation)
    # 這是使用者將通用工具 (Template) 具象化為專用工具 (Instance) 的過程

    Example: 成功建立 PTT 爬蟲實例
      # 測試目標：驗證系統能基於模板成功建立工具實例
      Given 系統中存在以下工具模板, in table "tool_templates":
        | id      | name        | schema                                            |
        | tmpl_01 | Web Scraper | { targetUrl: { type: "string", required: true } } |
      And 使用者資訊:
        | userId |
        | u_001  |
      When 執行 API "CreateToolInstance", call:
        | endpoint            | method | bodyParams                                                                      |
        | /api/tool-instances | POST   | { name: "PTT Scraper", templateId: "tmpl_01", config: { targetUrl: "ptt.cc" } } |
      Then 回應 HTTP 201, with data:
        | field      | value                   | type   |
        | id         | inst_001                | string |
        | name       | PTT Scraper             | string |
        | templateId | tmpl_01                 | string |
        | config     | { targetUrl: "ptt.cc" } | object |
        | userId     | u_001                   | string |
        | status     | ACTIVE                  | string |
        | createdAt  |     2026-02-04T00:00:00 | string |
      And 資料庫 table "tool_instances" 應新增記錄:
        | id       | name        | templateId | config                  | userId | status |
        | inst_001 | PTT Scraper | tmpl_01    | { targetUrl: "ptt.cc" } | u_001  | ACTIVE |
      And 系統應發布事件 "ToolInstanceCreated", with payload:
        | field      | value    |
        | instanceId | inst_001 |
        | templateId | tmpl_01  |
        | userId     | u_001    |

    Example: 參數驗證失敗 (Schema Validation Violation)
      # 測試目標：驗證系統的 schema 驗證機制
      Given 系統中存在以下工具模板, in table "tool_templates":
        | id      | name        | schema                                            |
        | tmpl_01 | Web Scraper | { targetUrl: { type: "string", required: true } } |
      When 執行 API "CreateToolInstance", call:
        | endpoint            | method | bodyParams                                                                  |
        | /api/tool-instances | POST   | { name: "Broken Scraper", templateId: "tmpl_01", config: { timeout: 500 } } |
      Then 回應 HTTP 400, with error:
        | field   | value                                                         | type   |
        | code    | INVALID_CONFIGURATION                                         | string |
        | message | 配置參數不符合模板 schema                                     | string |
        | details | { missingFields: ["targetUrl"], providedFields: ["timeout"] } | object |
      And 資料庫 table "tool_instances" 不應新增任何記錄

    Example: 嘗試基於不存在的模板建立實例
      # 測試目標：驗證系統對模板存在性的檢查
      Given 系統中不存在模板 id="tmpl_999"
      When 執行 API "CreateToolInstance", call:
        | endpoint            | method | bodyParams                                                 |
        | /api/tool-instances | POST   | { name: "Ghost Tool", templateId: "tmpl_999", config: {} } |
      Then 回應 HTTP 404, with error:
        | field   | value                      | type   |
        | code    | TEMPLATE_NOT_FOUND         | string |
        | message | 工具模板不存在             | string |
        | details | { templateId: "tmpl_999" } | object |

  Rule: 更新與刪除工具實例 (傳導至綁定 Agent)
    # 工具實例的更動應自動反映在引用它的 Agent 上

    Example: 更新工具實例會立即影響引用它的 Agent
      # 測試目標：驗證工具實例更新的自動傳導機制
      Given 系統中存在以下工具實例, in table "tool_instances":
        | id       | name         | templateId | config                   | status |
        | inst_002 | News Crawler | tmpl_01    | { targetUrl: "cnn.com" } | ACTIVE |
      And 存在以下 Agent, in table "agents":
        | id     | name       | status |
        | ag_001 | Researcher | ACTIVE |
      And Agent 綁定工具, in table "agent_tools":
        | agentId | toolInstanceId | enabled |
        | ag_001  | inst_002       | true    |
      When 執行 API "UpdateToolInstance", call:
        | endpoint                 | method | pathParams         | bodyParams                           |
        | /api/tool-instances/{id} | PATCH  | { id: "inst_002" } | { config: { targetUrl: "bbc.com" } } |
      Then 回應 HTTP 200, with data:
        | field  | value                    | type   |
        | id     | inst_002                 | string |
        | name   | News Crawler             | string |
        | config | { targetUrl: "bbc.com" } | object |
      And 資料庫 table "tool_instances" 應更新記錄:
        | id       | config                   | updatedAt           |
        | inst_002 | { targetUrl: "bbc.com" } | 2026-02-04T00:00:00 |
      And 資料庫 table "agent_tools" 應無需任何更動（引用關係不變）
      And Agent "ag_001" 在使用該工具時將自動套用新配置 (bbc.com)
      And 系統應發布事件 "ToolInstanceUpdated", with payload:
        | field      | value    |
        | instanceId | inst_002 |

    Example: 刪除工具實例後，引用該工具的 Agent 應自動移除綁定
      # 測試目標：驗證工具實例刪除的層聯影響
      Given 系統中存在以下工具實例, in table "tool_instances":
        | id       | name      | status |
        | inst_003 | Math Tool | ACTIVE |
      And 存在以下 Agent, in table "agents":
        | id     | name     | status |
        | ag_002 | MathGuru | ACTIVE |
      And Agent 綁定工具, in table "agent_tools":
        | agentId | toolInstanceId | enabled |
        | ag_002  | inst_003       | true    |
      When 執行 API "DeleteToolInstance", call:
        | endpoint                 | method | pathParams         |
        | /api/tool-instances/{id} | DELETE | { id: "inst_003" } |
      Then 回應 HTTP 200, with data:
        | field   | value          |
        | message | 工具實例已刪除 |
        | id      | inst_003       |
      And 資料庫 table "tool_instances" 應更新記錄:
        | id       | status  | deletedAt           |
        | inst_003 | DELETED | 2026-02-04T00:00:00 |
      And 資料庫 table "agent_tools" 應刪除記錄:
        | agentId | toolInstanceId |
        | ag_002  | inst_003       |
      And Agent "ag_002" 的工具清單中應不再包含 "Math Tool"
      And 系統應發布事件 "ToolInstanceDeleted", with payload:
        | field          | value      |
        | instanceId     | inst_003   |
        | affectedAgents | ["ag_002"] |

  Rule: 工具模板 (ToolTemplate) 的生命週期管理
    # 工具模板是系統底層定義，刪除模板將產生層聯影響

    Example: 刪除模板時層聯刪除所有實例
      # 測試目標：驗證模板刪除的層聯影響範圍
      Given 系統中存在以下工具模板, in table "tool_templates":
        | id      | name        | status |
        | tmpl_02 | Web Scraper | ACTIVE |
      And 系統中存在以下工具實例, in table "tool_instances":
        | id       | name        | templateId | status |
        | inst_004 | PTT Scraper | tmpl_02    | ACTIVE |
      And 存在以下 Agent, in table "agents":
        | id     | name       | status |
        | ag_003 | Researcher | ACTIVE |
      And Agent 綁定工具, in table "agent_tools":
        | agentId | toolInstanceId | enabled |
        | ag_003  | inst_004       | true    |
      And 請求者為管理員, with userId="u_admin", role="ADMIN"
      When 執行 API "DeleteToolTemplate", call:
        | endpoint                 | method | pathParams        |
        | /api/tool-templates/{id} | DELETE | { id: "tmpl_02" } |
      Then 回應 HTTP 200, with data:
        | field             | value          |
        | message           | 工具模板已刪除 |
        | templateId        | tmpl_02        |
        | affectedInstances | ["inst_004"]   |
        | affectedAgents    | ["ag_003"]     |
      And 資料庫 table "tool_templates" 應更新記錄:
        | id      | status  | deletedAt           |
        | tmpl_02 | DELETED | 2026-02-04T00:00:00 |
      And 資料庫 table "tool_instances" 應更新記錄（層聯刪除）:
        | id       | status  | deletedAt           |
        | inst_004 | DELETED | 2026-02-04T00:00:00 |
      And 資料庫 table "agent_tools" 應刪除記錄（層聯清除）:
        | agentId | toolInstanceId |
        | ag_003  | inst_004       |
      And Agent "ag_003" 的工具清單中應不再包含 "PTT Scraper"
      And 系統應發布事件 "ToolTemplateDeleted", with payload:
        | field            | value        |
        | templateId       | tmpl_02      |
        | cascadeInstances | ["inst_004"] |
        | cascadeAgents    | ["ag_003"]   |

    Example: 非管理員嘗試刪除工具模板（權限拒絕）
      # 測試目標：驗證模板刪除的權限控制
      Given 請求者為一般使用者, with userId="u_001", role="USER"
      And 系統中存在工具模板 id="tmpl_03"
      When 執行 API "DeleteToolTemplate", call:
        | endpoint                 | method | pathParams        |
        | /api/tool-templates/{id} | DELETE | { id: "tmpl_03" } |
      Then 回應 HTTP 403, with error:
        | field   | value                  | type   |
        | code    | PERMISSION_DENIED      | string |
        | message | 僅管理員可刪除工具模板 | string |
