# Specular-AI
Mirroring intent into architecture, where specs become reality.

## 🚀 快速開始

### 環境需求

- Node.js 18+ 
- npm 或 yarn
- [Ollama](https://ollama.com/) (本地 LLM)

### 安裝步驟

#### 1. 安裝並啟動 Ollama

```bash
# 安裝 Ollama (Linux)
curl -fsSL https://ollama.com/install.sh | sh

# 下載模型
ollama pull llama3.1

# 確認 Ollama 服務運行中 (預設 http://localhost:11434)
ollama serve
```

#### 2. 設定前端

1. **進入前端目錄**
   ```bash
   cd frontend
   ```

2. **安裝依賴**
   ```bash
   npm install
   ```

3. **設定環境變數**
   ```bash
   cp .env.local.example .env.local
   ```
   編輯 `.env.local` 並填入必要的設定：
   - `OPENAI_API_KEY`: OpenAI API 金鑰（必填）
   - `NEXT_PUBLIC_API_URL`: 後端 API 網址（選填，預設 `http://localhost:8000`）

4. **啟動開發伺服器**
   ```bash
   npm run dev
   ```

5. **開啟瀏覽器**
   
   訪問 [http://localhost:3000](http://localhost:3000)

### 可用指令

| 指令 | 說明 |
|------|------|
| `npm run dev` | 啟動開發伺服器 |
| `npm run build` | 建置生產版本 |
| `npm run start` | 啟動生產伺服器 |
| `npm run lint` | 執行程式碼檢查 |
| `npm run e2e` | 執行 E2E 測試 |
| `npm run e2e:ui` | 開啟 E2E 測試 UI |

---

## 🛑 停止服務

### 停止 Next.js 開發伺服器
在運行 `npm run dev` 的終端機按下 `Ctrl + C`

### 停止 Ollama 服務
```bash
# 方法 1: 在 ollama serve 的終端機按 Ctrl + C

# 方法 2: 使用 systemctl（如果作為服務運行）
sudo systemctl stop ollama

# 方法 3: 強制終止
pkill ollama
```

---

## 🔄 下次重新啟動

已經安裝過的話，只需執行以下步驟：

```bash
# 1. 啟動 Ollama（開一個終端機）
ollama serve

# 2. 啟動前端（開另一個終端機）
cd frontend
npm run dev
```

然後開啟瀏覽器訪問 [http://localhost:3000](http://localhost:3000)

---

## ❓ 常見問題

### Ollama 啟動時顯示 "address already in use"

這表示 Ollama **已經在運行中**，你可以直接使用，不需要再執行 `ollama serve`。

```bash
# 確認 Ollama 運行狀態
lsof -i :11434

# 如果需要重啟
pkill ollama
ollama serve
```

### 確認 Ollama 是否正常運行

```bash
curl http://localhost:11434/api/tags
```

