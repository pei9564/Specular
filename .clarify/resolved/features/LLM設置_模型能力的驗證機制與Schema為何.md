# 釐清問題

註冊 LLM 時的 `capabilities` (如 `tool_use`, `vision`) 目前僅驗證是否為合法字串，未來是否需支援針對特定能力的參數配置 (如 `vision` 支援的最大解析度)？

# 定位

Feature：`LLM設置.feature`。

# 多選題

| 選項 | 描述 |
|--------|-------------|
| A | 保持字串清單：簡單快速，不支援細部參數 |
| B | 升級為物件：`{ "name": "vision", "config": {...} }` |
| C | 分離欄位：能力維持字串，細節放入 `configuration` 欄位 |
| Short | 能力維持字串清單 |

# 影響範圍

影響模型能力宣告的靈活性與後續技術對接的深度。

# 優先級

Low

- 未來擴充性考量

---

# 解決記錄

- **回答**：B - 枚舉化 (Strict)：必須符合系統定義的枚舉值。
- **更新的規格檔**：spec/erm.dbml, spec/features/LLM設置.feature
- **變更內容**：在 LLM設置 Feature 中已具備驗證邏輯，並在 erm.dbml 中註記 capabilities 需符合系統枚舉值。
