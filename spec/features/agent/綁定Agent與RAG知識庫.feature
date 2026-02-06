Feature: 綁定 Agent 與 RAG 知識庫
  讓 Agent 能夠檢索上傳的文件，提供知識增強的回答

  Background:
    Given 系統中存在以下 Agent:
      | id        | name    | owner_id | status |
      | agent-001 | MathBot | user-001 | active |
      | agent-002 | CodeBot | user-002 | active |
    And 系統中存在以下 RAG 知識庫:
      | id      | name         | status     | owner_id | visibility | doc_count | chunk_count | embedding_model  |
      | rag-001 | CompanyDocs  | ready      | user-001 | public     |        50 |        2500 | text-embedding-3 |
      | rag-002 | TechManual   | ready      | user-001 | private    |        20 |         800 | text-embedding-3 |
      | rag-003 | LegalDocs    | ready      | user-002 | public     |       100 |        5000 | text-embedding-3 |
      | rag-004 | Processing   | processing | user-001 | public     |        10 |           0 | text-embedding-3 |
      | rag-005 | FailedImport | error      | user-001 | public     |         5 |           0 | text-embedding-3 |
      | rag-006 | PrivateData  | ready      | user-002 | private    |        30 |        1500 | text-embedding-3 |
    And 使用者 "user-001" 已登入
  # ============================================================
  # Rule: 建立綁定關係
  # ============================================================

  # [NOTE] 綁定 API 在 spec.md 5.1 中是透過 PUT /api/v1/agents/{id} 更新 rag_collection_id 欄位實現
  Rule: 使用者可以將 RAG 知識庫綁定到自己的 Agent

    Example: 成功 - 綁定單一知識庫
      Given Agent "agent-001" 尚未綁定任何 RAG 知識庫
      And agent_rag_bindings 表中無 agent_id 為 "agent-001" 的記錄
      # API: PUT /api/v1/agents/{id}
      When 使用者 "user-001" 發送 PUT 請求至 "/api/v1/agents/agent-001":
        | rag_collection_id | rag-001 |
      Then 請求應成功，回傳狀態碼 201
      And agent_rag_bindings 表應新增一筆記錄:
        | agent_id  | rag_id  | created_at | retrieval_config               |
        | agent-001 | rag-001 | (當前時間) | {"top_k": 5, "threshold": 0.7} |
      And Agent "agent-001" 執行時應能檢索 CompanyDocs 的內容

    Example: 成功 - 綁定多個知識庫
      When 使用者 "user-001" 提交綁定請求:
        | agent_id | agent-001       |
        | rag_ids  | rag-001,rag-002 |
      Then 請求應成功
      And agent_rag_bindings 表應新增兩筆記錄
      And Agent 檢索時應合併多個知識庫的結果

    Example: 成功 - 綁定公開的知識庫（非自己擁有）
      # API: PUT /api/v1/agents/{id}
      When 使用者 "user-001" 發送 PUT 請求至 "/api/v1/agents/agent-001":
        | rag_collection_id | rag-003 |
      Then 請求應成功
      And Agent "agent-001" 應能檢索 LegalDocs 的內容

    Example: 失敗 - 無法綁定 private 知識庫（非擁有者）
      # API: PUT /api/v1/agents/{id}
      When 使用者 "user-001" 發送 PUT 請求至 "/api/v1/agents/agent-001":
        | rag_collection_id | rag-006 |
      Then 請求應失敗，回傳狀態碼 403
      And 錯誤訊息應為 "RAG knowledge base 'PrivateData' is private and not accessible"

    Example: 失敗 - 無法綁定尚在處理中的知識庫
      # API: PUT /api/v1/agents/{id}
      When 使用者 "user-001" 發送 PUT 請求至 "/api/v1/agents/agent-001":
        | rag_collection_id | rag-004 |
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "RAG knowledge base 'Processing' is not ready (status: processing)"

    Example: 失敗 - 無法綁定處理失敗的知識庫
      # API: PUT /api/v1/agents/{id}
      When 使用者 "user-001" 發送 PUT 請求至 "/api/v1/agents/agent-001":
        | rag_collection_id | rag-005 |
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "RAG knowledge base 'FailedImport' is not ready (status: error)"

    Example: 失敗 - 知識庫不存在
      # API: PUT /api/v1/agents/{id}
      When 使用者 "user-001" 發送 PUT 請求至 "/api/v1/agents/agent-001":
        | rag_collection_id | non-existent-rag |
      Then 請求應失敗，回傳狀態碼 404
      And 錯誤訊息應為 "RAG knowledge base 'non-existent-rag' not found"

    Example: 失敗 - 非 Agent 擁有者無法綁定
      # API: PUT /api/v1/agents/{id}
      When 使用者 "user-001" 發送 PUT 請求至 "/api/v1/agents/agent-002":
        | rag_collection_id | rag-001 |
      Then 請求應失敗，回傳狀態碼 403
      And 錯誤訊息應為 "You do not have permission to modify this agent"
  # ============================================================
  # Rule: 自訂檢索配置
  # ============================================================

  Rule: 綁定時可以自訂 RAG 檢索參數

    Example: 成功 - 自訂 top_k 參數
      When 使用者 "user-001" 提交綁定請求:
        | agent_id               | agent-001 |
        | rag_ids                | rag-001   |
        | retrieval_config.top_k |        10 |
      Then 請求應成功
      And agent_rag_bindings 記錄的 retrieval_config 應為:
        | field     | value |
        | top_k     |    10 |
        | threshold |   0.7 |

    Example: 成功 - 自訂相似度閾值
      When 使用者 "user-001" 提交綁定請求:
        | agent_id                   | agent-001 |
        | rag_ids                    | rag-001   |
        | retrieval_config.threshold |      0.85 |
      Then 請求應成功
      And Agent 檢索時應過濾掉相似度低於 0.85 的結果

    Example: 成功 - 啟用 reranking
      When 使用者 "user-001" 提交綁定請求:
        | agent_id                      | agent-001        |
        | rag_ids                       | rag-001          |
        | retrieval_config.use_rerank   | true             |
        | retrieval_config.rerank_model | cohere-rerank-v3 |
      Then 請求應成功
      And Agent 檢索時應使用 reranking 模型重新排序結果

    Example: 失敗 - top_k 超出範圍
      When 使用者 "user-001" 提交綁定請求:
        | agent_id               | agent-001 |
        | rag_ids                | rag-001   |
        | retrieval_config.top_k |       100 |
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "top_k must be between 1 and 50"

    Example: 失敗 - threshold 超出範圍
      When 使用者 "user-001" 提交綁定請求:
        | agent_id                   | agent-001 |
        | rag_ids                    | rag-001   |
        | retrieval_config.threshold |       1.5 |
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "threshold must be between 0 and 1"
  # ============================================================
  # Rule: 解除綁定
  # ============================================================

  Rule: 使用者可以解除 Agent 與 RAG 知識庫的綁定

    Example: 成功 - 解除單一綁定
      Given Agent "agent-001" 已綁定 RAG 知識庫:
        | rag_id  |
        | rag-001 |
        | rag-002 |
      When 使用者 "user-001" 提交解除綁定請求:
        | agent_id | agent-001 |
        | rag_ids  | rag-001   |
      Then 請求應成功，回傳狀態碼 200
      And agent_rag_bindings 表應刪除 agent-001 與 rag-001 的記錄
      And Agent "agent-001" 應無法再檢索 CompanyDocs 的內容

    Example: 成功 - 解除所有綁定
      Given Agent "agent-001" 已綁定 3 個 RAG 知識庫
      When 使用者 "user-001" 提交解除綁定請求:
        | agent_id   | agent-001 |
        | unbind_all | true      |
      Then 請求應成功
      And agent_rag_bindings 表中 agent_id 為 "agent-001" 的記錄應全部刪除
  # ============================================================
  # Rule: 查詢綁定狀態
  # ============================================================

  Rule: 可以查詢 Agent 目前綁定的 RAG 知識庫

    Example: 成功 - 查詢 Agent 的 RAG 綁定列表
      Given Agent "agent-001" 已綁定 RAG 知識庫:
        | rag_id  | bound_at            | retrieval_config                |
        | rag-001 | 2024-01-01 10:00:00 | {"top_k": 5, "threshold": 0.7}  |
        | rag-002 | 2024-01-02 15:30:00 | {"top_k": 10, "threshold": 0.8} |
      # API: GET /api/v1/agents/{id}
      When 使用者 "user-001" 發送 GET 請求至 "/api/v1/agents/agent-001"
      Then 請求應成功
      And 回傳結果應包含:
        | rag_id  | name        | doc_count | chunk_count | top_k | threshold | bound_at            |
        | rag-001 | CompanyDocs |        50 |        2500 |     5 |       0.7 | 2024-01-01 10:00:00 |
        | rag-002 | TechManual  |        20 |         800 |    10 |       0.8 | 2024-01-02 15:30:00 |
  # ============================================================
  # Rule: 更新檢索配置
  # ============================================================

  Rule: 可以更新已綁定知識庫的檢索配置

    Example: 成功 - 更新 top_k 參數
      Given Agent "agent-001" 已綁定 RAG 知識庫 "rag-001"，top_k 為 5
      When 使用者 "user-001" 提交更新綁定請求:
        | agent_id               | agent-001 |
        | rag_id                 | rag-001   |
        | retrieval_config.top_k |        15 |
      Then 請求應成功
      And agent_rag_bindings 記錄應更新:
        | field                  | old_value | new_value |
        | retrieval_config.top_k |         5 |        15 |
  # ============================================================
  # Rule: 綁定限制
  # ============================================================

  Rule: 系統對綁定數量有上限限制

    Example: 失敗 - 超過 RAG 綁定上限
      Given Agent "agent-001" 已綁定 5 個 RAG 知識庫（達到上限）
      When 使用者 "user-001" 提交綁定請求:
        | agent_id | agent-001  |
        | rag_ids  | new-rag-id |
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "Agent has reached the maximum RAG binding limit (5)"
  # ============================================================
  # Rule: Embedding 模型相容性
  # ============================================================

  Rule: 綁定的知識庫必須使用相容的 embedding 模型

    Example: 警告 - 不同 embedding 模型的知識庫
      Given 系統中新增 RAG 知識庫:
        | id      | name    | embedding_model    |
        | rag-007 | OldDocs | text-embedding-ada |
      And Agent "agent-001" 已綁定使用 "text-embedding-3" 的知識庫
      When 使用者 "user-001" 提交綁定請求:
        | agent_id | agent-001 |
        | rag_ids  | rag-007   |
      Then 請求應成功，但回傳警告:
        | warning | Different embedding models detected                                             |
        | details | Mixing 'text-embedding-3' and 'text-embedding-ada' may affect retrieval quality |
