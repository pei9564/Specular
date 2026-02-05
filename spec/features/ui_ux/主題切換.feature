Feature: 主題切換
  # 支援淺色、深色及跟隨系統的主題模式，並規範品牌色彩

  Rule: 主題切換 的核心邏輯
    # 定義 主題切換 的相關規則與行為

    Example: 切換至深色主題
      When 用戶選擇 "dark" 主題
      Then 應用程式背景色應變更為深色 "#0F172A"
      And 用戶的主題偏好應被儲存

    Example: 切換至淺色主題
      When 用戶選擇 "light" 主題
      Then 應用程式背景色應變更為淺色 "#F8FAFC"
      And 用戶的主題偏好應被儲存

    Example: 跟隨系統設定
      When 用戶選擇 "system" 主題
      And 系統作業系統設定為深色模式
      Then 應用程式應自動應用深色主題

    Example: 品牌色彩一致性
      When 顯示主要的品牌元素 (如按鈕、Logo)
      Then 應使用金色 "#D4AF37" 作為主色調
