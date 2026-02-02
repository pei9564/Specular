Feature: 工具庫存取 (Tool Registry Access)
  Rule: 查詢可用工具模板 (Templates)
    # 這是建立新 Tool Instance 時的前置查詢
    
    Example: 取得系統支援的工具模板清單
      Given Aggregate: 系統已註冊以下 Tool Template：
        | Template ID | Name        | Schema              |
        | web_scraper | Web Scraper | { target_url: str } |
      When Query: 執行 GetToolTemplates (取得模板)
      Then Read Model: 應回傳 "Web Scraper" 模板

  Rule: 查詢已建立的工具實例 (Instances)
    # 這是 Agent 綁定工具時的查詢
    
    Example: 取得使用者已建立的工具實例
      Given Aggregate: 使用者已基於 "web_scraper" 建立以下實例：
        | Instance ID  | Name         | Config                  |
        | ptt_scraper  | PTT Crawler  | { target_url: ptt.cc }  |
        | news_scraper | News Crawler | { target_url: news.com }|
      When Query: 執行 GetToolInstances (取得實例)
      Then Read Model: 回傳清單應包含 "PTT Crawler" 與 "News Crawler"
      And Check: 兩者皆源自同一個 Template 但具備不同 Config