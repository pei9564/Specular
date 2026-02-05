Feature: JWT Token 管理
  # 定義 Token 的簽發標準、效期與安全性設定

  Rule: JWT Token 管理 的核心邏輯
    # 定義 JWT Token 管理 的相關規則與行為

    Example: 簽發 Access Token
      When 系統為用戶簽發 Token
      Then Token 的加密演算法 (alg) 應為 "HS256"
      And Token 的有效期限 (exp) 應為簽發後 24 小時

    Example: 驗證有效 Token
      Given 有一個有效的 Access Token
      When 用戶使用該 Token 訪問受保護的 API
      Then 系統應允許訪問
      And 系統能從 Token 解析出用戶身份 (sub)

    Example: 驗證過期 Token
      Given 有一個已經過期的 Access Token
      When 用戶使用該 Token 訪問受保護的 API
      Then 系統應拒絕訪問
      And 回應 401 Unauthorized
