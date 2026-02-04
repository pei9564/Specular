#!/bin/bash

# Specular AI Backend 開發啟動腳本

echo "🚀 Starting Specular AI Backend..."

# 檢查 .env 文件
if [ ! -f .env ]; then
    echo "⚠️  .env file not found. Copying from .env.example..."
    cp .env.example .env
    echo "✅ Please update .env with your configuration"
fi

# 檢查 Python 版本
python_version=$(python --version 2>&1 | awk '{print $2}')
echo "🐍 Python version: $python_version"

# 安裝依賴（如果需要）
if [ "$1" == "--install" ]; then
    echo "📦 Installing dependencies..."
    pip install -r requirements.txt
fi

# 執行測試（如果需要）
if [ "$1" == "--test" ]; then
    echo "🧪 Running tests..."
    pytest
    exit 0
fi

# 啟動開發伺服器
echo "🌐 Starting development server on http://localhost:8000"
echo "📚 API docs available at http://localhost:8000/docs"
echo ""

uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
