Feature: 工具實例管理 (Tool Instance Management)

  Rule: 基於模板建立新的工具實例 (Instantiation)
    # 這是使用者將通用工具 (Template) 具象化為專用工具 (Instance) 的過程

    Example: 成功建立 PTT 爬蟲實例
      Given 系統存在 "web_scraper" 工具模板 (Schema: {target_url: str})
      When 執行 CreateToolInstance，參數如下：
        | name        | PTT Scraper              |
        | template_id | web_scraper              |
        | config      | { target_url: "ptt.cc" } |
      Then 應建立一個新的 ToolInstance "PTT Scraper"
      And 該實例綁定 "web_scraper" 且 Config 正確
      And 系統應發布 Tool_Instance_Created 事件

    Example: 參數驗證失敗 (Schema Validation Violation)
      Given 系統存在 "web_scraper" 工具模板
      When 執行 CreateToolInstance，參數如下：
        | name        | Broken Scraper                           |
        | template_id | web_scraper                              |
        | config      | { timeout: 500 } (缺少必要的 target_url) |
      Then 回傳 Error "Invalid Configuration"
      And 工具實例不應被建立

  Rule: 更新與刪除工具實例 (傳導至綁定 Agent)
    # 工具實例的更動應自動反映在引用它的 Agent 上

    Example: 更新工具實例會立即影響引用它的 Agent
      Given 存在實例 "News Crawler" (Config: {target: "cnn.com"})
      And Agent "Researcher" 已綁定 "News Crawler"
      When 執行 UpdateToolInstance，將 "News Crawler" 的 config 更新為 {target: "bbc.com"}
      Then "News Crawler" 的實例 Config 應更新
      And Agent "Researcher" 在使用該工具時將自動套用新配置 (bbc.com)
      And Agent 資料表之記錄應無需任何更動 (引用關係不變)
      And 系統應發布 Tool_Instance_Updated 事件

    Example: 刪除工具實例後，引用該工具的 Agent 應自動移除綁定
      Given 實例 "Math Tool" 目前被 Agent "MathGuru" 綁定
      When 執行 DeleteToolInstance ("Math Tool")
      Then 系統應成功執行刪除行為
      And Agent "MathGuru" 的工具清單中應不再包含 "Math Tool"
      And 系統應發布 Tool_Instance_Deleted 事件

  Rule: 工具模板 (ToolTemplate) 的生命週期管理
    # 工具模板是系統底層定義，刪除模板將產生層聯影響

    Example: 刪除模板時層聯刪除所有實例
      Given 系統存在模板 "web_scraper"
      And 已建立實例 "PTT Scraper" (基於 "web_scraper")
      And Agent "Researcher" 已綁定 "PTT Scraper"
      When 執行 DeleteToolTemplate ("web_scraper")
      Then 模板 "web_scraper" 應被移除
      And 實例 "PTT Scraper" 應被自動刪除 (Cascade)
      And Agent "Researcher" 的工具清單中應不再包含 "PTT Scraper"
      And 系統應發布 Tool_Template_Deleted 事件
