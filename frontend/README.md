# Specular AI Frontend

AI Agent 配置與管理平台前端應用程式。

## 技術棧

- **框架**: Next.js 14 (App Router)
- **語言**: TypeScript
- **樣式**: Tailwind CSS
- **AI 整合**: CopilotKit (AG-UI Protocol)
- **測試**: Playwright + playwright-bdd

## 快速開始

### 1. 安裝依賴

```bash
npm install
```

### 2. 設定環境變數

```bash
cp .env.local.example .env.local
# 編輯 .env.local 設定 OPENAI_API_KEY
```

### 3. 啟動開發伺服器

```bash
npm run dev
```

開啟 [http://localhost:3000](http://localhost:3000)

## 頁面結構

| 路徑 | 功能 |
|------|------|
| `/` | 首頁 Dashboard |
| `/topics` | 對話主題管理 |
| `/topics/[id]` | Chat 對話介面 (SSE 串流) |
| `/copilot` | CopilotKit Chat (AG-UI) |
| `/history` | 歷史查詢 |
| `/llms` | LLM 管理 |
| `/agents` | Agent 管理 |
| `/tools` | Tool 管理 |

## BDD 測試

```bash
npm run bddgen   # 生成測試檔案
npm run e2e      # 執行測試
npm run e2e:ui   # Playwright UI 模式
```

## CopilotKit 整合

本專案整合 CopilotKit AG-UI 協議，支援：

- **Chat UI**: 內建對話介面元件
- **Human-in-the-Loop**: Tool 執行確認流程
- **SSE 串流**: 即時 AI 回應

詳見 `/copilot` 頁面的實作範例。
