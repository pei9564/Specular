# 釐清問題

使用者在瀏覽 Topic 清單時，系統應支援何種分頁或篩選機制，以應對大量歷史對話？

# 定位

Feature：`Topic查詢.feature`。

# 多選題

| 選項 | 描述 |
|--------|-------------|
| A | Offset/Limit：簡單的頁碼跳躍 |
| B | 游標分頁 (Cursor)：基於 `created_at` 進行連續加載 (Infinite Scroll) |
| C | 不分頁：僅返回最近 50 個主題 |
| Short | 採游標分頁 |

# 影響範圍

影響 API 的效能表現與前端列表的呈現方式。

# 優先級

Medium

- 影響效能設計與 API 規格

---

# 解決記錄

- **回答**：B - 游標分頁 (Cursor-based)：適合無限捲動 (Infinite Scroll)，根據最後一筆對話的時間點來讀取下一批主題。
- **更新的規格檔**：spec/features/Topic查詢.feature
- **變更內容**：新增分頁查詢規則，明確定義使用 limit 與 cursor 參數進行主題列表讀取。
