Feature: 查詢 Agent 列表 (List Agents)
  # 查詢系統中已建立的 Agent 清單，包含狀態與基礎配置摘要

  Rule: 提供分頁與關鍵字搜尋
    # 支援大量 Agent 的檢索

    Example: 搜尋特定名稱的 Agent
      Given 系統中有 "MathBot", "CodeBot", "ChatBot"
      When 使用者搜尋關鍵字 "Code"
      Then 列表應僅顯示 "CodeBot"

  Rule: 顯示 Agent 的配置摘要
    # 讓使用者快速了解 Agent 能力

    Example: 列表項目內容
      When 使用者查看 Agent 列表
      Then 每個項目應顯示:
        | Field        | Example           |
        | Name         | MathGuru          |
        | Model        | gpt-4o (OpenAI)   |
        | Mode         | Chat              |
        | Capabilities | Skills: 2, MCP: 1 |
        | Status       | Active            |

  Rule: 依據權限過濾可見的 Agent
    # Access Control

    Example: 一般使用者僅能看見公開或自己的 Agent
      Given Admin 建立了 "SystemAgent" (Private)
      And User 建立了 "MyAgent"
      When User 查詢列表
      Then 應看見 "MyAgent"
      But 不應看見 "SystemAgent"

