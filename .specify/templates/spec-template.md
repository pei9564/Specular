# language: en

# -------------------------------------------------------------------------

# SPEC-KIT SYSTEM INSTRUCTION (DO NOT REMOVE)

# -------------------------------------------------------------------------

# Role: You are a Senior Product Architect & QA Lead

# Task: Generate a comprehensive, executable Gherkin Feature file

#

# === CRITICAL: AUTO-FILL & INFERENCE MODE ===

# You are NOT a simple scribe. You MUST actively infer missing requirements

# 1. READ DBML CONTEXT: Check the provided `@...dbml` files. Use EXACT field names

# 2. INFER RULES

# - If DBML has `NOT NULL` -> Generate "Missing Field" failure scenario

# - If DBML has `UNIQUE` -> Generate "Duplicate Entry" failure scenario

# - If DBML has `ENUM` -> Generate "Invalid Status" failure scenario

# 3. DETERMINE TYPE: strict separation between COMMAND (Write) and QUERY (Read)

#

# === TYPE 1: COMMAND RULES (State Changes) ===

# Focus: Input validation, State transitions, Side effects

# Structure

# - Rule 1 [Precondition]: Name must follow "XX 必須/只能 YY" (e.g., "密碼長度必須大於8碼")

# * Auto-generate: Input format validation, Auth checks, Resource ownership

# - Rule 2 [Postcondition]: Name must follow "XX 應該 ZZ" (e.g., "訂單狀態應該變更為已付款")

# * Auto-generate: DB updates, Email notifications, Event publishing

#

# === TYPE 2: QUERY RULES (Data Retrieval) ===

# Focus: Data accuracy, Filtering, Permissions

# Structure

# - Rule 1 [Precondition]: Name must follow "XX 必須/只能 YY" (e.g., "只能查詢自己的訂單")

# * Auto-generate: Permission scope, Filter validation

# - Rule 2 [Success]: Name must follow "成功查詢應 XX" (e.g., "成功查詢應包含完整明細")

# * Auto-generate: Data completeness, Join correctness (based on DBML relations)

#

# Annotation: Mark any AI-inferred scenarios with the tag: @auto_generated

# -------------------------------------------------------------------------

@wip
Feature: [Action Name - e.g., RegisterUser or GetUser]

# Summary: [Brief description of the business goal]

  Background:
    Given the following system state (based on DBML context):
      # Initialize strict minimum data required for these scenarios
      # Example:
      # | table | field | value |

# =========================================================================

# BLOCK A: IF COMMAND (Create/Update/Delete) - Remove Block B if used

# =========================================================================

  Rule: [Precondition] 輸入驗證與狀態檢查 (XX 必須/只能 YY)

    @auto_generated
    Scenario: [Failure] 當違反資料庫限制時 (e.g., Unique/Format)，操作應失敗
      Given [Invalid Input or State]
      When I execute the command
      Then the operation should be rejected
      And the error message should indicate "[Reason]"

    Scenario: [Failure] 當違反業務邏輯時 (e.g., 狀態不允許)，操作應失敗
      Given [Context causing conflict]
      When I execute the command
      Then the operation should be rejected

  Rule: [Postcondition] 成功執行後的狀態改變 (XX 應該 ZZ)

    Scenario: [Success] 當滿足所有條件時，系統狀態應正確更新
      Given [Valid Precondition]
      When I execute the command
      Then the record in "[Table Name]" should be created/updated
      And the field "[Field Name]" should equal "[Value]"
      # Check for side effects (e.g., Email sent)

# =========================================================================

# BLOCK B: IF QUERY (Read Only) - Remove Block A if used

# =========================================================================

  Rule: [Precondition] 查詢權限與條件 (XX 必須/只能 YY)

    @auto_generated
    Scenario: [Failure] 當權限不足或範圍錯誤時，查詢應被拒絕
      Given I am accessing data that belongs to "[Other User]"
      When I request the data
      Then I should receive a "403 Forbidden" error

  Rule: [Success] 回傳資料正確性 (成功查詢應 XX)

    Scenario: [Success] 成功查詢應回傳正確且完整的資料結構
      Given the database contains:
        | table | id | data |
      When I request the data with parameters:
        | param | value |
      Then the response should match the structure defined in "[DBML_Table]"
      And the response should contain exactly:
        | field | value |
