Feature: 查詢知識庫文件狀態
  # 追蹤 RAG 處理流程的進度

  Rule: 查詢知識庫文件狀態 的核心邏輯
    # 定義 查詢知識庫文件狀態 的相關規則與行為

    Example: 查詢處理狀態
      When 用戶查詢某個文件的狀態
      Then 系統應回傳目前進度 (例如 "Processing", "Completed", "Failed")
      And 顯示解析或向量化的詳細狀態
