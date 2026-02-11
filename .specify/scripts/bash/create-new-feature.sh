#!/usr/bin/env bash

# .specify/scripts/bash/create-new-feature.sh
# Version: 2.0 (Gherkin + Domain Support)

set -e

JSON_MODE=false
SHORT_NAME=""
BRANCH_NUMBER=""
DOMAIN="Uncategorized" # Default domain
ARGS=()
i=1

while [ $i -le $# ]; do
    arg="${!i}"
    case "$arg" in
        --json) 
            JSON_MODE=true 
            ;;
        --short-name)
            i=$((i + 1))
            SHORT_NAME="${!i}"
            ;;
        --number)
            i=$((i + 1))
            BRANCH_NUMBER="${!i}"
            ;;
        --help|-h) 
            echo "Usage: $0 [--json] [--short-name <domain/name>] [--number N] <description>"
            echo "Example: $0 'User login' --short-name 'Identity/Login'"
            exit 0
            ;;
        *) 
            ARGS+=("$arg") 
            ;;
    esac
    i=$((i + 1))
done

FEATURE_DESCRIPTION="${ARGS[*]}"
if [ -z "$FEATURE_DESCRIPTION" ]; then
    echo "Error: Feature description required." >&2
    exit 1
fi

# ==============================================================================
# 1. 處理 Domain 與 Feature Name (核心修改)
# ==============================================================================

# 如果 short-name 包含 "/" (例如 Identity/Login)，則拆分為 Domain 和 Name
if [[ "$SHORT_NAME" == *"/"* ]]; then
    DOMAIN=$(echo "$SHORT_NAME" | cut -d'/' -f1)
    FEATURE_SLUG=$(echo "$SHORT_NAME" | cut -d'/' -f2)
else
    # 如果沒有指定 Domain，嘗試從 Description 簡單推導 (或是用 Uncategorized)
    FEATURE_SLUG=$(echo "$SHORT_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g')
    if [ -z "$FEATURE_SLUG" ]; then
         FEATURE_SLUG=$(echo "$FEATURE_DESCRIPTION" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | cut -c1-30)
    fi
fi

# ==============================================================================
# 2. 自動編號邏輯 (保留原版精華)
# ==============================================================================

# 為了不破壞原有的編號邏輯，我們還是去檢查 git branch
# 但我們不再依賴 `specs/` 目錄下的編號，因為我們現在是 `specs/features/Domain/...`
# 這裡簡化為只檢查 Git Branch 的最大編號

get_highest_from_branches() {
    local highest=0
    branches=$(git branch -a 2>/dev/null || echo "")
    if [ -n "$branches" ]; then
        while IFS= read -r branch; do
            clean_branch=$(echo "$branch" | sed 's/^[* ]*//; s|^remotes/[^/]*/||')
            if echo "$clean_branch" | grep -q '^[0-9]\{3\}-'; then
                number=$(echo "$clean_branch" | grep -o '^[0-9]\{3\}' | head -1)
                # Remove leading zeros carefully
                number=$((10#$number))
                if [ "$number" -gt "$highest" ]; then
                    highest=$number
                fi
            fi
        done <<< "$branches"
    fi
    echo "$highest"
}

if [ -z "$BRANCH_NUMBER" ]; then
    HIGHEST=$(get_highest_from_branches)
    BRANCH_NUMBER=$((HIGHEST + 1))
fi

FEATURE_NUM=$(printf "%03d" "$((10#$BRANCH_NUMBER))")
BRANCH_NAME="${FEATURE_NUM}-${DOMAIN}-${FEATURE_SLUG}"

# 建立 Git Branch
if git rev-parse --show-toplevel >/dev/null 2>&1; then
    if git rev-parse --verify "$BRANCH_NAME" >/dev/null 2>&1; then
        echo "⚠️ Branch $BRANCH_NAME already exists, switching to it..."
        git checkout "$BRANCH_NAME"
    else
        git checkout -b "$BRANCH_NAME"
    fi
fi

# ==============================================================================
# 3. 生成 Gherkin 檔案 (核心修改)
# ==============================================================================

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
TARGET_DIR="$REPO_ROOT/specs/features/$DOMAIN"
TARGET_FILE="$TARGET_DIR/$FEATURE_SLUG.feature"
TEMPLATE="$REPO_ROOT/.specify/templates/spec-template.md"

mkdir -p "$TARGET_DIR"

if [ ! -f "$TARGET_FILE" ]; then
    if [ -f "$TEMPLATE" ]; then
        # 讀取 Gherkin 模版並替換 Feature Name
        sed "s/\[Action Name - e.g., RegisterUser or GetUser\]/$FEATURE_SLUG/g" "$TEMPLATE" > "$TARGET_FILE"
    else
        echo "Feature: $FEATURE_SLUG" > "$TARGET_FILE"
        echo "  # Template not found, created empty feature." >> "$TARGET_FILE"
    fi
    ACTION="Created"
else
    ACTION="Existed"
fi

# ==============================================================================
# 4. 輸出結果 (JSON 用於 CLI 整合)
# ==============================================================================

if $JSON_MODE; then
    printf '{"branch_name":"%s","spec_file":"%s","feature_num":"%s"}\n' "$BRANCH_NAME" "$TARGET_FILE" "$FEATURE_NUM"
else
    echo "✅ Branch: $BRANCH_NAME"
    echo "✅ Feature: $TARGET_FILE ($ACTION)"
    echo "📂 Domain: $DOMAIN"
fi