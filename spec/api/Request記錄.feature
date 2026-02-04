Feature: 請求記錄與可追蹤性 (Request Logging & Traceability)
  # 本 Feature 定義系統如何記錄 API 請求、追蹤資訊與異常堆疊，以支援審計與除錯

  Rule: 記錄 API 請求上下文與異常堆疊
    # 確保每個請求都能被追蹤與審計，包含正常請求與異常情況

    Example: 記錄帶有追蹤資訊的正常請求
      # 測試目標：驗證系統能正確記錄正常請求的完整上下文
      Given 使用者資訊:
        | userId |
        | u_999  |
      And 請求 Header 包含:
        | headerName | headerValue  |
        | Trace-ID   | trace_abc123 |
        | User-Agent | Mozilla/5.0  |
      And 審計服務狀態為 AVAILABLE
      When 執行任意 API 請求, call:
        | endpoint    | method | responseTime |
        | /api/agents | GET    |        150ms |
      Then 資料庫 table "audit_logs" 應新增記錄:
        | traceId      | userId | endpoint    | method | statusCode | durationMs | createdAt           |
        | trace_abc123 | u_999  | /api/agents | GET    |        200 |        150 | 2026-02-04T00:00:00 |
      And 系統應發布事件 "RequestRecorded", with payload:
        | field      | value        |
        | traceId    | trace_abc123 |
        | userId     | u_999        |
        | statusCode |          200 |

    Example: 記錄包含請求與回應 Body 的完整審計日誌
      # 測試目標：驗證系統能記錄請求與回應的詳細內容
      Given 使用者資訊:
        | userId |
        | u_001  |
      And 請求 Header 包含:
        | headerName | headerValue  |
        | Trace-ID   | trace_xyz789 |
      When 執行 API 請求, call:
        | endpoint    | method | requestBody         | responseBody                      | statusCode |
        | /api/agents | POST   | { name: "TestBot" } | { id: "ag_001", name: "TestBot" } |        201 |
      Then 資料庫 table "audit_logs" 應新增記錄:
        | traceId      | userId | endpoint    | method | statusCode | requestBody         | responseBody                      |
        | trace_xyz789 | u_001  | /api/agents | POST   |        201 | { name: "TestBot" } | { id: "ag_001", name: "TestBot" } |

    Example: 捕獲並記錄處理過程中的異常
      # 測試目標：驗證系統能捕獲並記錄異常堆疊
      Given 使用者發送請求, with userId="u_002", traceId="trace_err001"
      And API 處理過程中拋出異常:
        | exceptionType | exceptionMessage            | stackTrace                |
        | ValueError    | Invalid agent configuration | at AgentService.create:45 |
      When 全域異常處理器捕獲該錯誤
      Then 資料庫 table "audit_logs" 應新增記錄:
        | traceId      | userId | statusCode | errorType  | errorMessage                | stackTrace                |
        | trace_err001 | u_002  |        400 | ValueError | Invalid agent configuration | at AgentService.create:45 |
      And 系統應發布事件 "ExceptionCaught", with payload:
        | field        | value                       |
        | traceId      | trace_err001                |
        | errorType    | ValueError                  |
        | errorMessage | Invalid agent configuration |

    Example: 記錄系統內部錯誤（500）
      # 測試目標：驗證系統能記錄未預期的內部錯誤
      Given 使用者發送請求, with userId="u_003", traceId="trace_500"
      And 系統內部發生未處理異常:
        | exceptionType        | exceptionMessage      | stackTrace                   |
        | NullPointerException | Unexpected null value | at DatabaseService.query:123 |
      When 全域異常處理器捕獲該錯誤
      Then 資料庫 table "audit_logs" 應新增記錄:
        | traceId   | userId | statusCode | errorType            | errorMessage          | stackTrace                   |
        | trace_500 | u_003  |        500 | NullPointerException | Unexpected null value | at DatabaseService.query:123 |
      And 系統應發布事件 "SystemErrorOccurred"
      And 錯誤應包含完整的 stack trace 用於除錯

  Rule: 追蹤資訊的傳遞與查詢
    # 支援跨服務的追蹤與審計日誌查詢

    Example: 根據 Trace ID 查詢請求記錄
      # 測試目標：驗證審計日誌的查詢功能
      Given 系統中存在審計記錄, in table "audit_logs":
        | traceId      | userId | endpoint    | method | statusCode | durationMs | createdAt           |
        | trace_search | u_004  | /api/topics | POST   |        201 |        250 | 2026-02-04T10:00:00 |
      And 查詢者為管理員, with userId="u_admin", role="ADMIN"
      When 執行 API "SearchAuditLogs", call:
        | endpoint        | method | queryParams                 |
        | /api/audit-logs | GET    | { traceId: "trace_search" } |
      Then 回應 HTTP 200, with data:
        | field      | value               | type   |
        | traceId    | trace_search        | string |
        | userId     | u_004               | string |
        | endpoint   | /api/topics         | string |
        | method     | POST                | string |
        | statusCode |                 201 | number |
        | durationMs |                 250 | number |
        | createdAt  | 2026-02-04T10:00:00 | string |

    Example: 查詢特定使用者的請求歷史
      # 測試目標：驗證按使用者過濾的審計日誌查詢
      Given 系統中存在審計記錄, in table "audit_logs":
        | id | traceId  | userId | endpoint    | statusCode | createdAt           |
        |  1 | trace_01 | u_005  | /api/agents |        200 | 2026-02-04T10:00:00 |
        |  2 | trace_02 | u_005  | /api/topics |        201 | 2026-02-04T11:00:00 |
        |  3 | trace_03 | u_006  | /api/llms   |        200 | 2026-02-04T12:00:00 |
      And 查詢者為管理員, with userId="u_admin", role="ADMIN"
      When 執行 API "SearchAuditLogs", call:
        | endpoint        | method | queryParams         |
        | /api/audit-logs | GET    | { userId: "u_005" } |
      Then 回應 HTTP 200, with table:
        | traceId  | userId | endpoint    | statusCode |
        | trace_01 | u_005  | /api/agents |        200 |
        | trace_02 | u_005  | /api/topics |        201 |
      And 回傳清單總數應為 2
      And 回傳結果不應包含 userId="u_006" 的記錄

  Rule: 審計日誌服務的韌性 (Resilience)
    # 確保日誌記錄失敗不影響業務邏輯

    Example: 日誌資料庫故障時不影響 API 回應
      # 測試目標：驗證日誌服務的容錯性
      Given 審計日誌資料庫狀態為 UNAVAILABLE
      When 執行 API 請求, call:
        | endpoint    | method | expectedBehavior |
        | /api/agents | GET    | 正常返回業務資料 |
      Then 回應 HTTP 200（業務邏輯正常）
      And 系統應發布內部警示 "AuditLogWriteFailed"
      And 原始 API 回應不應受日誌失敗影響
      And 使用者應能正常收到資料

    Example: 過濾健康檢查路徑避免日誌噪音
      # 測試目標：驗證系統對雜訊請求的過濾
      Given 請求路徑為 "/health"
      When 系統攔截到該請求
      Then 資料庫 table "audit_logs" 不應新增任何記錄
      And 系統應直接返回健康狀態，無需記錄
