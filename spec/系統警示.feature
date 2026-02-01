Feature: 系統警示 (System Alerting)
  Rule: 監控與警示觸發
    Example: 處理資料庫連線失敗
      Given Event: 偵測到 UpstreamConnectionFailed
      When Command: 執行 TriggerInternalAlert
        With arguments:
          - severity: "High"
          - source: "LLM-Availability-Service"
          - reason: "Database Unreachable"
      Then Event: 應發布 AlertBroadcasted
        And Payload: 包含錯誤代碼與時間戳記
      And Return: 成功訊息 "Alert processed successfully"