Feature: 多語言設定
  # 支援繁體中文與 English 切換，預設為繁體中文

  Rule: 多語言設定 的核心邏輯
    # 定義 多語言設定 的相關規則與行為

    Example: 切換語言至英文
      When 用戶將語言設定切換為 "en"
      Then 介面文字應顯示為英文
      And 語言偏好應儲存於 localStorage

    Example: 系統預設語言
      Given 用戶首次訪問且無儲存偏好
      Then 系統預設語言應為 "zh-TW" (繁體中文)

    Example: 切換語言至繁體中文
      When 用戶將語言設定切換為 "zh-TW"
      Then 介面文字應顯示為繁體中文
