# Specular AI Backend 開發啟動腳本 (Windows PowerShell)

Write-Host "🚀 Starting Specular AI Backend..." -ForegroundColor Green

# 檢查 .env 文件
if (-not (Test-Path .env)) {
    Write-Host "⚠️  .env file not found. Copying from .env.example..." -ForegroundColor Yellow
    Copy-Item .env.example .env
    Write-Host "✅ Please update .env with your configuration" -ForegroundColor Green
}

# 檢查 Python 版本
$pythonVersion = python --version
Write-Host "🐍 $pythonVersion" -ForegroundColor Cyan

# 處理參數
param(
    [switch]$Install,
    [switch]$Test
)

# 安裝依賴
if ($Install) {
    Write-Host "📦 Installing dependencies..." -ForegroundColor Cyan
    pip install -r requirements.txt
}

# 執行測試
if ($Test) {
    Write-Host "🧪 Running tests..." -ForegroundColor Cyan
    pytest
    exit 0
}

# 啟動開發伺服器
Write-Host "🌐 Starting development server on http://localhost:8000" -ForegroundColor Green
Write-Host "📚 API docs available at http://localhost:8000/docs" -ForegroundColor Cyan
Write-Host ""

uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
