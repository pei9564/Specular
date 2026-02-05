# 釐清問題

是否需要 UserSettings 實體來儲存用戶偏好（如主題、語言、通知設定）？

# 定位

ERM: UserSettings

# 多選題

| 選項 | 描述 |
|--------|-------------|
| A | 是，新增 UserSettings 表，與 Users 1:1 關聯 |
| B | 否，將偏好設定存於 Users 表的 json 欄位 |
| C | 暫不處理，MVP 階段無需用戶偏好 |
| Short | |

# 影響範圍

- ERM: 新增 UserSettings 或 Users 表擴充
- Features: 用戶中心/個人設定

# 優先級

Low

---
# 解決記錄

- **回答**：C - 暫不處理，MVP 階段無需用戶偏好
- **更新的規格檔**：無
- **變更內容**：本次不新增 UserSettings 實體或欄位
