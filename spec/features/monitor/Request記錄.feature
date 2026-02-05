Feature: Request 記錄與錯誤追蹤
  # 監控系統錯誤與 API 請求

  Rule: Request 記錄與錯誤追蹤 的核心邏輯
    # 定義 Request 記錄與錯誤追蹤 的相關規則與行為

    Example: 查看錯誤日誌
      When 系統發生錯誤
      Then 錯誤詳情與 Stack Trace 應被記錄
      And 管理員可透過監控面板查看

    Example: OpenTelemetry Traces
      When 請求經過多個模組
      Then 系統應產生 Trace ID 並記錄完整的調用鏈路
