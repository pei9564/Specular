# language: en

# -------------------------------------------------------------------------

# SPEC-KIT INSTRUCTION (DO NOT REMOVE)

# -------------------------------------------------------------------------

# Task: Generate a Gherkin Feature based on user input

# Context

# 1. Check `spec/db_schema/*.dbml` for data structures. Use exact field names

# 2. Determine if the user request is a COMMAND (State Change) or QUERY (Data Retrieval)

#

# Rules for COMMAND (Command Type)

# - Focus: State transitions, validations, side effects

# - Rule 1 (Precondition): Naming "XX 必須/只能 YY" (Validation failures)

# - Rule 2 (Postcondition): Naming "XX 應該 ZZ" (State changes, events)

#

# Rules for QUERY (Query Type)

# - Focus: Data accuracy, filtering, permission

# - Rule 1 (Precondition): Naming "XX 必須/只能 YY" (Auth/Permission)

# - Rule 2 (Success): Naming "成功查詢應 XX" (Correct data returned)

# -------------------------------------------------------------------------

@wip
Feature: [Action Name - e.g., RegisterUser or GetUser]

# Summary of what this action does

  Background:
    Given the following system state from "spec/db_schema/":
      # Initialize necessary data based on DBML definitions
      # Example:
      # | table  | field | value |

# =========================================================

# IF COMMAND (修改型) - Delete this block if it's a Query

# =========================================================

  Rule: [Precondition] 輸入驗證與狀態檢查 (XX 必須/只能 YY)
    # Edge Cases & Fail Cases
    Scenario: [Failure] 當沒滿足前置條件時，操作應失敗
      Given [Invalid Precondition]
      When I execute the command
      Then the operation should be rejected with error "[Error Code]"

  Rule: [Postcondition] 成功執行後的狀態改變 (XX 應該 ZZ)
    # Success Case
    Scenario: [Success] 當滿足條件時，系統狀態應正確更新
      Given [Valid Precondition]
      When I execute the command
      Then the record in "[Table Name]" should be created/updated
      And the field "[Field Name]" should equal "[Value]"

# =========================================================

# IF QUERY (查詢型) - Delete this block if it's a Command

# =========================================================

  Rule: [Precondition] 查詢權限與條件 (XX 必須/只能 YY)
    # Edge Cases & Fail Cases
    Scenario: [Failure] 當權限不足或條件錯誤時，查詢應被拒絕
      Given [Invalid Permission/Condition]
      When I request the data
      Then I should receive a "[Error Code]" error

  Rule: [Success] 回傳資料正確性 (成功查詢應 XX)
    # Success Case
    Scenario: [Success] 成功查詢應回傳正確且完整的資料
      Given the database contains:
        | table | id | data |
      When I request the data with parameters:
        | param | value |
      Then the response should contain exactly:
        | field | value |
      And the data structure should match "[DBML_Table_Name]"
