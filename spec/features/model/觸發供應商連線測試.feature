Feature: 觸發供應商連線測試
  測試與 LLM 供應商的 API 連線是否正常

  Background:
    Given 系統中存在以下模型配置:
      | id        | provider_type | display_name | model_name    | api_key_encrypted | base_url                       | endpoint                     |
      | model-001 | openai        | GPT-4o       | gpt-4o        | (加密的 key)      | https://api.openai.com/v1      | null                         |
      | model-002 | azure_openai  | Azure GPT-4  | gpt-4         | (加密的 key)      | null                           | https://xxx.openai.azure.com |
      | model-003 | anthropic     | Claude 3     | claude-3-opus | (加密的 key)      | https://api.anthropic.com      | null                         |
      | model-004 | dashscope     | 通義千問     | qwen-max      | (加密的 key)      | https://dashscope.aliyuncs.com | null                         |
      | model-005 | ollama        | Local Llama  | llama3:8b     | null              | http://localhost:11434         | null                         |
    And 使用者 "admin@example.com" 已登入（角色為 admin）
  # ============================================================
  # Rule: OpenAI 連線測試
  # ============================================================

  Rule: 測試 OpenAI 類型的連線

    Example: 成功 - OpenAI 連線測試通過
      When 使用者發送 POST 請求至 "/api/admin/models/model-001/test"
      Then 系統應發送請求:
        | method  | GET                                    |
        | url     | https://api.openai.com/v1/models       |
        | headers | Authorization: Bearer (解密的 api_key) |
      And 若 API 回應 200，請求應成功
      And 回傳結果應包含:
        | field      | value          |
        | status     | passed         |
        | latency_ms | (回應時間毫秒) |
        | tested_at  | (當前時間)     |
      And model_providers 表中 model-001 應更新:
        | field             | value      |
        | last_tested_at    | (當前時間) |
        | last_test_status  | passed     |
        | last_test_latency | (延遲毫秒) |

    Example: 失敗 - OpenAI API Key 無效
      Given model-001 的 api_key 已過期或無效
      When 使用者發送 POST 請求至 "/api/admin/models/model-001/test"
      Then API 應回應 401 Unauthorized
      And 請求應成功（測試本身成功執行），回傳狀態碼 200
      And 回傳結果應包含:
        | field         | value                    |
        | status        | failed                   |
        | error_code    | INVALID_API_KEY          |
        | error_message | Invalid API key provided |
      And model_providers 表中 model-001 應更新:
        | field            | value  |
        | last_test_status | failed |

    Example: 失敗 - OpenAI API 逾時
      Given OpenAI API 無回應（逾時 30 秒）
      When 使用者發送 POST 請求至 "/api/admin/models/model-001/test"
      Then 回傳結果應包含:
        | field         | value                |
        | status        | failed               |
        | error_code    | TIMEOUT              |
        | error_message | Connection timed out |
  # ============================================================
  # Rule: Azure OpenAI 連線測試
  # ============================================================

  Rule: 測試 Azure OpenAI 類型的連線

    Example: 成功 - Azure OpenAI 連線測試通過
      Given model-002 的配置:
        | endpoint        | https://xxx.openai.azure.com |
        | deployment_name | my-gpt4-deployment           |
        | api_version     |           2024-02-15-preview |
      When 使用者發送 POST 請求至 "/api/admin/models/model-002/test"
      Then 系統應發送請求:
        | method  | GET                                                                            |
        | url     | https://xxx.openai.azure.com/openai/deployments?api-version=2024-02-15-preview |
        | headers | api-key: (解密的 api_key)                                                      |
      And 若 API 回應 200，測試應標記為 passed

    Example: 失敗 - Azure 端點無效
      Given model-002 的 endpoint 無法連線
      When 使用者發送 POST 請求至 "/api/admin/models/model-002/test"
      Then 回傳結果應包含:
        | field         | value                         |
        | status        | failed                        |
        | error_code    | CONNECTION_ERROR              |
        | error_message | Unable to connect to endpoint |
  # ============================================================
  # Rule: Anthropic 連線測試
  # ============================================================

  Rule: 測試 Anthropic 類型的連線

    Example: 成功 - Anthropic 連線測試通過
      When 使用者發送 POST 請求至 "/api/admin/models/model-003/test"
      Then 系統應發送請求:
        | method  | POST                                                                                           |
        | url     | https://api.anthropic.com/v1/messages                                                          |
        | headers | x-api-key: (解密的 api_key), anthropic-version: 2023-06-01                                     |
        | body    | {"model": "claude-3-opus", "max_tokens": 1, "messages": [{"role": "user", "content": "test"}]} |
      And 若 API 回應成功，測試應標記為 passed

    Example: 失敗 - Anthropic Rate Limit
      Given Anthropic API 回應 429 Too Many Requests
      When 使用者發送 POST 請求至 "/api/admin/models/model-003/test"
      Then 回傳結果應包含:
        | field         | value                   |
        | status        | failed                  |
        | error_code    | RATE_LIMITED            |
        | error_message | API rate limit exceeded |
  # ============================================================
  # Rule: DashScope 連線測試
  # ============================================================

  Rule: 測試 DashScope 類型的連線

    Example: 成功 - DashScope 連線測試通過
      When 使用者發送 POST 請求至 "/api/admin/models/model-004/test"
      Then 系統應發送請求:
        | method  | POST                                                                           |
        | url     | https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation |
        | headers | Authorization: Bearer (解密的 api_key)                                         |
      And 若 API 回應成功，測試應標記為 passed
  # ============================================================
  # Rule: Ollama 連線測試
  # ============================================================

  Rule: 測試本地 Ollama 連線

    Example: 成功 - Ollama 連線測試通過
      When 使用者發送 POST 請求至 "/api/admin/models/model-005/test"
      Then 系統應發送請求:
        | method | GET                             |
        | url    | http://localhost:11434/api/tags |
      And 若 API 回應 200 且包含模型列表，測試應標記為 passed

    Example: 失敗 - Ollama 服務未啟動
      Given Ollama 服務未在 localhost:11434 運行
      When 使用者發送 POST 請求至 "/api/admin/models/model-005/test"
      Then 回傳結果應包含:
        | field         | value                                 |
        | status        | failed                                |
        | error_code    | CONNECTION_REFUSED                    |
        | error_message | Connection refused to localhost:11434 |

    Example: 失敗 - 模型未安裝
      Given Ollama 服務運行中但未安裝 llama3:8b 模型
      When 使用者發送 POST 請求至 "/api/admin/models/model-005/test"
      Then 回傳結果應包含:
        | field   | value                               |
        | status  | warning                             |
        | warning | Model 'llama3:8b' not found locally |
  # ============================================================
  # Rule: 批次測試
  # ============================================================

  Rule: 支援批次測試多個模型

    Example: 成功 - 批次測試所有模型
      When 使用者發送 POST 請求至 "/api/admin/models/test-all"
      Then 系統應依序測試所有啟用的模型
      And 回傳結果應包含每個模型的測試結果:
        | model_id  | status  |
        | model-001 | passed  |
        | model-002 | passed  |
        | model-003 | failed  |
        | model-004 | passed  |
        | model-005 | warning |
      And 回傳應包含摘要:
        | total   | 5 |
        | passed  | 3 |
        | failed  | 1 |
        | warning | 1 |

    Example: 批次測試特定模型
      When 使用者發送 POST 請求至 "/api/admin/models/test-batch":
        | model_ids | ["model-001", "model-003"] |
      Then 系統應只測試指定的模型
      And 回傳結果應只包含 model-001 和 model-003
  # ============================================================
  # Rule: 權限控制
  # ============================================================

  Rule: 只有管理員可以觸發連線測試

    Example: 失敗 - 一般用戶禁止測試
      Given 使用者 "user@example.com" 已登入（角色為 user）
      When 使用者發送 POST 請求至 "/api/admin/models/model-001/test"
      Then 請求應失敗，回傳狀態碼 403
  # ============================================================
  # Rule: 測試結果記錄
  # ============================================================

  Rule: 測試結果應記錄歷史

    Example: 記錄測試歷史
      When 管理員觸發連線測試
      Then model_connection_tests 表應新增一筆記錄:
        | field         | value      |
        | model_id      | model-001  |
        | status        | passed     |
        | latency_ms    | (延遲毫秒) |
        | error_code    | null       |
        | error_message | null       |
        | tested_by     | admin-001  |
        | tested_at     | (當前時間) |

    Example: 查詢測試歷史
      When 使用者發送 GET 請求至 "/api/admin/models/model-001/test-history":
        | limit | 10 |
      Then 回傳結果應包含最近 10 筆測試記錄
