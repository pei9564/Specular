# 釐清問題

Messages 表的 role 欄位是否應增加 `tool` 選項以儲存工具回傳結果？

# 定位

ERM: Messages.role

# 多選題

| 選項 | 描述 |
|--------|-------------|
| A | 是，新增 `tool` role，用於儲存工具執行後的結果回傳給 LLM |
| B | 否，工具結果僅存於 ToolCalls 表，組裝 context 時動態合併 |
| C | 否，使用 system role 標記工具結果 |
| Short | |

# 影響範圍

- ERM: Messages.role enum 更新
- Features: 發送訊息給Agent (工具調用流程)
- Features: 查詢會話歷史訊息

# 優先級

High

---
# 解決記錄

- **回答**：A - 是，新增 tool role...
- **更新的規格檔**：spec/erm.dbml
- **變更內容**：Messages.role 新增 'tool' 選項
