# 釐清問題

當 Agent 的狀態被設為 `Deleted` 時，該記錄是否仍保留於資料庫（軟刪除）？若是，管理員是否具備還原該 Agent 的能力？

# 定位

Feature：`Agent設置.feature` (Lifecycle Management)。

# 多選題

| 選項 | 描述 |
|--------|-------------|
| A | 永久刪除：不可還原 |
| B | 軟刪除：資料保留但不顯現，Admin 可透過後台還原 |
| C | 僅設為 Inactive：不提供刪除功能，僅能隱藏 |
| Short | 支援軟刪除還原 |

# 影響範圍

影響 Agent 的刪除操作實作方式（DELETE vs UPDATE status）以及管理功能的設計。

# 優先級

Low

- 營運管理流程細節

---

# 解決記錄

- **回答**：B - 軟刪除：資料保留但不顯現，Admin 可透過後台還原
- **更新的規格檔**：spec/features/Agent設置.feature, spec/erm.dbml
- **變更內容**：在 Agent設置.feature 中新增還原 (RestoreAgent) 規則，並在 erm.dbml 註記狀態為軟刪除可還原。
