Feature: LLM 註冊與配置管理 (LLM Registry Management)
  # 本 Feature 定義管理員如何管理 LLM 註冊表，包含狀態控制、權限設定、供應商配置與運行時影響

  Rule: 模型生命週期與存取權限控制
    # 允許管理員控制模型是否啟用 (ACTIVE/INACTIVE) 以及可見範圍 (PUBLIC/ADMIN_ONLY)

    Example: 將模型從停用改為啟用
      # 測試目標：驗證管理員能啟用已停用的模型
      Given 系統中存在以下 LLM, in table "llm_registry":
        | id     | modelId                  | status   | accessLevel |
        | llm_01 | internal-finetuned-model | INACTIVE | ADMIN_ONLY  |
      And 請求者為管理員, with userId="u_admin", role="ADMIN"
      When 執行 API "UpdateModelAccess", call:
        | endpoint       | method | pathParams       | bodyParams           |
        | /api/llms/{id} | PATCH  | { id: "llm_01" } | { status: "ACTIVE" } |
      Then 回應 HTTP 200, with data:
        | field       | value                    | type   |
        | id          | llm_01                   | string |
        | modelId     | internal-finetuned-model | string |
        | status      | ACTIVE                   | string |
        | accessLevel | ADMIN_ONLY               | string |
        | message     | Model access updated     | string |
      And 資料庫 table "llm_registry" 應更新記錄:
        | id     | status | updatedAt           |
        | llm_01 | ACTIVE | 2026-02-04T00:00:00 |

    Example: 將模型發布為全員可用 (PUBLIC)
      # 測試目標：驗證管理員能變更模型的存取權限等級
      Given 系統中存在以下 LLM, in table "llm_registry":
        | id     | modelId | status | accessLevel |
        | llm_02 | gpt-4o  | ACTIVE | ADMIN_ONLY  |
      And 請求者為管理員, with userId="u_admin", role="ADMIN"
      When 執行 API "UpdateModelAccess", call:
        | endpoint       | method | pathParams       | bodyParams                |
        | /api/llms/{id} | PATCH  | { id: "llm_02" } | { accessLevel: "PUBLIC" } |
      Then 回應 HTTP 200, with data:
        | field       | value  | type   |
        | id          | llm_02 | string |
        | modelId     | gpt-4o | string |
        | accessLevel | PUBLIC | string |
      And 資料庫 table "llm_registry" 應更新記錄:
        | id     | accessLevel | updatedAt           |
        | llm_02 | PUBLIC      | 2026-02-04T00:00:00 |
      And 系統應發布事件 "ModelPublished", with payload:
        | field   | value  |
        | modelId | llm_02 |

    Example: 停用舊版模型 (Deactivate)
      # 測試目標：驗證管理員能停用模型，使其不再出現在查詢清單中
      Given 系統中存在以下 LLM, in table "llm_registry":
        | id     | modelId        | status |
        | llm_03 | gpt-3.5-legacy | ACTIVE |
      And 請求者為管理員, with userId="u_admin", role="ADMIN"
      When 執行 API "UpdateModelStatus", call:
        | endpoint       | method | pathParams       | bodyParams             |
        | /api/llms/{id} | PATCH  | { id: "llm_03" } | { status: "INACTIVE" } |
      Then 回應 HTTP 200, with data:
        | field   | value          | type   |
        | id      | llm_03         | string |
        | modelId | gpt-3.5-legacy | string |
        | status  | INACTIVE       | string |
      And 資料庫 table "llm_registry" 應更新記錄:
        | id     | status   | updatedAt           |
        | llm_03 | INACTIVE | 2026-02-04T00:00:00 |
      And 該模型不應再出現在一般使用者的查詢清單中

  Rule: 配置參數驗證
    # 確保輸入的狀態與權限參數符合系統定義

    Example: 嘗試設定無效的狀態值
      # 測試目標：驗證系統的參數驗證機制
      Given 請求者為管理員, with userId="u_admin", role="ADMIN"
      And 系統中存在以下 LLM, in table "llm_registry":
        | id     | modelId | status |
        | llm_04 | gpt-4o  | ACTIVE |
      When 執行 API "UpdateModelStatus", call:
        | endpoint       | method | pathParams       | bodyParams                |
        | /api/llms/{id} | PATCH  | { id: "llm_04" } | { status: "SuperActive" } |
      Then 回應 HTTP 400, with error:
        | field   | value                                     | type   |
        | code    | INVALID_STATUS_VALUE                      | string |
        | message | 無效的狀態值                              | string |
        | details | { allowedValues: ["ACTIVE", "INACTIVE"] } | object |
      And 資料庫 table "llm_registry" 不應變更任何記錄

  Rule: 支援多種後端供應商配置 (Provider Configuration)
    # Configuration Rules - 針對 OpenAI Compatible, vLLM, Ollama 提供差異化設定

    Example: 註冊 vLLM 自架服務 (OpenAI Compatible Interface)
      # 測試目標：驗證系統支援註冊自架的 vLLM 服務
      Given 企業內部架設了 vLLM server, baseUrl="http://10.0.0.5:8000/v1"
      And 請求者為管理員, with userId="u_admin", role="ADMIN"
      When 執行 API "RegisterModel", call:
        | endpoint  | method | bodyParams                                                                                                                                                       |
        | /api/llms | POST   | { modelId: "internal-llama3-70b", provider: "vllm", capabilities: ["tool_use", "json_mode"], config: { baseUrl: "http://10.0.0.5:8000/v1", maxModelLen: 4096 } } |
      Then 回應 HTTP 201, with data:
        | field        | value                                                     | type   |
        | id           | llm_05                                                    | string |
        | modelId      | internal-llama3-70b                                       | string |
        | provider     | vllm                                                      | string |
        | capabilities | ["tool_use", "json_mode"]                                 | array  |
        | config       | { baseUrl: "http://10.0.0.5:8000/v1", maxModelLen: 4096 } | object |
        | status       | ACTIVE                                                    | string |
      And 資料庫 table "llm_registry" 應新增記錄:
        | id     | modelId             | provider | status | createdAt           |
        | llm_05 | internal-llama3-70b | vllm     | ACTIVE | 2026-02-04T00:00:00 |
      And 系統應嘗試發送測試請求到 "http://10.0.0.5:8000/v1" 並確認成功

    Example: 嘗試使用不支援的 Capability 值 (驗證失敗)
      # 測試目標：驗證系統對 capabilities 欄位的驗證
      Given 請求者為管理員, with userId="u_admin", role="ADMIN"
      When 執行 API "RegisterModel", call:
        | endpoint  | method | bodyParams                                               |
        | /api/llms | POST   | { modelId: "test-model", capabilities: ["fly_to_moon"] } |
      Then 回應 HTTP 400, with error:
        | field   | value                                                                                            | type   |
        | code    | INVALID_CAPABILITY                                                                               | string |
        | message | 無效的能力值                                                                                     | string |
        | details | { invalidValue: "fly_to_moon", allowedValues: ["tool_use", "vision", "json_mode", "streaming"] } | object |

  Rule: 模型停用之運行時影響 (Inactive Runtime Impact)
    # Inactive Rule - 確保已停用的模型直接導致運行時錯誤

    Example: 使用已停用模型的 Topic 嘗試進行對話 (失敗)
      # 測試目標：驗證停用模型後，關聯的對話會被阻止
      Given 系統中存在以下 LLM, in table "llm_registry":
        | id     | modelId        | status   |
        | llm_06 | gpt-3.5-legacy | INACTIVE |
      And 存在以下 Topic, in table "topics":
        | id        | name      | llmId  | status |
        | topic_old | Old Topic | llm_06 | ACTIVE |
      When 執行 API "SubmitChatMessage", call:
        | endpoint                  | method | bodyParams                                 |
        | /api/topics/{id}/messages | POST   | { topicId: "topic_old", message: "Hello" } |
      Then 回應 HTTP 400, with error:
        | field   | value                                                                | type   |
        | code    | MODEL_INACTIVE                                                       | string |
        | message | 此對話使用的模型已停用，請更新 Topic 設定                            | string |
        | details | { topicId: "topic_old", llmId: "llm_06", modelId: "gpt-3.5-legacy" } | object |
      And 系統應提示使用者手動更新 Topic 的模型設定
