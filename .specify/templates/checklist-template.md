# Specification Audit Checklist: [FEATURE NAME]

**Purpose**: Evidence-based audit of specification quality (filled by `/speckit.clarify`)
**Created**: [DATE]
**Feature**: `[path to .feature file]`
**DBML**: `[path to domain .dbml file]`
**Status**: DRAFT | READY FOR PLANNING

> **Instructions for `/speckit.clarify`**: For each item, search the `.feature` file
> for matching evidence. If found, check the item and quote the Scenario name or
> relevant line as evidence. If not found, leave unchecked and explain what is missing.
> Do NOT rubber-stamp — every checked item MUST have cited evidence.

## Precondition Coverage

- [ ] **NOT NULL 驗證**: 列出覆蓋必填欄位缺失的 Scenario 名稱 → _[evidence]_
- [ ] **UNIQUE 驗證**: 列出覆蓋唯一性約束的 Scenario 名稱 → _[evidence]_
- [ ] **業務規則驗證**: 列出覆蓋業務邏輯前置條件的 Scenario 名稱 → _[evidence]_
- [ ] **邊界覆蓋率**: 多子規則約束 (如密碼強度) 是否使用 Scenario Outline + Examples 覆蓋每個子規則？列出每個約束的覆蓋情況 → _[evidence]_

## Postcondition Coverage

- [ ] **狀態變更驗證**: 列出驗證狀態正確更新的 Scenario 名稱 → _[evidence]_
- [ ] **冪等性驗證**: 列出驗證重複執行安全的 Scenario 名稱 → _[evidence]_
- [ ] **副作用驗證**: 列出驗證 side effects (通知/事件/關聯更新) 的 Scenario 名稱 → _[evidence]_

## Content Quality

- [ ] **無實作細節**: 引述任何提及技術實作的段落（若無則標記 PASS 並說明掃描範圍） → _[evidence]_
- [ ] **Success Criteria 可量測**: 逐條列出每個 criterion 及其量測方式 → _[evidence]_
- [ ] **Success Criteria 無技術用語**: 確認無框架/語言/資料庫等技術名詞 → _[evidence]_
  > Litmus test: 非技術人員能否驗證此 criterion？若否則 FAIL。
  > Anti-patterns (自動 FAIL): "API response time under 200ms",
  > "Database handles 1000 TPS", "React components render efficiently",
  > "Redis cache hit rate above 80%", 任何提及具體框架/語言/中介軟體的指標。
  > 正確寫法: "User receives visual feedback immediately after submission",
  > "The system remains available and responsive during peak load (N users)".

## Schema Alignment

- [ ] **DBML 欄位一致性**: 列出 .feature 中所有欄位名，逐一對照 DBML 來源 → _[evidence]_
- [ ] **DBML 約束覆蓋**: 每個 NOT NULL/UNIQUE/ENUM 約束都有對應的 failure Scenario → _[evidence]_

## Scope & Completeness

- [ ] **範圍明確定義**: 引述 In Scope / Out of Scope 段落 → _[evidence]_
- [ ] **假設已記錄**: 引述 Assumptions 段落 → _[evidence]_
- [ ] **命名規範**: Precondition Rule 使用 "XX 必須/只能 YY"；Postcondition Rule 使用 "XX 應該 ZZ" → _[evidence]_

## Critical Risk Resolution

- [ ] **[CRITICAL] markers 全數解決**: 列出每個 `[CRITICAL]` marker 及其解決方式 → _[evidence]_
- [ ] **System Exit Strategy**: 若 feature 涉及啟動/背景/排程流程，失敗行為已有明確 Scenario → _[evidence or N/A]_
- [ ] **Data Integrity**: 若 feature 涉及寫入/刪除/更新，回滾/衝突策略已有明確 Scenario → _[evidence or N/A]_
- [ ] **Security Boundary**: 若 feature 涉及 authN/authZ，權限模型已有明確 Scenario → _[evidence or N/A]_

> Items marked N/A must include a one-line justification (e.g., "Feature is read-only, no write operations").

## Audit Gate (MANDATORY — clarify MUST fill these)

- [ ] **至少 1 項改善建議**: 描述發現的可優化點或潛在風險 → _[finding]_
- [ ] **至少 1 項邊界風險**: 描述未覆蓋或弱覆蓋的邊界案例 → _[finding]_

> If unable to identify findings for the Audit Gate, re-examine with adversarial lens:
> "What would a hostile user, edge case, or race condition break?"
> The audit is NOT complete until both Audit Gate items are filled.
> Reverse Scenario Scan findings (upstream failure, partial completion, race condition)
> should be recorded here as boundary risks.

## Notes

- This checklist is filled by `/speckit.clarify`, NOT by `/speckit.specify`
- All items must pass (including Audit Gate) before `.feature` transitions from `@wip` to `@ready`
- Items left unchecked after audit require spec updates and re-audit
