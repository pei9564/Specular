# 釐清問題

RAG 知識庫 (Knowledge Bases) 與文件 (Documents) 是否應建模為獨立實體？

# 定位

ERM: KnowledgeBases, Documents

# 多選題

| 選項 | 描述 |
|--------|-------------|
| A | 是，新增 KnowledgeBases 與 Documents 表，建立完整的 RAG 管理系統 |
| B | 否，RAG 視為外部服務，僅在 Agent 中儲存 reference ID |
| C | 僅新增 KnowledgeBases 表，文件內容由外部向量資料庫託管 |
| Short | |

# 影響範圍

- ERM: 新增 KnowledgeBases, Documents 表
- Features: 綁定Agent與RAG知識庫, 上傳文件至知識庫

# 優先級

High

---
# 解決記錄

- **回答**：A - 是，新增 KnowledgeBases 與 Documents 兩個獨立實體表...
- **更新的規格檔**：spec/erm.dbml
- **變更內容**：新增 KnowledgeBases, Documents 實體及 AgentKnowledgeBases 關聯表
