Feature: 工具實例管理 (Tool Instance Management)

  Rule: 基於模板建立新的工具實例 (Instantiation)
    # 這是使用者將通用工具 (Template) 具象化為專用工具 (Instance) 的過程

    Example: 成功建立 PTT 爬蟲實例
      Given Aggregate: 系統存在 "web_scraper" 工具模板 (Schema: {target_url: str})
      When Command: 執行 CreateToolInstance，參數如下：
        | name        | PTT Scraper              |
        | template_id | web_scraper              |
        | config      | { target_url: "ptt.cc" } |
      Then Aggregate: 應建立一個新的 ToolInstance "PTT Scraper"
      And Check: 該實例綁定 "web_scraper" 且 Config 正確
      And Event: 系統應發布 Tool_Instance_Created 事件

    Example: 參數驗證失敗 (Schema Validation Violation)
      Given Aggregate: 系統存在 "web_scraper" 工具模板
      When Command: 執行 CreateToolInstance，參數如下：
        | name        | Broken Scraper                           |
        | template_id | web_scraper                              |
        | config      | { timeout: 500 } (缺少必要的 target_url) |
      Then Return: 系統應回傳 Error "Invalid Configuration"
      And Aggregate: 工具實例不應被建立

  Rule: 更新與刪除工具實例
    # 工具實例的生命週期管理

    Example: 更新工具實例的 Config
      Given Aggregate: 存在實例 "News Crawler" (Config: {target: "cnn.com"})
      When Command: 執行 UpdateToolInstance，更新 config 為 {target: "bbc.com"}
      Then Aggregate: 實例的 Config 應更新為 {target: "bbc.com"}
      And Event: 系統應發布 Tool_Instance_Updated 事件

    Example: 刪除已被 Agent 綁定的實例 (參照完整性)
      Given Aggregate: 實例 "Math Tool" 目前被 Agent "MathGuru" 綁定使用中
      When Command: 執行 DeleteToolInstance (Math Tool)
      Then Return: 系統應回傳 Error "Resource In Use"
      And Aggregate: 實例 "Math Tool" 應仍保留在系統中
