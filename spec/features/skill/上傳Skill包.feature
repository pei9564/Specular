Feature: 上傳 Skill 包
  使用者上傳自定義 Python 工具包

  Background:
    Given 系統中存在以下用戶:
      | id        | email             | role  |
      | user-001  | user@example.com  | user  |
      | admin-001 | admin@example.com | admin |
    And Skill 包必須包含以下結構:
      | file             | required | description             |
      | SKILL.md         | true     | Skill 說明文件          |
      | __init__.py      | true     | Python 模組初始化       |
      | functions.py     | true     | 工具函數定義            |
      | requirements.txt | false    | Python 依賴套件（可選） |
      | config.json      | false    | Skill 配置（可選）      |
    And 使用者 "user@example.com" 已登入
  # ============================================================
  # Rule: 上傳合法的 Skill 包
  # ============================================================

  Rule: 用戶可以上傳符合規範的 Skill ZIP 包

    Example: 成功 - 上傳合法的 Skill ZIP
      Given 用戶準備了 ZIP 檔案 "calculator.zip" 包含:
        | file         | content                                      |
        | SKILL.md     | # Calculator\n計算工具                       |
        | __init__.py  | from .functions import *                     |
        | functions.py | def calculate(expression: str) -> float: ... |
      When 使用者發送 POST 請求至 "/api/skills/upload":
        | file | (calculator.zip binary) |
      Then 請求應成功，回傳狀態碼 201
      And skills 表應新增一筆記錄:
        | field        | value           |
        | id           | (自動生成 UUID) |
        | name         | calculator      |
        | display_name | Calculator      |
        | description  | 計算工具        |
        | version      |           1.0.0 |
        | owner_id     | user-001        |
        | status       | active          |
        | visibility   | private         |
        | created_at   | (當前時間)      |
      And skill_functions 表應新增一筆記錄:
        | field             | value                              |
        | skill_id          | (新 Skill ID)                      |
        | function_name     | calculate                          |
        | parameters_schema | {"expression": {"type": "string"}} |
        | return_type       | float                              |
      And Skill 檔案應儲存至 "/skills/{skill_id}/" 目錄

    Example: 成功 - 解析多個工具函數
      Given ZIP 檔案的 functions.py 包含多個函數:
        """python
        def add(a: int, b: int) -> int:
            '''加法運算'''
            return a + b
        
        def subtract(a: int, b: int) -> int:
            '''減法運算'''
            return a - b
        
        def _private_helper():
            '''私有函數，不應被解析'''
            pass
        """
      When 使用者上傳該 ZIP
      Then skill_functions 表應新增 2 筆記錄（排除以 _ 開頭的私有函數）:
        | function_name | description |
        | add           | 加法運算    |
        | subtract      | 減法運算    |

    Example: 成功 - 自動生成 JSON Schema
      Given functions.py 包含帶有類型標註的函數:
        """python
        def search(
            query: str,
            limit: int = 10,
            filters: dict = None
        ) -> list[dict]:
            '''搜尋功能'''
            pass
        """
      When 使用者上傳該 ZIP
      Then skill_functions 記錄的 parameters_schema 應為:
        """json
        {
          "type": "object",
          "properties": {
            "query": {"type": "string", "description": ""},
            "limit": {"type": "integer", "default": 10},
            "filters": {"type": "object", "default": null}
          },
          "required": ["query"]
        }
        """

    Example: 成功 - 包含依賴套件
      Given ZIP 檔案包含 requirements.txt:
        """
        requests>=2.28.0
        pandas>=2.0.0
        """
      When 使用者上傳該 ZIP
      Then skills 記錄的 dependencies 應為:
        | package  | version  |
        | requests | >=2.28.0 |
        | pandas   | >=2.0.0  |
  # ============================================================
  # Rule: 檔案結構驗證
  # ============================================================

  Rule: 系統應驗證 Skill 包的檔案結構

    Example: 失敗 - 缺少 SKILL.md
      Given ZIP 檔案缺少 SKILL.md
      When 使用者上傳該 ZIP
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "Missing required file: SKILL.md"

    Example: 失敗 - 缺少 functions.py
      Given ZIP 檔案缺少 functions.py
      When 使用者上傳該 ZIP
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "Missing required file: functions.py"

    Example: 失敗 - 缺少 __init__.py
      Given ZIP 檔案缺少 __init__.py
      When 使用者上傳該 ZIP
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "Missing required file: __init__.py"

    Example: 失敗 - 不是有效的 ZIP 檔案
      When 使用者上傳一個非 ZIP 格式的檔案
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "Invalid file format. Expected ZIP archive."

    Example: 失敗 - ZIP 檔案過大
      Given ZIP 檔案大小超過 50MB
      When 使用者上傳該 ZIP
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "File size exceeds maximum limit (50MB)"
  # ============================================================
  # Rule: Python 程式碼驗證
  # ============================================================

  Rule: 系統應驗證 Python 程式碼的安全性

    Example: 失敗 - functions.py 語法錯誤
      Given functions.py 包含語法錯誤:
        """python
        def broken_function(
            # 缺少閉合括號
        """
      When 使用者上傳該 ZIP
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應包含 "Syntax error in functions.py"

    Example: 失敗 - 無任何可用的工具函數
      Given functions.py 只包含私有函數:
        """python
        def _helper():
            pass
        """
      When 使用者上傳該 ZIP
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "No public functions found in functions.py"

    Example: 警告 - 函數缺少類型標註
      Given functions.py 的函數缺少類型標註:
        """python
        def process(data):
            return data
        """
      When 使用者上傳該 ZIP
      Then 請求應成功
      And 回傳應包含警告:
        | warning | Function 'process' is missing type annotations. Schema will use 'any' type. |

    Example: 失敗 - 禁止的 import 語句
      Given functions.py 包含危險的 import:
        """python
        import os
        import subprocess
        
        def dangerous():
            subprocess.run(['rm', '-rf', '/'])
        """
      When 使用者上傳該 ZIP
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "Forbidden imports detected: os, subprocess"
  # ============================================================
  # Rule: 版本管理
  # ============================================================

  Rule: 支援 Skill 版本更新

    Example: 成功 - 上傳新版本
      Given 系統中已存在 Skill "calculator" 版本 "1.0.0"，owner 為 user-001
      When 使用者上傳新版本的 calculator.zip:
        | config.version | 1.1.0 |
      Then 請求應成功
      And skills 表應新增一筆新記錄:
        | name                | calculator  |
        | version             |       1.1.0 |
        | previous_version_id | (舊版本 ID) |
      And 舊版本應標記為 is_latest = false

    Example: 失敗 - 版本號未遞增
      Given 系統中已存在 Skill "calculator" 版本 "1.0.0"
      When 使用者上傳版本號為 "0.9.0" 的 calculator.zip
      Then 請求應失敗，回傳狀態碼 400
      And 錯誤訊息應為 "Version '0.9.0' must be greater than current version '1.0.0'"

    Example: 失敗 - 非擁有者無法更新
      Given Skill "calculator" 的 owner 為 user-002
      When 使用者 "user-001" 上傳 calculator.zip 新版本
      Then 請求應失敗，回傳狀態碼 403
      And 錯誤訊息應為 "You do not have permission to update this skill"
  # ============================================================
  # Rule: 名稱衝突
  # ============================================================

  Rule: Skill 名稱在同一擁有者下必須唯一

    Example: 失敗 - 名稱已存在（同一用戶）
      Given 使用者 "user-001" 已有 Skill 名稱為 "calculator"
      When 使用者上傳另一個名為 "calculator" 的新 Skill
      Then 請求應失敗，回傳狀態碼 409
      And 錯誤訊息應為 "A skill named 'calculator' already exists. Use version update to modify existing skill."

    Example: 成功 - 不同用戶可有相同名稱
      Given 使用者 "user-002" 已有 Skill 名稱為 "calculator"
      When 使用者 "user-001" 上傳名為 "calculator" 的 Skill
      Then 請求應成功
      And 系統中應有兩個不同 owner 的 "calculator" Skill
  # ============================================================
  # Rule: 上傳配額
  # ============================================================

  Rule: 用戶的 Skill 上傳有數量限制

    Example: 失敗 - 超過 Skill 數量上限
      Given 使用者 "user-001" 已上傳 20 個 Skill（達到上限）
      When 使用者上傳新的 Skill
      Then 請求應失敗，回傳狀態碼 429
      And 錯誤訊息應為 "Skill quota exceeded. Maximum: 20 skills per user."
  # ============================================================
  # Rule: 審計日誌
  # ============================================================

  Rule: 上傳操作應記錄審計日誌

    Example: 記錄上傳操作
      When 使用者上傳 Skill
      Then audit_logs 表應新增一筆記錄:
        | field       | value                                                            |
        | action      | skill.upload                                                     |
        | actor_id    | user-001                                                         |
        | target_type | skill                                                            |
        | target_id   | (新 Skill ID)                                                    |
        | details     | {"name": "calculator", "version": "1.0.0", "functions_count": 2} |
        | created_at  | (當前時間)                                                       |
