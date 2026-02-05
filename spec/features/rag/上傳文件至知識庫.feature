Feature: 上傳文件至知識庫
  # 支援多種格式文件上傳並進行 RAG 處理

  Rule: 上傳文件至知識庫 的核心邏輯
    # 定義 上傳文件至知識庫 的相關規則與行為

    Example: 上傳支援的文件格式
      When 用戶上傳 ".pdf", ".docx", ".md" 或 ".txt" 檔案
      Then 系統應接受上傳
      And 開始 "解析" -> "分塊" -> "向量化" -> "儲存" 的處理流程

    Example: 關聯至 Agent
      When 知識庫處理完成
      Then 該知識庫應可被選取並關聯至指定 Agent
