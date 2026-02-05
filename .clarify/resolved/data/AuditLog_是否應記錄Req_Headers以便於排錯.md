# 釐清問題

為了便於開發期的請求排錯，`AuditLog` 是否應增加記錄非敏感的 Request Headers (如 User-Agent, Content-Type)？

# 定位

ERM：`AuditLog` 實體。
Feature：`Request記錄.feature` 功能。

# 多選題

| 選項 | 描述 |
|--------|-------------|
| A | 不記錄：保持資料表精簡 |
| B | 完整記錄：除了 Authorization 等敏感 Header 外全部存入 |
| C | 選擇性記錄：僅錄取特定的 Trace/Context Headers |
| Short | 記錄非敏感 Header |

# 影響範圍

影響 Audit Log 的儲存空間需求與管理員的排錯效率。

# 優先級

Low

- 優化或細節調整
