Feature: 系統維運與審計 (System Operations & Auditing)
  # 本 Feature 定義系統級別的維運功能，包含身份驗證、日誌管理、警示機制與資料保留政策

  Rule: 透過信任的 Header 識別使用者身份 (External Authentication)
    # 外部認證整合：信任上游 Gateway 傳遞的身份，無需本地登入

    Example: 接收標準身份 Header 建立 Context
      # 測試目標：驗證系統能正確解析外部身份資訊
      Given 上游 Gateway 傳入請求, with headers:
        | headerName  | headerValue |
        | X-User-ID   | u_ldap_101  |
        | X-User-Role | Admin       |
      When 系統 Middleware 處理請求
      Then 系統當前 User Context 應為:
        | field  | value      |
        | userId | u_ldap_101 |
        | role   | Admin      |
      And 後續的業務邏輯應使用該 Context 進行權限檢查

    Example: 缺少必要身份 Header (拒絕訪問)
      # 測試目標：驗證系統對缺少身份資訊的請求的處理
      Given 上游 Gateway 傳入請求, with headers:
        | headerName  | headerValue |
        | X-User-Role | User        |
      And 缺少必要的 "X-User-ID" header
      When 系統 Middleware 處理請求
      Then 回應 HTTP 401, with error:
        | field   | value                          | type   |
        | code    | UNAUTHORIZED                   | string |
        | message | 缺少必要的身份驗證資訊         | string |
        | details | { missingHeader: "X-User-ID" } | object |
      And 請求不應進入業務邏輯層

    Example: Header 值格式異常（驗證失敗）
      # 測試目標：驗證系統對異常 Header 值的處理
      Given 上游 Gateway 傳入請求, with headers:
        | headerName  | headerValue    |
        | X-User-ID   | (empty string) |
        | X-User-Role | Admin          |
      When 系統 Middleware 處理請求
      Then 回應 HTTP 401, with error:
        | field   | value              | type   |
        | code    | INVALID_USER_ID    | string |
        | message | 使用者 ID 格式異常 | string |

  Rule: 日誌韌性與過濾 (Logging Resilience)
    # 確保日誌行為不影響業務，並過濾雜訊

    Example: 忽略健康檢查路徑 (Noise Filtering)
      # 測試目標：驗證系統對健康檢查請求的過濾
      Given 請求資訊:
        | endpoint | method |
        | /health  | GET    |
      When 系統攔截到該請求
      Then 回應 HTTP 200, with data:
        | field  | value |
        | status | OK    |
      And 資料庫 table "audit_logs" 不應新增任何記錄
      And 系統應直接返回健康狀態，無需記錄

    Example: 過濾其他雜訊路徑
      # 測試目標：驗證系統對多種雜訊路徑的過濾
      Given 請求路徑為以下之一:
        | endpoint     |
        | /health      |
        | /metrics     |
        | /favicon.ico |
      When 系統攔截到這些請求
      Then 資料庫 table "audit_logs" 不應為這些請求新增記錄

    Example: 日誌資料庫故障時不影響 API 回應 (Fault Tolerance)
      # 測試目標：驗證日誌服務的容錯機制
      Given 審計日誌資料庫狀態為 UNAVAILABLE
      And 使用者發送正常業務請求, endpoint="/api/agents", method="GET"
      When 系統嘗試寫入日誌失敗
      Then 系統應發布內部警示 "AuditLogWriteFailed", with payload:
        | field    | value                |
        | severity | HIGH                 |
        | reason   | Database unavailable |
        | endpoint | /api/agents          |
      And 原始 API 回應應正常返回給使用者（HTTP 200）
      And 業務邏輯不應受日誌失敗影響

  Rule: 審計日誌檢視 (Audit Log Inspection)
    # 提供管理員查詢與追蹤紀錄的能力

    Example: 根據 Trace ID 追蹤特定請求
      # 測試目標：驗證審計日誌的追蹤查詢功能
      Given 系統中存在審計記錄, in table "audit_logs":
        | traceId   | userId | endpoint    | method | statusCode | requestBody         | responseBody     | createdAt           |
        | trace_123 | u_001  | /api/agents | POST   |        201 | { name: "TestBot" } | { id: "ag_001" } | 2026-02-04T10:00:00 |
      And 查詢者為管理員, with userId="u_admin", role="ADMIN"
      When 執行 API "SearchAuditLogs", call:
        | endpoint        | method | queryParams              |
        | /api/audit-logs | GET    | { traceId: "trace_123" } |
      Then 回應 HTTP 200, with data:
        | field        | value               | type   |
        | traceId      | trace_123           | string |
        | userId       | u_001               | string |
        | endpoint     | /api/agents         | string |
        | method       | POST                | string |
        | statusCode   |                 201 | number |
        | requestBody  | { name: "TestBot" } | object |
        | responseBody | { id: "ag_001" }    | object |
        | createdAt    | 2026-02-04T10:00:00 | string |
      And 應回傳該筆請求的完整詳情（包含 request 與 response body）

    Example: 非管理員嘗試查詢審計日誌（權限拒絕）
      # 測試目標：驗證審計日誌查詢的權限控制
      Given 查詢者為一般使用者, with userId="u_002", role="USER"
      When 執行 API "SearchAuditLogs", call:
        | endpoint        | method | queryParams              |
        | /api/audit-logs | GET    | { traceId: "trace_123" } |
      Then 回應 HTTP 403, with error:
        | field   | value                  | type   |
        | code    | PERMISSION_DENIED      | string |
        | message | 僅管理員可查詢審計日誌 | string |

  Rule: 系統警示觸發 (System Alerting)
    # 定義內部異常時的警示廣播機制

    Example: 處理關鍵服務連線失敗
      # 測試目標：驗證系統警示的觸發機制
      Given 系統偵測到異常狀態:
        | service     | status      | severity |
        | LLM Service | UNREACHABLE | HIGH     |
      When 執行 "TriggerSystemAlert"
      Then 系統應發布事件 "AlertBroadcasted", with payload:
        | field     | value                |
        | severity  | HIGH                 |
        | service   | LLM Service          |
        | status    | UNREACHABLE          |
        | message   | LLM Service 無法連線 |
        | timestamp |  2026-02-04T00:00:00 |
      And 維運團隊應收到通知

    Example: 處理資料庫連線池耗盡
      # 測試目標：驗證資源耗盡的警示
      Given 系統偵測到異常狀態:
        | resource      | status    | severity |
        | Database Pool | EXHAUSTED | CRITICAL |
      When 執行 "TriggerSystemAlert"
      Then 系統應發布事件 "AlertBroadcasted", with payload:
        | field    | value              |
        | severity | CRITICAL           |
        | resource | Database Pool      |
        | message  | 資料庫連線池已耗盡 |

  Rule: 系統資料保留政策 (Data Retention Policy)
    # 針對日誌與訊息定義自動清理機制

    Example: Audit Log 滾動保留 90 天
      # 測試目標：驗證審計日誌的自動清理機制
      Given 系統中存在審計記錄, in table "audit_logs":
        | id | traceId   | userId | createdAt           | age   |
        |  1 | trace_old | u_001  | 2025-10-01T00:00:00 | 126天 |
        |  2 | trace_new | u_002  | 2026-01-01T00:00:00 |  34天 |
      And 系統保留政策為 90 天
      When 執行自動清理排程 "CleanupAuditLogs"
      Then 資料庫 table "audit_logs" 應刪除記錄:
        | id | traceId   | reason     |
        |  1 | trace_old | 超過 90 天 |
      And 資料庫 table "audit_logs" 應保留記錄:
        | id | traceId   |
        |  2 | trace_new |
      And 系統應保留最近 90 天內的完整日誌紀錄

    Example: 對話訊息 (ChatMessage) 永久保留
      # 測試目標：驗證對話訊息不會被自動清理
      Given 系統中存在對話訊息, in table "chat_messages":
        | id   | threadId | content | createdAt           | age   |
        | m_01 | th_001   | Hello   | 2025-01-01T00:00:00 | 399天 |
        | m_02 | th_002   | World   | 2026-02-01T00:00:00 |   3天 |
      When 執行自動清理排程 "CleanupOldData"
      Then 資料庫 table "chat_messages" 不應刪除任何記錄
      And 所有對話訊息應永久保留，無論建立時間
      And 確保使用者的歷史對話始終可被查詢

    Example: 已刪除 Agent 的資料保留
      # 測試目標：驗證軟刪除資源的保留政策
      Given 系統中存在已刪除的 Agent, in table "agents":
        | id     | name   | status  | deletedAt           | daysSinceDeleted |
        | ag_old | OldBot | DELETED | 2025-01-01T00:00:00 |            400天 |
      And 系統保留政策為已刪除資源保留 365 天
      When 執行自動清理排程 "CleanupDeletedResources"
      Then 資料庫 table "agents" 應物理刪除記錄:
        | id     | reason            |
        | ag_old | 已刪除超過 365 天 |
      And 相關的 Topics 與 ChatMessages 應根據各自的保留政策處理
