Feature: 綁定 Agent 與 RAG 知識庫
  # 讓 Agent 能夠檢索上傳的文件

  Rule: 綁定 Agent 與 RAG 知識庫 的核心邏輯
    # 定義 綁定 Agent 與 RAG 知識庫 的相關規則與行為

    Example: 選擇知識庫集合
      Given 系統中已有處理完成的 RAG 知識庫 "CompanyDocs"
      When 用戶在 Agent 配置中選擇該知識庫
      Then 系統應建立關聯
      And Agent 執行時應能檢索該知識庫的內容
