Feature: LLM 註冊與配置管理 (LLM Registry Management)

  Rule: 模型生命週期與存取權限控制
    # 允許管理員控制模型是否啟用 (Active/Inactive) 以及可見範圍 (Public/Admin-Only)

    Example: 將模型從停用改為啟用
      Given LLM Registry 中存在模型 "internal-finetuned-model"
      And Status: "Inactive" (停用)
      And Access: "Admin-Only"
      When 執行 UpdateModelAccess，參數如下：
        | model_id | internal-finetuned-model |
        | status   | Active                   |
      Then LLM Registry 中的 "internal-finetuned-model" 狀態應更新為 "Active"
      And Return: 成功訊息 "Model access updated"

    Example: 將模型發布為全員可用 (Public)
      Given LLM Registry 中存在模型 "gpt-4o"
      And Status: "Active"
      And Access: "Admin-Only"
      When 執行 UpdateModelAccess，參數如下：
        | model_id     | gpt-4o |
        | access_level | Public |
      Then LLM Registry 中的 "gpt-4o" 權限應更新為 "Public"
      And 系統應發布 Model_Published 事件

    Example: 停用舊版模型 (Deactivate)
      Given LLM Registry 中存在模型 "gpt-3.5-legacy"
      And Status: "Active"
      When 執行 UpdateModelStatus，參數如下：
        | model_id | gpt-3.5-legacy |
        | status   | Inactive       |
      Then "gpt-3.5-legacy" 的狀態應變更為 "Inactive"
      And 該模型不應再出現在一般使用者的查詢清單中

  Rule: 配置參數驗證
    # 確保輸入的狀態與權限參數符合系統定義

    Example: 嘗試設定無效的狀態值
      Given 使用者為管理員
      When 執行 UpdateModelStatus，參數如下：
        | model_id | gpt-4o      |
        | status   | SuperActive |
      Then 回傳 Error "Invalid Status Value"
      And 模型狀態不應被變更

  Rule: 支援多種後端供應商配置 (Provider Configuration)
    # Configuration Rules - 針對 OpenAI Compatible, vLLM, Ollama 提供差異化設定

    Example: 註冊 vLLM 自架服務 (OpenAI Compatible Interface)
      Given 企業內部架設了 vLLM server
      When 執行 RegisterModel，參數如下：
        | model_id     | internal-llama3-70b                                              |
        | provider     | vllm                                                             |
        | capabilities | ["tool_use", "json_mode"]                                        |
        | config       | { "base_url": "http://10.0.0.5:8000/v1", "max_model_len": 4096 } |
      Then 建立一個 "vllm" 類型的 LLM
      And 系統應嘗試發送測試請求並確認成功

    Example: 嘗試使用不支援的 Capability 值 (驗證失敗)
      When 執行 RegisterModel，參數如下：
        | model_id     | test-model      |
        | capabilities | ["fly_to_moon"] |
      Then 回傳 Error "Invalid Capability"
      And 合法值僅限 "tool_use", "vision", "json_mode", "streaming"

  Rule: 模型停用之運行時影響 (Inactive Runtime Impact)
    # Inactive Rule - 確保已停用的模型直接導致運行時錯誤

    Example: 使用已停用模型的 Topic 嘗試進行對話 (失敗)
      Given Chat Topic (ID: topic-old) 明確指定使用 "gpt-3.5-legacy"
      And 模型 "gpt-3.5-legacy" 的狀態已被設為 "Inactive"
      When 使用者在 "topic-old" 發送訊息
      Then 回傳 Error "Model Inactive"
      And 系統提示使用者需手動更新 Topic 設定
