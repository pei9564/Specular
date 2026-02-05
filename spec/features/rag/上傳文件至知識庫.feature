Feature: 上傳文件至知識庫
  支援多種格式文件上傳並進行 RAG 處理

  Background:
    Given 系統支援以下文件格式:
      | extension | mime_type                                                               | max_size_mb |
      | .pdf      | application/pdf                                                         |          50 |
      | .docx     | application/vnd.openxmlformats-officedocument.wordprocessingml.document |          30 |
      | .doc      | application/msword                                                      |          30 |
      | .txt      | text/plain                                                              |          10 |
      | .md       | text/markdown                                                           |          10 |
      | .csv      | text/csv                                                                |          20 |
      | .xlsx     | application/vnd.openxmlformats-officedocument.spreadsheetml.sheet       |          30 |
    And 系統中存在以下知識庫:
      | id     | name        | owner_id | status     | embedding_model  |
      | kb-001 | CompanyDocs | user-001 | ready      | text-embedding-3 |
      | kb-002 | TechManual  | user-001 | ready      | text-embedding-3 |
      | kb-003 | Processing  | user-001 | processing | text-embedding-3 |
    And 使用者 "user-001" 已登入
  # ============================================================
  # Rule: 創建知識庫
  # ============================================================

  Rule: 用戶可以創建新的知識庫

    Example: 成功 - 創建新知識庫
      When 使用者發送 POST 請求至 "/api/knowledge-bases":
        | field           | value                 |
        | name            | Product Documentation |
        | description     | 產品相關文件          |
        | embedding_model | text-embedding-3      |
        | visibility      | private               |
      Then 請求應成功，回傳狀態碼 201
      And knowledge_bases 表應新增一筆記錄:
        | field           | value                 |
        | id              | (自動生成 UUID)       |
        | name            | Product Documentation |
        | description     | 產品相關文件          |
        | owner_id        | user-001              |
        | embedding_model | text-embedding-3      |
        | visibility      | private               |
        | status          | empty                 |
        | doc_count       |                     0 |
        | chunk_count     |                     0 |
        | created_at      | (當前時間)            |

    Example: 失敗 - 名稱已存在
      Given knowledge_bases 表已存在 name 為 "CompanyDocs" 且 owner_id 為 "user-001"
      When 使用者發送 POST 請求至 "/api/knowledge-bases":
        | name | CompanyDocs |
      Then 請求應失敗，回傳狀態碼 409
      And 錯誤訊息應為 "A knowledge base named 'CompanyDocs' already exists"
  # ============================================================
  # Rule: 上傳文件
  # ============================================================

  Rule: 用戶可以上傳支援格式的文件至知識庫

    Example: 成功 - 上傳 PDF 文件
      When 使用者發送 POST 請求至 "/api/knowledge-bases/kb-001/documents":
        | file     | (report.pdf binary, 5MB) |
        | filename | report.pdf               |
      Then 請求應成功，回傳狀態碼 202 Accepted
      And documents 表應新增一筆記錄:
        | field             | value           |
        | id                | (自動生成 UUID) |
        | knowledge_base_id | kb-001          |
        | filename          | report.pdf      |
        | original_filename | report.pdf      |
        | mime_type         | application/pdf |
        | file_size         |         5242880 |
        | status            | pending         |
        | uploaded_by       | user-001        |
        | uploaded_at       | (當前時間)      |
      And 文件應儲存至 "/storage/kb-001/documents/{doc_id}/report.pdf"
      And 系統應將文件排入處理佇列
      And 回傳結果應包含:
        | field       | value                          |
        | document_id | (新文件 UUID)                  |
        | status      | pending                        |
        | message     | Document queued for processing |

    Example: 成功 - 上傳 DOCX 文件
      When 使用者上傳 "manual.docx" 至知識庫 "kb-001"
      Then 請求應成功
      And documents 記錄的 mime_type 應為 "application/vnd.openxmlformats-officedocument.wordprocessingml.document"

    Example: 成功 - 上傳 Markdown 文件
      When 使用者上傳 "readme.md" 至知識庫 "kb-001"
      Then 請求應成功
      And documents 記錄的 mime_type 應為 "text/markdown"

    Example: 成功 - 上傳純文字文件
      When 使用者上傳 "notes.txt" 至知識庫 "kb-001"
      Then 請求應成功

    Example: 成功 - 批次上傳多個文件
      When 使用者發送 POST 請求至 "/api/knowledge-bases/kb-001/documents/batch":
        | files | [(doc1.pdf), (doc2.docx), (doc3.md)] |
      Then 請求應成功，回傳狀態碼 202
      And documents 表應新增 3 筆記錄
      And 回傳結果應包含:
        | uploaded_count |                             3 |
        | documents      | [{id, filename, status}, ...] |
  # ============================================================
  # Rule: 文件格式驗證
  # ============================================================

  Rule: 系統應驗證上傳文件的格式和大小

    Example: 失敗 - 不支援的文件格式
      When 使用者上傳 "image.jpg" 至知識庫 "kb-001"
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "Unsupported file format: .jpg. Supported: .pdf, .docx, .doc, .txt, .md, .csv, .xlsx"

    Example: 失敗 - 文件過大
      When 使用者上傳 60MB 的 PDF 文件至知識庫
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "File size exceeds maximum limit for PDF (50MB)"

    Example: 失敗 - 文件內容損壞
      When 使用者上傳一個損壞的 PDF 文件
      Then 請求應成功（上傳本身）
      And 文件處理時應標記為 error
      And documents 記錄應更新:
        | status        | error                                  |
        | error_message | Failed to parse PDF: file is corrupted |

    Example: 失敗 - 空文件
      When 使用者上傳 0 bytes 的文件
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "Empty file is not allowed"
  # ============================================================
  # Rule: 文件處理流程
  # ============================================================

  Rule: 上傳的文件應經過完整的 RAG 處理流程

    Example: 處理流程 - 解析 → 分塊 → 向量化 → 儲存
      Given 使用者上傳文件 "report.pdf"
      When 系統開始處理文件
      Then 處理流程應依序執行:
        | step | name      | description                |
        |    1 | parsing   | 解析文件內容，提取文字     |
        |    2 | chunking  | 將文字分割成適當大小的區塊 |
        |    3 | embedding | 對每個區塊生成向量嵌入     |
        |    4 | indexing  | 將向量儲存至向量資料庫     |
      And documents 表的 status 應依序更新:
        | status     | processing_step |
        | processing | parsing         |
        | processing | chunking        |
        | processing | embedding       |
        | processing | indexing        |
        | ready      | completed       |

    Example: 處理完成 - 更新知識庫統計
      Given 文件 "report.pdf" 處理完成，產生 50 個 chunks
      Then documents 表應更新:
        | field        | value      |
        | status       | ready      |
        | chunk_count  |         50 |
        | processed_at | (當前時間) |
      And knowledge_bases 表中 kb-001 應更新:
        | field       | old_value | new_value |
        | doc_count   |         5 |         6 |
        | chunk_count |       200 |       250 |
        | status      | ready     | ready     |

    Example: 處理失敗 - 記錄錯誤
      Given 文件處理在 embedding 階段失敗
      Then documents 表應更新:
        | field           | value                      |
        | status          | error                      |
        | processing_step | embedding                  |
        | error_message   | Embedding API rate limited |
        | retry_count     |                          1 |
      And 系統應在 5 分鐘後自動重試
  # ============================================================
  # Rule: 分塊策略
  # ============================================================

  Rule: 支援不同的文件分塊策略

    Example: 預設分塊設定
      When 使用者上傳文件不指定分塊設定
      Then 系統應使用預設設定:
        | field         | value |
        | chunk_size    |  1000 |
        | chunk_overlap |   200 |
        | separator     | \n\n  |

    Example: 自訂分塊設定
      When 使用者發送 POST 請求至 "/api/knowledge-bases/kb-001/documents":
        | file          | (report.pdf) |
        | chunk_size    |          500 |
        | chunk_overlap |          100 |
      Then 文件應使用自訂設定進行分塊

    Example: 智慧分塊（依文件結構）
      Given 上傳的 PDF 包含章節標題
      When 使用者指定 chunking_strategy 為 "semantic"
      Then 系統應優先在章節邊界進行分塊
      And 保持語義完整性
  # ============================================================
  # Rule: 權限控制
  # ============================================================

  Rule: 用戶只能上傳文件到自己的知識庫

    Example: 失敗 - 上傳到他人的知識庫
      Given 知識庫 "kb-other" 的 owner_id 為 "user-002"
      When 使用者 "user-001" 上傳文件到 "kb-other"
      Then 請求應失敗，回傳狀態碼 403
      And 錯誤訊息應為 "You do not have permission to upload to this knowledge base"

    Example: 失敗 - 知識庫不存在
      When 使用者上傳文件到 "non-existent-kb"
      Then 請求應失敗，回傳狀態碼 404
      And 錯誤訊息應為 "Knowledge base not found"

    Example: 失敗 - 知識庫正在處理中
      Given 知識庫 "kb-003" 的 status 為 "processing"
      When 使用者上傳文件到 "kb-003"
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "Knowledge base is currently processing. Please wait."
  # ============================================================
  # Rule: 文件配額
  # ============================================================

  Rule: 知識庫有文件數量和儲存空間限制

    Example: 失敗 - 超過文件數量限制
      Given 知識庫 "kb-001" 已有 100 個文件（達到上限）
      When 使用者上傳新文件
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "Document limit reached (100). Please delete some documents first."

    Example: 失敗 - 超過儲存空間限制
      Given 知識庫 "kb-001" 已使用 1GB 儲存空間（達到上限）
      When 使用者上傳 50MB 的新文件
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "Storage limit reached (1GB). Please upgrade or delete some documents."
  # ============================================================
  # Rule: 重複文件處理
  # ============================================================

  Rule: 系統應檢測並處理重複文件

    Example: 警告 - 相同檔名文件已存在
      Given 知識庫 "kb-001" 已有文件 "report.pdf"
      When 使用者再次上傳 "report.pdf"
      Then 請求應成功，回傳狀態碼 202
      And 回傳應包含警告:
        | warning | A file with the same name already exists. It will be replaced. |
      And 舊文件應標記為 replaced
      And 新文件應開始處理

    Example: 跳過 - 內容完全相同
      Given 知識庫 "kb-001" 已有文件，hash 為 "abc123"
      When 使用者上傳內容 hash 相同的文件:
        | skip_duplicates | true |
      Then 請求應成功
      And 回傳應包含:
        | skipped | true                          |
        | reason  | Identical file already exists |
      And documents 表應無新增記錄
  # ============================================================
  # Rule: 審計日誌
  # ============================================================

  Rule: 文件上傳應記錄審計日誌

    Example: 記錄上傳操作
      When 使用者上傳文件
      Then audit_logs 表應新增一筆記錄:
        | field       | value                                                                   |
        | action      | document.upload                                                         |
        | actor_id    | user-001                                                                |
        | target_type | document                                                                |
        | target_id   | (新文件 ID)                                                             |
        | details     | {"filename": "report.pdf", "size": 5242880, "knowledge_base": "kb-001"} |
        | created_at  | (當前時間)                                                              |
