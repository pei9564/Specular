Feature: 日誌韌性與過濾 (Logging Resilience & Filtering)
  Rule: 排除健康檢查雜訊並確保業務不中斷
    Example: 忽略健康檢查路徑
      Given Context: 請求路徑 (Path) 為 "/health" 或 "/metrics"
      When Command: 系統攔截到請求
      Then Event: 系統不應發出 Request_Recorded 事件
      And Aggregate: Audit Log 不應新增任何紀錄
    Example: 日誌資料庫故障時不影響 API 回應
      Given Event: 審計日誌資料庫 (Log DB) 連線逾時或磁碟已滿
      When Command: 系統嘗試寫入日誌
      Then Event: 系統應發出 Audit_Write_Failed 警示
      But Return: 原始 API Response 仍應正常回傳
      And Check: 使用者不應收到 500 Internal Server Error