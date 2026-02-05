Feature: 上傳 Skill 包
  # 使用者上傳自定義 Python 工具包

  Rule: 上傳 Skill 包 的核心邏輯
    # 定義 上傳 Skill 包 的相關規則與行為

    Example: 上傳合法的 Skill ZIP
      When 用戶上傳包含 "SKILL.md", "__init__.py", "functions.py" 的 ZIP 檔
      Then 系統應解壓縮並驗證檔案結構
      And 系統應解析 "functions.py" 中的工具函數簽名
      And 生成對應的 JSON Schema
      And 將 Skill 儲存至 Skill 倉庫

    Example: 上傳結構錯誤的 Skill
      When 用戶上傳缺少 "SKILL.md" 的 ZIP 檔
      Then 系統應拒絕上傳並回傳錯誤 "Missing SKILL.md"
