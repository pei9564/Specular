Feature: Agent 模式設定
  # 設定 Agent 為被動對話或主動觸發模式

  Rule: Agent 模式設定 的核心邏輯
    # 定義 Agent 模式設定 的相關規則與行為

    Example: 設定為對話模式 (Chat)
      When Agent 模式設為 "chat"
      Then 該 Agent 應能出現在對話列表中
      And 等待使用者輸入訊息後回應

    Example: 設定為觸發器模式 (Triggers)
      When Agent 模式設為 "triggers"
      Then 該 Agent 主要由事件或排程觸發
      And 適用於自動化任務場景
