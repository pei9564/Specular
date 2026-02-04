Feature: LLM 查詢 (LLM Registry Query)
  # 本 Feature 定義使用者如何查詢可用的 LLM 模型，包含權限過濾與異常處理

  Rule: 依據使用者權限過濾可見模型 (Visibility)
    # Visibility Rule - 確保使用者只能看到他們有權存取的模型

    Example: 一般使用者查詢混合權限的模型列表
      # 測試目標：驗證系統能正確依據使用者權限過濾模型清單
      Given 系統中存在以下 LLM, in table "llm_registry":
        | id     | modelId                  | status | accessLevel |
        | llm_01 | gpt-4o                   | ACTIVE | PUBLIC      |
        | llm_02 | internal-finetuned-model | ACTIVE | ADMIN_ONLY  |
      And 使用者資訊:
        | userId | role |
        | u_001  | USER |
      When 執行 API "CheckUsableLLMs", call:
        | endpoint  | method | queryParams        |
        | /api/llms | GET    | { status: ACTIVE } |
      Then 回應 HTTP 200, with table:
        | id     | modelId | status | accessLevel |
        | llm_01 | gpt-4o  | ACTIVE | PUBLIC      |
      And 回傳清單總數應為 1
      And 回傳結果不應包含 modelId="internal-finetuned-model"

    Example: 管理員查詢所有可用模型
      # 測試目標：驗證管理員能查看所有可用模型
      Given 系統中存在以下 LLM, in table "llm_registry":
        | id     | modelId                  | status | accessLevel |
        | llm_01 | gpt-4o                   | ACTIVE | PUBLIC      |
        | llm_02 | internal-finetuned-model | ACTIVE | ADMIN_ONLY  |
      And 使用者資訊:
        | userId  | role  |
        | u_admin | ADMIN |
      When 執行 API "CheckUsableLLMs", call:
        | endpoint  | method | queryParams        |
        | /api/llms | GET    | { status: ACTIVE } |
      Then 回應 HTTP 200, with table:
        | id     | modelId                  | status | accessLevel |
        | llm_01 | gpt-4o                   | ACTIVE | PUBLIC      |
        | llm_02 | internal-finetuned-model | ACTIVE | ADMIN_ONLY  |
      And 回傳清單總數應為 2

  Rule: 無符合權限模型時回傳空集合 (Empty State)
    # Empty State Rule - 當過濾後無結果時，應回傳空清單而非錯誤

    Example: 一般使用者查詢僅含私有模型的環境
      # 測試目標：驗證空結果的正確處理，不應返回錯誤
      Given 系統中存在以下 LLM, in table "llm_registry":
        | id     | modelId                  | status | accessLevel |
        | llm_02 | internal-finetuned-model | ACTIVE | ADMIN_ONLY  |
      And 使用者資訊:
        | userId | role |
        | u_002  | USER |
      When 執行 API "CheckUsableLLMs", call:
        | endpoint  | method | queryParams        |
        | /api/llms | GET    | { status: ACTIVE } |
      Then 回應 HTTP 200, with table:
        | (empty) |
      And 回傳清單應為空陣列 []
      And 回傳清單總數應為 0

  Rule: 基礎設施異常時回傳明確失敗訊息 (Exception Handling)
    # Failure Rule - 當依賴服務不可用時，需明確告知使用者

    Example: 查詢時發生資料庫連線逾時
      # 測試目標：驗證系統對基礎設施異常的處理
      Given 資料庫連線狀態為 TIMEOUT
      When 執行 API "CheckUsableLLMs", call:
        | endpoint  | method |
        | /api/llms | GET    |
      Then 回應 HTTP 503, with error:
        | field   | value                                     | type   |
        | code    | SERVICE_UNAVAILABLE                       | string |
        | message | 服務暫時無法使用，請稍後再試              | string |
        | details | { reason: "Database connection timeout" } | object |

    Example: 查詢時發生未預期的系統錯誤
      # 測試目標：驗證系統對未預期錯誤的容錯處理
      Given 系統內部發生未處理異常 "NullPointerException"
      When 執行 API "CheckUsableLLMs", call:
        | endpoint  | method |
        | /api/llms | GET    |
      Then 回應 HTTP 500, with error:
        | field   | value                 | type   |
        | code    | INTERNAL_SERVER_ERROR | string |
        | message | 系統發生錯誤          | string |
      And 系統應記錄完整的錯誤堆疊到 audit log
      And 系統應發布事件 "SystemErrorOccurred"
