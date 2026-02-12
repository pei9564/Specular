# Specification Audit Checklist: InitialAdmin

**Purpose**: Evidence-based audit of specification quality (filled by `/speckit.clarify`)
**Created**: 2026-02-12
**Feature**: `specs/features/auth/InitialAdmin.feature`
**DBML**: `specs/db_schema/auth.dbml` (@provisional)
**Status**: READY FOR PLANNING

## Precondition Coverage

- [x] **NOT NULL 驗證**: → password NOT NULL: Scenario "[Failure] 當密碼未透過環境設定提供時，系統應中止啟動" (line 86). username/email NOT NULL handled via defaults: Scenarios "當環境未設定 username 時" (line 150) and "當環境未設定 email 時" (line 159).
- [x] **UNIQUE 驗證**: → username UNIQUE: Scenario "[Failure] 當 username 與既有帳號重複時" (line 110). email UNIQUE: Scenario "[Failure] 當 email 與既有帳號重複時" (line 121).
- [x] **業務規則驗證**: → Scenario "[Failure] 當已存在管理員帳號時，不應重複建立" (line 78) covers the core precondition that admin must not exist.
- [x] **邊界覆蓋率**: → Scenario Outline "[Failure] 當密碼不符合 <rule> 時" (lines 93-107) uses Examples table with 5 sub-rules: 長度不足, 缺少大寫字母, 缺少小寫字母, 缺少數字, 缺少特殊字元.

## Postcondition Coverage

- [x] **狀態變更驗證**: → Scenario "[Success] 當系統首次啟動且無管理員帳號時" (line 133) verifies all fields: username, email, role, is_active, password_hash (hashed), created_at (UTC).
- [x] **冪等性驗證**: → Scenario "[Success] 重複啟動系統應保持冪等性" (line 168) verifies no new record, existing unchanged, updated_at not modified. Also: Scenario "[Failure] 當已存在管理員帳號時" (line 78) covers from precondition angle.
- [x] **副作用驗證**: → password_hash storage verified as "secure one-way hash (not equal to plaintext)" (line 147). created_at UTC timestamp verified (line 148). No external notification side effects defined for this feature (appropriate — this is an internal startup process).

## Content Quality

- [x] **無實作細節**: → Scanned all 178 lines. No mentions of specific languages, frameworks, libraries, or APIs. "one-way hash" is a security requirement, not an implementation choice. "UTC timestamp" is a data constraint. PASS.
- [x] **Success Criteria 可量測**: → (1) "within 30 seconds of first system startup" — measurable by timer. (2) "100% of deployments" — measurable by deployment success rate. (3) "never produce duplicate" — measurable by record count. (4) "refuse to create insecure accounts and report the issue clearly" — measurable by error output.
- [x] **Success Criteria 無技術用語**: → No framework/language/database names in Success Criteria (lines 42-45). Litmus test: a non-technical operator can verify all 4 criteria by observing login behavior, deployment logs, and restart behavior. PASS.

## Schema Alignment

- [x] **DBML 欄位一致性**: → Fields in .feature mapped to auth.dbml: username → users.username (varchar(50), NOT NULL, UNIQUE) ✓ | email → users.email (varchar(255), NOT NULL, UNIQUE) ✓ | password_hash → users.password_hash (varchar(255), NOT NULL) ✓ | role → users.role (user_role ENUM, NOT NULL) ✓ | is_active → users.is_active (boolean, NOT NULL) ✓ | created_at → users.created_at (timestamptz, NOT NULL) ✓ | updated_at → users.updated_at (timestamptz, NOT NULL) ✓. "password" in env config is input-only (not a DB field) — correct.
- [x] **DBML 約束覆蓋**: → NOT NULL: password (line 86), username/email via defaults (lines 150, 159). UNIQUE: username (line 110), email (line 121). ENUM user_role: role is hardcoded to super_admin (not user-provided input), so invalid ENUM scenario is not applicable. All applicable constraints covered.

## Scope & Completeness

- [x] **範圍明確定義**: → In Scope: "Automatic creation of one initial admin account on first startup" (line 48). Out of Scope: "Admin account management UI, password reset flow, multi-admin seeding" (line 49).
- [x] **假設已記錄**: → Assumptions section (lines 31-39) covers: env config source, default username/email, mandatory password, role, hash storage, idempotency, password rules, UTC timestamps.
- [x] **命名規範**: → Precondition Rule: "初始管理員只能在無管理員帳號且設定完整時建立" — uses "只能" ✓. Postcondition Rule: "成功建立後系統應有可用的管理員帳號" — uses "應" ✓.

## Critical Risk Resolution

- [x] **[CRITICAL] markers 全數解決**: → 1 marker found: `[CRITICAL: System Exit Strategy]`. Resolved via clarification Q1 → "Fail-fast (abort startup)". Marker replaced with explicit System Exit Strategy section (lines 51-54) and all failure Scenarios updated to "system should abort startup".
- [x] **System Exit Strategy**: → Fail-fast strategy documented (lines 51-54). All failure Scenarios (lines 86-129) use "the system should abort startup" as the outcome. Exception: "當已存在管理員帳號時" (line 78) correctly does NOT abort — existing admin is a normal state, not an error.
- [x] **Data Integrity**: → Idempotency: Scenario "重複啟動系統應保持冪等性" (line 168). UNIQUE conflicts: username (line 110) and email (line 121) abort startup rather than corrupting data. No partial-write scenario (see Audit Gate boundary risk below).
- [x] **Security Boundary**: → Role explicitly set to super_admin (line 145). Password strength enforced with 5 sub-rules (lines 93-107). Password hash storage verified (line 147). is_active explicitly set to true (line 146).

## Audit Gate (MANDATORY)

- [x] **至少 1 項改善建議**: → The "當已存在管理員帳號時，不應重複建立" scenario (line 78) checks by role=super_admin, but the DBML allows multiple roles (super_admin, admin, member). If a future feature creates "admin" role accounts, the check should clarify whether ANY admin-level role blocks creation or only super_admin. Currently the check is narrowly scoped to super_admin which is correct for now, but the boundary between super_admin and admin roles should be explicitly defined when additional auth features are added.
- [x] **至少 1 項邊界風險**: → **Race condition (concurrent startup)**: If two system instances start simultaneously, both could pass the "no super_admin exists" check and attempt concurrent inserts. The UNIQUE constraint on username/email would cause one to fail at DB level, but the spec has no Scenario describing this concurrent behavior. For a single-instance startup command this is low-probability, but in containerized deployments (multiple replicas starting simultaneously) it becomes realistic. The DB UNIQUE constraint provides a safety net, but the expected behavior (which instance wins, how the loser handles the constraint violation) is unspecified. Recommended: defer to Plan phase as a deployment-level concern, document as a known edge case.

## Notes

- DBML remains `@provisional` — must be ratified during `/speckit.plan`
- @auto_generated scenarios reviewed: all 3 are valid (password Outline, username UNIQUE, email UNIQUE). No redundancy or logical impossibility found.
- Race condition edge case documented in Audit Gate but deferred to Plan phase (deployment-level concern, not spec-level).
- 2 clarification questions asked and resolved in this session.
