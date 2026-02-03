Feature: 請求記錄與可追蹤性 (Request Logging & Traceability)

  Rule: 記錄 API 請求上下文與異常堆疊

    Example: 記錄帶有追蹤資訊的正常請求
      Given 使用者 ID 為 "u_999"
      And 請求 Header 包含 Trace-ID = "trace_abc123"
      And 審計服務正常運作
      When 系統執行 InterceptAndLogRequest (攔截並記錄)
      Then Audit Log 應新增一條紀錄
      And trace_id="trace_abc123", user_id="u_999", status_code=200
      And duration_ms=150
      And 系統應發出 Request_Recorded 事件

    Example: 捕獲並記錄處理過程中的異常
      Given API 處理過程中拋出 ValueError (商業邏輯錯誤)
      When 全域異常處理器捕獲該錯誤
      Then Audit Log 應寫入該請求紀錄
      And status_code=400 (或 500)
      And error_type="ValueError"
      And stack_trace 應包含錯誤發生行數
      And 系統應發出 Exception_Caught 事件
