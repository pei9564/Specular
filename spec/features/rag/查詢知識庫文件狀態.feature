Feature: 查詢知識庫文件狀態
  查詢知識庫中文件的處理進度 (RAG Pipeline Status) 與詳細資訊

  Background:
    Given 系統中存在知識庫 "kb-001" (Owner: user-001):
      | id     | name        | status |
      | kb-001 | CompanyDocs | ready  |
    And 知識庫 "kb-001" 中包含以下文件:
      | id      | filename    | status     | processing_step | error_message | uploaded_at         | chunk_count |
      | doc-001 | report.pdf  | ready      | completed       | null          | 2024-02-01 10:00:00 |          50 |
      | doc-002 | manual.docx | processing | embedding       | null          | 2024-02-05 12:00:00 |          20 |
      | doc-003 | error.txt   | error      | parsing         | file corrupt  | 2024-02-05 12:05:00 |           0 |
      | doc-004 | queued.md   | pending    | null            | null          | 2024-02-05 12:10:00 |           0 |
    And 使用者 "user-001" 已登入
  # ============================================================
  # Rule: 查詢知識庫文件列表
  # ============================================================

  Rule: 用戶可以分頁查詢特定知識庫內的所有文件列表

    Example: 成功 - 查詢文件列表
      When 使用者查詢知識庫 "kb-001" 的文件列表:
        | page      |  1 |
        | page_size | 10 |
      Then 請求應成功，回傳狀態碼 200
      And 回傳結果應包含 4 筆文件資料
      And 每筆文件應包含摘要資訊:
        | field       |
        | id          |
        | filename    |
        | status      |
        | file_size   |
        | uploaded_at |

    Example: 成功 - 依狀態篩選文件
      When 使用者查詢知識庫 "kb-001" 的文件列表:
        | status | error |
      Then 回傳結果應僅包含 1 筆資料
      And 包含文件 "error.txt"

    Example: 成功 - 關鍵字搜尋文件
      When 使用者查詢知識庫 "kb-001" 的文件列表:
        | search | report |
      Then 回傳結果應包含文件 "report.pdf"
  # ============================================================
  # Rule: 查詢單一文件詳細狀態
  # ============================================================

  Rule: 用戶可以查詢單一文件的詳細 RAG 處理進度與元數據

    Example: 成功 - 查詢已完成的文件 (Ready)
      When 使用者查詢文件 "doc-001" 的詳情
      Then 回傳狀態應為 "ready"
      And 應顯示處理統計:
        | field              | value |
        | chunk_count        |    50 |
        | processing_time_ms |  1200 |

    Example: 成功 - 查詢處理中的文件 (Processing)
      When 使用者查詢文件 "doc-002" 的詳情
      Then 回傳狀態應為 "processing"
      And 應顯示目前步驟為 "embedding"
      And 應顯示進度百分比 (optional)

    Example: 成功 - 查詢失敗的文件 (Error)
      When 使用者查詢文件 "doc-003" 的詳情
      Then 回傳狀態應為 "error"
      And 應顯示錯誤原因:
        | field         | value        |
        | failed_step   | parsing      |
        | error_message | file corrupt |
  # ============================================================
  # Rule: 查詢知識庫整體狀態
  # ============================================================

  Rule: 知識庫層級應提供聚合的狀態摘要

    Example: 查詢知識庫摘要
      When 使用者查詢知識庫 "kb-001" 的資訊
      Then 回傳結果應包含文件統計:
        | field           | value                                           |
        | total_documents |                                               4 |
        | status_counts   | {ready: 1, processing: 1, error: 1, pending: 1} |
        | total_chunks    |                                              70 |
  # ============================================================
  # Rule: 權限控制
  # ============================================================

  Rule: 僅知識庫擁有者可查詢文件狀態

    Example: 失敗 - 查詢他人知識庫
      Given 使用者 "user-002" (非擁有者) 已登入
      When 使用者查詢知識庫 "kb-001" 的文件列表
      Then 請求應失敗，回傳狀態碼 403
      And 錯誤訊息應為 "Permission denied"
