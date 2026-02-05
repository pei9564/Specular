Feature: 查詢特定供應商的連線健康紀錄
  監控 LLM 供應商的連線狀態與歷史健康紀錄

  Background:
    Given 系統中存在以下模型配置:
      | id        | provider_type | display_name | last_test_status | last_tested_at      |
      | model-001 | openai        | GPT-4o       | passed           | 2024-01-15 10:00:00 |
      | model-002 | openai        | GPT-3.5      | passed           | 2024-01-15 09:00:00 |
      | model-003 | anthropic     | Claude 3     | failed           | 2024-01-15 08:00:00 |
      | model-004 | azure_openai  | Azure GPT    | passed           | 2024-01-14 12:00:00 |
    And model_connection_tests 表中有以下歷史記錄:
      | id   | model_id  | status | latency_ms | error_code  | tested_at           |
      | t-01 | model-001 | passed |        150 | null        | 2024-01-15 10:00:00 |
      | t-02 | model-001 | passed |        180 | null        | 2024-01-15 08:00:00 |
      | t-03 | model-001 | failed | null       | TIMEOUT     | 2024-01-15 06:00:00 |
      | t-04 | model-001 | passed |        200 | null        | 2024-01-14 10:00:00 |
      | t-05 | model-003 | failed | null       | INVALID_KEY | 2024-01-15 08:00:00 |
      | t-06 | model-003 | failed | null       | INVALID_KEY | 2024-01-15 06:00:00 |
      | t-07 | model-003 | passed |        300 | null        | 2024-01-14 08:00:00 |
    And 使用者 "admin@example.com" 已登入（角色為 admin）
  # ============================================================
  # Rule: 查詢單一模型的健康紀錄
  # ============================================================

  Rule: 管理員可以查詢特定模型的連線健康歷史

    Example: 成功 - 查詢模型健康紀錄
      When 使用者發送 GET 請求至 "/api/admin/models/model-001/health"
      Then 請求應成功，回傳狀態碼 200
      And 回傳結果應包含當前狀態:
        | field            | value               |
        | model_id         | model-001           |
        | display_name     | GPT-4o              |
        | current_status   | healthy             |
        | last_test_status | passed              |
        | last_tested_at   | 2024-01-15 10:00:00 |
        | last_latency_ms  |                 150 |
      And 回傳結果應包含健康統計:
        | field              | value |
        | tests_last_24h     |     4 |
        | success_rate_24h   |  75.0 |
        | avg_latency_ms_24h |   176 |
        | failures_last_24h  |     1 |

    Example: 成功 - 查詢包含歷史記錄
      When 使用者發送 GET 請求至 "/api/admin/models/model-001/health":
        | include_history | true |
        | limit           |   10 |
      Then 回傳結果應包含 history 陣列:
        | id   | status | latency_ms | tested_at           |
        | t-01 | passed |        150 | 2024-01-15 10:00:00 |
        | t-02 | passed |        180 | 2024-01-15 08:00:00 |
        | t-03 | failed | null       | 2024-01-15 06:00:00 |
        | t-04 | passed |        200 | 2024-01-14 10:00:00 |

    Example: 查詢不健康模型的狀態
      When 使用者發送 GET 請求至 "/api/admin/models/model-003/health"
      Then 回傳結果應包含:
        | field                | value       |
        | current_status       | unhealthy   |
        | last_test_status     | failed      |
        | last_error_code      | INVALID_KEY |
        | consecutive_failures |           2 |
  # ============================================================
  # Rule: 查詢所有模型的健康狀態
  # ============================================================

  Rule: 管理員可以查詢所有模型的健康狀態總覽

    Example: 成功 - 查詢健康狀態總覽
      When 使用者發送 GET 請求至 "/api/admin/models/health"
      Then 請求應成功
      And 回傳結果應包含所有模型的狀態:
        | model_id  | display_name | status    | last_test_status | last_latency_ms |
        | model-001 | GPT-4o       | healthy   | passed           |             150 |
        | model-002 | GPT-3.5      | healthy   | passed           | (值)            |
        | model-003 | Claude 3     | unhealthy | failed           | null            |
        | model-004 | Azure GPT    | healthy   | passed           | (值)            |
      And 回傳結果應包含摘要:
        | field           | value |
        | total_models    |     4 |
        | healthy_count   |     3 |
        | unhealthy_count |     1 |
        | unknown_count   |     0 |

    Example: 篩選不健康的模型
      When 使用者發送 GET 請求至 "/api/admin/models/health":
        | status | unhealthy |
      Then 回傳結果應只包含 status 為 "unhealthy" 的模型:
        | model_id  | status    |
        | model-003 | unhealthy |
  # ============================================================
  # Rule: 時間範圍查詢
  # ============================================================

  Rule: 支援查詢特定時間範圍的健康紀錄

    Example: 成功 - 查詢最近 24 小時的紀錄
      When 使用者發送 GET 請求至 "/api/admin/models/model-001/health":
        | period | 24h |
      Then 統計應基於最近 24 小時的數據計算

    Example: 成功 - 查詢最近 7 天的紀錄
      When 使用者發送 GET 請求至 "/api/admin/models/model-001/health":
        | period | 7d |
      Then 統計應基於最近 7 天的數據計算
      And 回傳應包含每日健康狀態趨勢:
        | date       | tests | success_rate | avg_latency |
        | 2024-01-15 |     3 |        66.67 |         165 |
        | 2024-01-14 |     1 |        100.0 |         200 |

    Example: 成功 - 自訂時間範圍
      When 使用者發送 GET 請求至 "/api/admin/models/model-001/health":
        | start_date | 2024-01-14 |
        | end_date   | 2024-01-15 |
      Then 統計應基於指定範圍的數據計算
  # ============================================================
  # Rule: 健康狀態判定
  # ============================================================

  Rule: 系統依據測試結果判定健康狀態

    Example: 健康狀態為 healthy
      Given 模型最近 5 次測試中有 4 次以上成功
      Then 該模型的 current_status 應為 "healthy"

    Example: 健康狀態為 degraded
      Given 模型最近 5 次測試中有 2-3 次成功
      Then 該模型的 current_status 應為 "degraded"

    Example: 健康狀態為 unhealthy
      Given 模型最近 5 次測試中少於 2 次成功
      Then 該模型的 current_status 應為 "unhealthy"

    Example: 健康狀態為 unknown
      Given 模型從未進行過連線測試
      Then 該模型的 current_status 應為 "unknown"
      And last_tested_at 應為 null

    Example: 延遲過高標記為 degraded
      Given 模型測試都成功但平均延遲超過 5000ms
      Then 該模型的 current_status 應為 "degraded"
      And 應標示 high_latency: true
  # ============================================================
  # Rule: 健康檢查告警
  # ============================================================

  Rule: 系統可配置健康檢查告警

    Example: 查詢告警設定
      When 使用者發送 GET 請求至 "/api/admin/models/model-001/health/alerts"
      Then 回傳結果應包含告警設定:
        | field                 | value                 |
        | alert_on_failure      | true                  |
        | consecutive_failures  |                     3 |
        | alert_on_high_latency | true                  |
        | latency_threshold_ms  |                  5000 |
        | alert_recipients      | ["admin@example.com"] |

    Example: 更新告警設定
      When 使用者發送 PATCH 請求至 "/api/admin/models/model-001/health/alerts":
        | consecutive_failures |                   5 |
        | latency_threshold_ms |                3000 |
        | alert_recipients     | ["ops@example.com"] |
      Then 請求應成功
      And model_health_alerts 表應更新

    Example: 觸發告警
      Given model-003 連續失敗達到告警閾值 (3 次)
      Then 系統應發送告警通知:
        | type       | model_health_alert                                      |
        | model_id   | model-003                                               |
        | status     | unhealthy                                               |
        | message    | Model 'Claude 3' has failed 3 consecutive health checks |
        | recipients | (配置的收件人)                                          |
  # ============================================================
  # Rule: 自動健康檢查
  # ============================================================

  Rule: 系統可配置定期自動健康檢查

    Example: 查詢自動檢查設定
      When 使用者發送 GET 請求至 "/api/admin/settings/health-check"
      Then 回傳結果應包含:
        | field            | value  |
        | enabled          | true   |
        | interval_minutes |     30 |
        | check_all_models | true   |
        | last_check_at    | (時間) |
        | next_check_at    | (時間) |

    Example: 更新自動檢查頻率
      When 使用者發送 PATCH 請求至 "/api/admin/settings/health-check":
        | interval_minutes | 15 |
      Then 系統應每 15 分鐘自動檢查所有模型連線
  # ============================================================
  # Rule: 權限控制
  # ============================================================

  Rule: 只有管理員可以查詢健康紀錄

    Example: 失敗 - 一般用戶禁止查詢
      Given 使用者 "user@example.com" 已登入（角色為 user）
      When 使用者發送 GET 請求至 "/api/admin/models/model-001/health"
      Then 請求應失敗，回傳狀態碼 403
  # ============================================================
  # Rule: 匯出功能
  # ============================================================

  Rule: 支援匯出健康紀錄報告

    Example: 成功 - 匯出 CSV 報告
      When 使用者發送 GET 請求至 "/api/admin/models/health/export":
        | format     | csv        |
        | start_date | 2024-01-01 |
        | end_date   | 2024-01-15 |
      Then 請求應成功
      And 回傳應為 CSV 格式的健康紀錄報告
      And Content-Type 應為 "text/csv"
      And Content-Disposition 應包含檔名

    Example: 成功 - 匯出 JSON 報告
      When 使用者發送 GET 請求至 "/api/admin/models/health/export":
        | format | json |
      Then 請求應成功
      And 回傳應為完整的 JSON 格式報告
