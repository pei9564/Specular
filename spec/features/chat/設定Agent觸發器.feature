Feature: 設定 Agent 觸發器
  # 配置 Agent 的主動執行條件 (Triggers)

  Rule: 設定 Agent 觸發器 的核心邏輯
    # 定義 設定 Agent 觸發器 的相關規則與行為

    Example: 設定排程觸發 (Schedule)
      When 為 Agent 設定 Schedule Trigger
      Then 系統應在指定時間自動執行該 Agent

    Example: 設定 Webhook 觸發
      When 為 Agent 設定 Webhook Trigger
      Then 系統應產生一組 Webhook URL
      And When收到帶有正確 Secret 的請求時執行 Agent

    Example: 觸發時傳遞 Input Template
      When 觸發器執行時
      Then 系統應根據 input_template 解析傳入資料 (如 {{payload.username}})
