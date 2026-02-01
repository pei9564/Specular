Feature: 請求記錄與可追蹤性 (Request Logging & Traceability)
  Rule: 記錄 API 請求上下文與異常堆疊
    # 涵蓋 Rule 1 (正常記錄) 與 Rule 3 (異常記錄)。
    Example: 記錄帶有追蹤資訊的正常請求 (Rule 1)
      # Given = Context/Preconditions
      Given Context: 使用者 ID 為 "u_999"
        And Context: 請求 Header 包含 Trace-ID = "trace_abc123"
        And Aggregate: 審計服務正常運作
      # When = Command (Middleware 攔截)
      When Command: 系統執行 InterceptAndLogRequest (攔截並記錄)
        And Action: API 處理成功，耗時 150ms
      # Then = Aggregate State (Log 寫入)
      Then Aggregate: Audit Log 應新增一條紀錄
        And Fields: trace_id="trace_abc123", user_id="u_999", status_code=200
        And Fields: duration_ms=150
      # Then = Event
      And Event: 系統應發出 Request_Recorded 事件
    Example: 捕獲並記錄處理過程中的異常 (Rule 3)
      # Given = Event (發生錯誤)
      Given Event: API 處理過程中拋出 ValueError (商業邏輯錯誤)
      
      # When = Command (異常處理器介入)
      When Command: 全域異常處理器捕獲該錯誤
      # Then = Aggregate State (Log 更新)
      Then Aggregate: Audit Log 應寫入該請求紀錄
        And Fields: status_code=400 (或 500)
        And Fields: error_type="ValueError"
        And Fields: stack_trace 應包含錯誤發生行數
      # Then = Event
      And Event: 系統應發出 Exception_Caught 事件
