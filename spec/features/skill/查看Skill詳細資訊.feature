Feature: 查看 Skill 詳細資訊
  # 提供 Skill 的完整資訊展示與管理

  Rule: 查看 Skill 詳細資訊 的核心邏輯
    # 定義 查看 Skill 詳細資訊 的相關規則與行為

    Example: 查看 Skill 詳情
      When 用戶請求查看特定 Skill 的詳情
      Then 系統應回傳 Config 資訊 (Meta data)
      And 渲染 "SKILL.md" 的內容於 Instructions Tab
      And 列出 Skill 資料夾內的文件結構

    Example: 下載 Skill
      When 用戶請求下載 Skill
      Then 系統應將 Skill 打包為 ZIP 並提供下載
