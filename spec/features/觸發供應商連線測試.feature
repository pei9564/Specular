Feature: 觸發供應商連線測試
  測試與 LLM 供應商的 API 連線是否正常

  Background:
    Given 系統中存在多種 LLM 模型配置 (OpenAI, Azure, Anthropic, Ollama等)
    And 使用者 "admin" 已登入

  Rule: 測試 OpenAI 類型的連線

    Example: 成功 - OpenAI 連線測試通過
      When 管理員觸發 OpenAI 模型配置的連線測試
      Then 系統應使用儲存的 API Key 向 OpenAI 發送測試請求
      And 若回應正常，測試狀態應更新為 "passed"
      And model_providers 表應記錄測試時間與延遲

    Example: 失敗 - OpenAI API Key 無效
      When 管理員觸發測試但 API Key 無效
      Then 測試狀態應更新為 "failed"
      And 錯誤訊息應記錄 Invalid API Key

  Rule: 測試 Azure OpenAI 類型的連線

    Example: 成功 - Azure OpenAI 連線測試通過
      When 管理員觸發 Azure OpenAI 模型配置的連線測試
      Then 系統應向 Azure Endpoint 發送測試請求
      And 若回應正常，測試狀態應更新為 "passed"

    Example: 失敗 - Endpoint 無法連線
      When 管理員觸發測試但 Endpoint 無法訪問
      Then 測試狀態應更新為 "failed"

  Rule: 測試 Anthropic 類型的連線

    Example: 成功 - Anthropic 連線測試通過
      When 管理員觸發 Anthropic 模型配置的連線測試
      Then 系統應向 Anthropic API 發送測試請求
      And 若回應正常，測試狀態應更新為 "passed"

  Rule: 測試 DashScope 類型的連線

    Example: 成功 - DashScope 連線測試通過
      When 管理員觸發 DashScope 模型配置的連線測試
      Then 系統應向 DashScope API 發送測試請求
      And 若回應正常，測試狀態應更新為 "passed"

  Rule: 測試本地 Ollama 連線

    Example: 成功 - Ollama 連線測試通過
      When 管理員觸發 Ollama 配置的連線測試
      Then 系統應向 Ollama Local Endpoint 發送測試請求
      And 若回應正常，測試狀態應更新為 "passed"

    Example: 失敗 - Ollama 服務未啟動
      When 管理員觸發測試但 Ollama 服務未運行
      Then 測試狀態應更新為 "failed"
      And 錯誤訊息應提示 Connection Refused

  Rule: 支援批次測試多個模型

    Example: 成功 - 批次測試所有模型
      When 管理員觸發「測試所有模型」
      Then 系統應依序測試所有啟用的供應商配置
      And 應回傳每個模型的測試結果摘要（成功/失敗數量）

  Rule: 只有管理員可以觸發連線測試

    Example: 失敗 - 一般用戶禁止測試
      Given 一般使用者嘗試觸發測試
      Then 操作應被拒絕，提示權限不足

  Rule: 測試結果應記錄歷史

    Example: 記錄測試歷史
      When 連線測試完成
      Then model_connection_tests 表應新增一筆記錄
      And 記錄應包含測試狀態、延遲時間與執行者
