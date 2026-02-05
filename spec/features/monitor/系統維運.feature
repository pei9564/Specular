Feature: 系統維運
  # 系統健康監控與資料清理

  Rule: 系統維運 的核心邏輯
    # 定義 系統維運 的相關規則與行為

    Example: 系統健康檢查
      When 請求 "/health" 端點
      Then 系統應回傳 200 OK
      And 顯示資料庫連線狀態為 "healthy"
      And 顯示 Redis/VectorDB 連線狀態

    Example: 錯誤警示
      When 系統關鍵服務斷線 (如 DB 連線失敗)
      Then 系統應記錄 Critical 級別的日誌
