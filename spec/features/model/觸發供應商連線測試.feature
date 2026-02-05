Feature: 觸發供應商連線測試
  # 測試與 LLM 供應商的 API 連線是否正常

  Rule: 觸發供應商連線測試 的核心邏輯
    # 定義 觸發供應商連線測試 的相關規則與行為

    Example: 測試 OpenAI 連線
      When 對 "openai" 類型的配置進行連線測試
      Then 系統應發送 GET 請求至 "{base_url}/models"
      And Header 應包含 Authorization: Bearer {key}

    Example: 測試 Azure OpenAI 連線
      When 對 "azure_openai" 類型的配置進行連線測試
      Then 系統應發送 GET 請求至 "{endpoint}/openai/models?api-version=..."
      And Header 應包含 api-key: {key}

    Example: 測試 Anthropic 連線
      When 對 "anthropic" 類型的配置進行連線測試
      Then 系統應發送 POST 請求至 "/v1/messages"
      And Header 應包含 x-api-key: {key}

    Example: 測試 DashScope 連線
      When 對 "dashscope" 類型的配置進行連線測試
      Then 系統應發送 POST 請求至 "/generation"
      And Header 應包含 Authorization: Bearer {key}
