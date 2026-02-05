Feature: 查詢 Token 使用量統計
  追蹤與分析系統的 LLM Token 消耗量，支援多維度報表

  Background:
    Given 系統已累積以下 Token 使用紀錄 (usage_logs):
      | id   | user_id  | agent_id  | model    | provider  | prompt_tokens | completion_tokens | total_tokens | created_at |
      | u-01 | user-001 | agent-001 | gpt-4    | openai    |           500 |               200 |          700 | 2024-02-01 |
      | u-02 | user-001 | agent-001 | gpt-4    | openai    |           300 |               100 |          400 | 2024-02-01 |
      | u-03 | user-002 | agent-002 | claude-3 | anthropic |          1000 |               500 |         1500 | 2024-02-02 |
    And 目前費率表為:
      | model    | prompt_price_1k | completion_price_1k |
      | gpt-4    |            0.03 |                0.06 |
      | claude-3 |           0.015 |               0.075 |
  # ============================================================
  # Rule: 用戶與 Agent 消耗統計
  # ============================================================

  Rule: 用戶可查詢自己與旗下 Agent 的 Token 消耗總量

    Example: 查詢特定 Agent 的總消耗
      Given 使用者 "user-001" 已登入
      When 查詢 "agent-001" 的 Token 統計，時間範圍 "2024-02-01" 至 "2024-02-02"
      Then 回傳統計結果:
        | total_prompt_tokens     |   800 |
        | total_completion_tokens |   300 |
        | total_tokens            |  1100 |
        | estimated_cost_usd      | 0.042 |

    Example: 查詢用戶個人的總消耗
      When 查詢 "user-001" 的所有 Agent 總和
      Then 回傳該用戶名下所有 Agent 的加總數據
  # ============================================================
  # Rule: 管理員全域報表
  # ============================================================

  Rule: 管理員可依模型供應商或模型類型查詢全系統消耗

    Example: 依 Provider 分組統計
      Given 使用者 "admin" 已登入
      When 查詢全系統 Token 統計，依 "provider" 分組
      Then 回傳結果:
        | provider  | request_count | total_tokens | cost_usd |
        | openai    |             2 |         1100 |    0.042 |
        | anthropic |             1 |         1500 |   0.0525 |

    Example: 依 Model 分組統計
      When 查詢全系統 Token 統計，依 "model" 分組
      Then 回傳結果包含 "gpt-4" 與 "claude-3" 的個別統計
  # ============================================================
  # Rule: 時間粒度分析
  # ============================================================

  Rule: 支援依日、週、月進行趨勢分析

    Example: 每日消耗趨勢圖
      When 查詢 "agent-001" 過去 7 天的每日消耗 (granularity=day)
      Then 回傳時間序列資料:
        | date       | tokens | cost  |
        | 2024-02-01 |   1100 | 0.042 |
        | 2024-02-02 |      0 | 0.000 |
  # ============================================================
  # Rule: 預算與配額警示
  # ============================================================

  Rule: 當 Token 消耗超過設定閾值時應標記警示

    Example: 超出預算警示
      Given "user-001" 設定每月預算為 5 USD
      When 當月累積成本達到 4.5 USD (90%)
      Then 系統應發送 "預算即將用盡" 通知給用戶
      And 在統計 API 回傳中標記 warning: true
