Feature: 外部認證整合 (External Authentication Integration)

  Rule: 透過信任的 Header 識別使用者身份 (Trusted Headers)
    # Integration Rule - 系統位於安全邊界內，信任上游 Gateway/Proxy 傳遞的身份資訊

    Example: 接收標準身份 Header 建立 Context
      Given Context: 上游 Gateway 傳入 Request
      And Context: Header `X-User-ID` = "u_ldap_101"
      And Context: Header `X-User-Role` = "Admin"
      When Command: 系統處理請求 (Middleware 解析)
      Then Context: 系統當前 User Context 應為 ID="u_ldap_101", Role="Admin"
      And Read Model: 若該 User ID 不存在於本地 DB，則視為新使用者 (無需同步建立)

    Example: 缺少必要身份 Header (拒絕訪問)
      Given Context: 上游 Gateway 傳入 Request
      But Context: 缺少 `X-User-ID` Header
      When Command: 系統處理請求
      Then Return: 系統應回傳 401 Unauthorized
      And Return: 錯誤訊息 "Missing Identity Headers"

  Rule: 未來擴充保留 (LDAP Compatibility)
    # Placeholder Rule - 確保欄位設計相容於 LDAP 常見屬性

    Example: 接收額外的 LDAP 屬性
      Given Context: Header `X-User-Department` = "Engineering"
      When Command: 系統處理請求
      Then Context: 系統應記錄該 Department 資訊於 Audit Log (若有設定)
