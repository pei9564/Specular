Feature: 審計日誌檢視 (Audit Log Inspection)

  Rule: 管理員查詢與追蹤審計紀錄

    Example: 根據 Trace ID 追蹤特定請求
      Given Aggregate: Audit Log 資料庫中存在 trace_id="trace_abc123" 的紀錄
      And Content: 該紀錄包含被遮罩後的 password
      And Context: 查詢者擁有 "Admin" 權限
      When Query: 執行 SearchAuditLogs，參數如下：
        | trace_id | trace_abc123 |
      Then Read Model: 應回傳該筆請求的詳細資訊
      And Field: password 欄位應仍為 "******" (確保即使是 Admin 也看不到明文)
