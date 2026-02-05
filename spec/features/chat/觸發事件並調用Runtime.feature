Feature: 觸發事件並調用 Runtime
  # 系統內部處理觸發事件的流程

  Rule: 觸發事件並調用 Runtime 的核心邏輯
    # 定義 觸發事件並調用 Runtime 的相關規則與行為

    Example: 執行觸發流程
      When 觸發條件滿足 (如排程時間到)
      Then 系統應創建 TriggerExecution 記錄
      And 根據 Input Template 生成輸入
      And 調用 AgentScope Runtime 執行 Agent
      And 更新 Execution 記錄為 "Completed" 或 "Failed"
