Feature: LLM 註冊與配置管理 (LLM Registry Management)

  Rule: 模型生命週期與存取權限控制
    # 允許管理員控制模型是否啟用 (Active/Deprecated) 以及可見範圍 (Public/Admin-Only)

    Example: 將內部微調模型設定為僅管理員可見
      Given Aggregate: LLM Registry 中存在模型 "internal-finetuned-model"
      And Status: "Draft" (草稿)
      And Access: "None"
      When Command: 執行 UpdateModelAccess，參數如下：
        | model_id     | internal-finetuned-model |
        | status       | Active                   |
        | access_level | Admin-Only               |
      Then Aggregate: LLM Registry 中的 "internal-finetuned-model" 狀態應更新為：
        | Status | Active     |
        | Access | Admin-Only |
      And Return: 成功訊息 "Model access updated"

    Example: 將模型發布為全員可用 (Public)
      Given Aggregate: LLM Registry 中存在模型 "gpt-4o"
      And Status: "Active"
      And Access: "Admin-Only"
      When Command: 執行 UpdateModelAccess，參數如下：
        | model_id     | gpt-4o |
        | access_level | Public |
      Then Aggregate: LLM Registry 中的 "gpt-4o" 權限應更新為 "Public"
      And Event: 系統應發布 Model_Published 事件

    Example: 下架舊版模型 (Deprecate)
      Given Aggregate: LLM Registry 中存在模型 "gpt-3.5-legacy"
      And Status: "Active"
      When Command: 執行 UpdateModelStatus，參數如下：
        | model_id | gpt-3.5-legacy |
        | status   | Deprecated     |
      Then Aggregate: "gpt-3.5-legacy" 的狀態應變更為 "Deprecated"
      And Check: 該模型不應再出現在一般使用者的查詢清單中

  Rule: 配置參數驗證
    # 確保輸入的狀態與權限參數符合系統定義

    Example: 嘗試設定無效的狀態值
      Given Context: 使用者為管理員
      When Command: 執行 UpdateModelStatus，參數如下：
        | model_id | gpt-4o      |
        | status   | SuperActive |
      Then Return: 系統應回傳 Error "Invalid Status Value"
      And Aggregate: 模型狀態不應被變更

  Rule: 模型棄用之運行時影響 (Deprecation Runtime Impact)
    # Deprecation Rule - 確保已棄用的模型直接導致運行時錯誤，而非靜默失敗或降級

    Example: 使用已棄用模型的 Agent 嘗試進行對話 (失敗)
      Given Aggregate: Agent "LegacyBot" 綁定模型 "gpt-3.5-legacy"
      And Aggregate: 模型 "gpt-3.5-legacy" 的狀態已被設為 "Deprecated"
      When Command: 使用者向 "LegacyBot" 發送訊息
      Then Return: 系統應回傳 Error "Model Deprecated"
      And Aggregate: 對話不應被處理

    Example: 使用已棄用模型的 Topic 嘗試進行對話 (失敗)
      Given Aggregate: Chat Topic (ID: topic-old) 明確指定使用 "gpt-3.5-legacy"
      And Aggregate: 模型 "gpt-3.5-legacy" 的狀態已被設為 "Deprecated"
      When Command: 使用者在 "topic-old" 發送訊息
      Then Return: 系統應回傳 Error "Model Deprecated"
      And Check: 系統提示使用者需手動更新 Topic 設定
