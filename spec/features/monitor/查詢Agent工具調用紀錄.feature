Feature: 查詢 Agent 工具調用紀錄
  # 監控 Agent 運行狀態與工具使用情況

  Rule: 查詢 Agent 工具調用紀錄 的核心邏輯
    # 定義 查詢 Agent 工具調用紀錄 的相關規則與行為

    Example: 查看工具調用日誌
      When 管理員查詢 Agent 的執行紀錄
      Then 系統應顯示工具呼叫的名稱、輸入參數與執行結果
      And 顯示執行耗時
