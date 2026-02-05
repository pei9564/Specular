Feature: Request 記錄與錯誤追蹤
  監控系統所有 API 請求，記錄詳細的上下文與錯誤資訊，支援分散式追蹤與效能分析

  Background:
    Given 系統已配置集中式日誌服務 (如 Elasticsearch 或 CloudWatch)
    And OpenTelemetry 追蹤已啟用
    And 系統目前時間為 "2024-02-05T12:00:00Z"
  # ============================================================
  # Rule: API 請求日誌
  # ============================================================

  Rule: 系統應記錄所有進入的 API 請求與回應摘要

    Example: 成功 - 記錄標準請求日誌
      When 用戶 "user-001" 發送 POST 請求至 "/api/agents"
      Then 請求處理完成，狀態碼為 201
      And request_logs 表應新增一筆記錄:
        | field      | value               |
        | trace_id   | (自動生成 trace_id) |
        | timestamp  | (當前時間)          |
        | method     | POST                |
        | path       | /api/agents         |
        | status     |                 201 |
        | latency_ms |                 150 |
        | client_ip  |       192.168.1.100 |
        | user_agent | Mozilla/5.0...      |
        | user_id    | user-001            |

    Example: 忽略 - 排除健康檢查日誌
      Given 系統配置 log_exclude_paths 為 ["/health", "/metrics"]
      Then 請求應成功
      But request_logs 表不應新增記錄（避免洗版）
  # ============================================================
  # Rule: 分散式追蹤 (Tracing)
  # ============================================================

  Rule: 每個請求應分配唯一的 Trace ID 以追蹤跨模組調用

    Example: 跨服務追蹤 ID 傳遞
      Given 前端發送請求帶有 header "x-request-id": "req-abc-123"
      When API Gateway 接收請求並轉發給 Agent Service
      Then Agent Service 的日誌中 trace_id 應為 "req-abc-123"
      And Agent Service 調用 LLM Service 時應傳遞該 trace_id
      And 整個調用鏈路應可透過該 trace_id 串聯

    Example: 自動生成 Trace ID
      Given 請求 header 未包含追蹤 ID
      When 請求進入系統邊界
      Then 系統應自動生成 UUIDv4 作為 trace_id
      And 在回應 headers 中回傳 "x-trace-id"
  # ============================================================
  # Rule: 錯誤捕捉與報告
  # ============================================================

  Rule: 系統應捕捉未處理的例外並記錄完整錯誤資訊

    Example: 捕捉 500 伺服器錯誤
      Given 資料庫連線中斷
      When 用戶嘗試讀取資料
      Then API 應回傳狀態碼 500
      And 回傳錯誤代碼 "INTERNAL_SERVER_ERROR"
      And error_logs 表應記錄 Critical 級別日誌:
        | field       | value                   |
        | error_type  | DatabaseConnectionError |
        | message     | Connection timed out    |
        | stack_trace | (包含完整堆疊路徑)      |
        | trace_id    | (對應的請求 Trace ID)   |
        | user_id     | (發起請求的用戶)        |

    Example: 捕捉 4xx 客戶端錯誤
      When 用戶傳送無效的 JSONPayload
      Then API 應回傳狀態碼 400
      And 應記錄 Warning 級別日誌:
        | message    | Invalid JSON format |
        | input_body | (截斷的原始輸入)    |
  # ============================================================
  # Rule: 效能監控
  # ============================================================

  Rule: 系統應記錄請求處理時間以進行效能分析

    Example: 記錄慢查詢 (Slow Query)
      Given 系統設定 slow_request_threshold 為 1000ms
      When 某個複雜搜尋請求耗時 2500ms
      Then 日誌應標記該請求為 "SLOW"
      And 應觸發效能警示通知
