Feature: 綁定 Agent 與 Skills
  # 選擇已註冊的 Skills 賦予 Agent 能力

  Rule: 綁定 Agent 與 Skills 的核心邏輯
    # 定義 綁定 Agent 與 Skills 的相關規則與行為

    Example: 綁定多個 Skills
      Given 系統中已存在 Skill "Calculator" 與 "Search"
      When 用戶在 Agent 配置中勾選這兩個 Skills
      Then 系統應建立綁定關係
      And Agent 執行時應能調用這些 Skill 的函數
