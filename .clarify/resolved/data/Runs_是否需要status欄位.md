# 釐清問題

Runs 表是否需要 status 欄位以追蹤執行狀態（如 running, completed, failed）？

# 定位

ERM: Runs

# 多選題

| 選項 | 描述 |
|--------|-------------|
| A | 是，新增 status 欄位 (created, processing, completed, failed) |
| B | 否，透過是否產生 output 或 end_time 來判斷 |
| C | 是，且包含 cancelled, expired 等細節狀態 |
| Short | |

# 影響範圍

- ERM: Runs 表新增 status 欄位
- Features: 觸發事件並調用Runtime, 監控與日誌

# 優先級

Medium

---
# 解決記錄

- **回答**：A - 是，新增 status 欄位...
- **更新的規格檔**：spec/erm.dbml
- **變更內容**：Runs 表新增 status 欄位 (created, processing, completed, failed)
