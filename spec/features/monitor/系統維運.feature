Feature: 系統維運
  系統健康監控、連線狀態檢查與日誌清理機制

  Background:
    Given 系統關鍵組件配置如下:
      | component   | type     | connection_string |
      | db_primary  | postgres | (hidden)          |
      | redis_cache | redis    | (hidden)          |
      | vector_db   | qdrant   | (hidden)          |
  # ============================================================
  # Rule: 系統健康檢查 (Health Check)
  # ============================================================

  Rule: 提供標準 Health Check 端點供負載平衡器與監控系統使用

    Example: 綜合健康狀態檢查
      When 請求 "GET /health"
      Then 若所有組件連線正常，回傳 200 OK
      And 回傳詳細狀態:
        | status     | healthy                            |
        | timestamp  | (ISO時間)                          |
        | components | {db: up, redis: up, vector_db: up} |

    Example: 單一組件故障
      Given Redis 服務斷線
      When 請求 "GET /health"
      Then 回傳 503 Service Unavailable
      And 回傳詳細狀態:
        | status     | unhealthy                            |
        | components | {db: up, redis: down, vector_db: up} |

    Example: Liveness Probe (存活探針)
      When 請求 "GET /health/liveness"
      Then 僅回傳 200 OK (不檢查相依服務，僅確認 API Server 活著)
  # ============================================================
  # Rule: 系統指標 (Metrics)
  # ============================================================

  Rule: 提供 Prometheus 格式的系統指標端點

    Example: 获取系統指標
      When 管理員請求 "GET /metrics"
      Then 回傳 Prometheus 格式文字資料
      And 應包含:
        | metric_name              | type    | description  |
        | http_requests_total      | counter | 總請求數     |
        | http_request_duration_ms | summary | 請求延遲分佈 |
        | active_websockets        | gauge   | 當前連線數   |
        | system_memory_usage      | gauge   | 記憶體使用率 |
  # ============================================================
  # Rule: 日誌保留與清理 (Log Retention)
  # ============================================================

  Rule: 定期清理過期日誌以釋放儲存空間

    Example: 自動清理過期日誌
      Given 系統設定 request_logs 保留天數為 30 天
      When 執行每日維護排程 (Daily Maintenance Job)
      Then 應刪除 30 天前的 request_logs 記錄
      And 應刪除 90 天前的 audit_logs 記錄 (依據不同規定的保留期)

    Example: 手動觸發清理
      Given 管理員權限
      When 發送 POST 請求至 "/api/admin/system/cleanup"
        | retention_days |          7 |
        | target_log     | error_logs |
      Then 系統應立即刪除 7 天前的錯誤日誌
      And 回傳刪除筆數
  # ============================================================
  # Rule: 系統配置熱重載
  # ============================================================

  Rule: 支援在不停機的情況下更新特定系統配置

    Example: 更新 Log Level
      When 管理員發送 PATCH 請求至 "/api/admin/system/config":
        | log_level | DEBUG |
      Then 系統應立即調整日誌輸出級別為 DEBUG
      And 不需重啟服務
