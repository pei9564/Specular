# 釐清問題

系統配置（例如敏感欄位清單 `SENSITIVE_FIELDS`）目前是靜態存儲於設定檔中，還是需要建模於資料庫以便運行時調整？

# 定位

ERM: 缺少 SystemConfig 實體。
Feature: `敏感資料遮罩.feature` Rule 2 (Configuration Based)。

# 多選題

| 選項 | 描述 |
|--------|-------------|
| A | 僅代碼靜態配置 (YAML/Env)，不需資料庫實體 |
| B | 建立資料庫實體 (SystemConfig)，支援 Admin API 即時更新 |
| C | 混合模式：預設使用設定檔，特定欄位可由 DB 覆蓋 |
| Short | Format: Short answer (<=5 words) |

# 影響範圍

影響 ERM 完整性與 `敏感資料遮罩` 的實作方式（是讀取記憶體變數還是查詢 DB）。

# 優先級

Medium
- 影響資料建模完整性與運營靈活性。

---
# 解決記錄

- **回答**：A - 僅代碼靜態配置 (YAML/Env)，不需資料庫實體。
- **更新的規格檔**：無（維持現狀）。
- **變更內容**：確認系統配置參數不進資料庫，維持靜態設定檔結構，符合 `敏感資料遮罩.feature` 的設計。
