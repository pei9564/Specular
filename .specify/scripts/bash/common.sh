#!/usr/bin/env bash
# .specify/scripts/bash/common.sh
# Common functions and variables for Spec Kit (Gherkin/DDD Edition)

# Get repository root
get_repo_root() {
    if git rev-parse --show-toplevel >/dev/null 2>&1; then
        git rev-parse --show-toplevel
    else
        local script_dir="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        (cd "$script_dir/../../.." && pwd)
    fi
}

# Get current branch
get_current_branch() {
    if [[ -n "${SPECIFY_FEATURE:-}" ]]; then
        echo "$SPECIFY_FEATURE"
        return
    fi

    if git rev-parse --abbrev-ref HEAD >/dev/null 2>&1; then
        git rev-parse --abbrev-ref HEAD
        return
    fi
    echo "main"
}

# Check if git is available
has_git() {
    git rev-parse --show-toplevel >/dev/null 2>&1
}

check_feature_branch() {
    local branch="$1"
    local has_git_repo="$2"

    if [[ "$has_git_repo" != "true" ]]; then
        return 0
    fi

    # 驗證 Branch 格式是否為: ###-Domain-FeatureName
    if [[ ! "$branch" =~ ^[0-9]{3}- ]]; then
        echo "ERROR: Not on a feature branch. Current: $branch" >&2
        echo "Format should be: 001-domain-feature-name" >&2
        return 1
    fi
    return 0
}

# ==============================================================================
# 核心修改：Feature 解析邏輯 (Resolver)
# ==============================================================================

# 根據 Branch 名稱找回對應的 .feature 檔案
# Branch 格式範例: 002-agent-create-agent-v2
# 目標檔案範例: specs/features/agent/CreateAgentV2.feature (忽略大小寫與連字號差異)
find_feature_file() {
    local repo_root="$1"
    local branch_name="$2"
    
    # 1. 移除開頭的編號 (002-)
    local clean_name="${branch_name#*[0-9]-}" 
    
    # 2. 嘗試解析 Domain (取第一個單字)
    # 例如: agent-create-agent-v2 -> domain=agent
    local domain="${clean_name%%-*}"
    
    # 3. 剩餘部分當作 Slug
    # 例如: create-agent-v2
    local slug="${clean_name#*-}"
    
    local features_dir="$repo_root/specs/features"
    local target_domain_dir="$features_dir/$domain"

    # 如果找不到 Domain 資料夾，嘗試全域搜尋 (Fallback)
    if [[ ! -d "$target_domain_dir" ]]; then
        local found=$(find "$features_dir" -name "*.feature" | grep -i "$(echo $slug | sed 's/-//g')" | head -1)
        echo "$found"
        return
    fi

    # 4. 在 Domain 資料夾內搜尋 (Fuzzy Search)
    # 將 slug 的 '-' 去掉 (createagentv2)，並忽略大小寫搜尋
    # 這是為了匹配 create-agent-v2 (Branch) 對應 CreateAgentV2.feature (File)
    local clean_slug=$(echo "$slug" | sed 's/-//g')
    
    # 使用 find 命令進行不分大小寫的模糊匹配
    local found_file=$(find "$target_domain_dir" -type f -name "*.feature" | while read f; do
        fname=$(basename "$f")
        # 移除副檔名和連字號，轉小寫比較
        clean_fname=$(echo "${fname%.feature}" | sed 's/-//g' | tr '[:upper:]' '[:lower:]')
        clean_target=$(echo "$clean_slug" | tr '[:upper:]' '[:lower:]')
        
        if [[ "$clean_fname" == "$clean_target" ]]; then
            echo "$f"
            break
        fi
    done | head -1)

    # 如果真的找不到，回傳一個預期的路徑 (讓後續流程報錯報得準確點)
    if [[ -n "$found_file" ]]; then
        echo "$found_file"
    else
        # Fallback path
        echo "$target_domain_dir/$slug.feature"
    fi
}

# 生成路徑變數供其他腳本使用
get_feature_paths() {
    local repo_root=$(get_repo_root)
    local current_branch=$(get_current_branch)
    local has_git_repo="false"
    if has_git; then has_git_repo="true"; fi

    # 找出核心 Feature File
    local feature_file=$(find_feature_file "$repo_root" "$current_branch")
    local feature_dir=$(dirname "$feature_file")
    
    # 根據 Feature File 的檔名，推導其他檔案名稱
    # 範例 Feature: specs/features/agent/CreateAgentV2.feature
    # 範例 Plan:    specs/features/agent/CreateAgentV2.plan.md
    
    local base_name=$(basename "$feature_file" .feature)
    
    # 檢查是否真的抓到了檔案
    local file_exists="false"
    if [[ -f "$feature_file" ]]; then file_exists="true"; fi

    cat <<EOF
REPO_ROOT='$repo_root'
CURRENT_BRANCH='$current_branch'
HAS_GIT='$has_git_repo'
FEATURE_EXISTS='$file_exists'
FEATURE_DIR='$feature_dir'
FEATURE_FILE='$feature_file'
FEATURE_SPEC='$feature_file'
IMPL_PLAN='$feature_dir/$base_name.plan.md'
TASKS='$feature_dir/$base_name.tasks.md'
DBML_DIR='$repo_root/specs/db_schema'
EOF
}

check_file() { [[ -f "$1" ]] && echo "  ✓ $2" || echo "  ✗ $2"; }
check_dir() { [[ -d "$1" && -n $(ls -A "$1" 2>/dev/null) ]] && echo "  ✓ $2" || echo "  ✗ $2"; }