Feature: JWT Token 管理
  定義 Token 的簽發標準、效期與安全性設定

  Background:
    Given 系統 JWT 配置:
      | setting           | value                     |
      | algorithm         | HS256                     |
      | secret_key        | (環境變數 JWT_SECRET_KEY) |
      | access_token_ttl  |            86400 (24小時) |
      | refresh_token_ttl |              604800 (7天) |
      | issuer            | specular-ai               |
    And 系統中存在以下用戶:
      | id       | email             | role  | is_active |
      | user-001 | user@example.com  | user  | true      |
      | user-002 | admin@example.com | admin | true      |
  # ============================================================
  # Rule: Access Token 簽發
  # ============================================================

  Rule: 系統應依據標準格式簽發 Access Token

    Example: 簽發 Access Token 結構
      When 系統為用戶 "user-001" 簽發 Access Token
      Then Token 應為有效的 JWT 格式（三段以 "." 分隔）
      And Token Header 應包含:
        | field | value |
        | alg   | HS256 |
        | typ   | JWT   |
      And Token Payload 應包含:
        | field | value                 |
        | sub   | user-001              |
        | email | user@example.com      |
        | role  | user                  |
        | iss   | specular-ai           |
        | iat   | (簽發時間戳)          |
        | exp   | (簽發時間 + 86400 秒) |
        | jti   | (唯一 Token ID, UUID) |
      And Token 應使用 JWT_SECRET_KEY 正確簽名

    Example: 不同用戶的 Token 包含不同身份資訊
      When 系統為用戶 "user-002" 簽發 Access Token
      Then Token Payload 應包含:
        | field | value             |
        | sub   | user-002          |
        | email | admin@example.com |
        | role  | admin             |

    Example: Token ID (jti) 唯一性
      When 系統連續為同一用戶簽發兩個 Token
      Then 兩個 Token 的 jti 應不相同
      And token_registry 表應有兩筆不同的記錄
  # ============================================================
  # Rule: Token 驗證 - 有效 Token
  # ============================================================

  Rule: 系統應正確驗證有效的 Token

    Example: 成功 - 使用有效 Token 訪問受保護 API
      Given 用戶 "user-001" 持有有效的 Access Token
      And Token 尚未過期
      When 用戶使用該 Token 發送 GET 請求至 "/api/agents"
      Then 請求應成功，回傳狀態碼 200
      And 系統應從 Token 解析出用戶身份:
        | field | value            |
        | sub   | user-001         |
        | email | user@example.com |
        | role  | user             |

    Example: 成功 - Token 即將過期但仍在有效期內
      Given 用戶持有 Access Token，將在 1 秒後過期
      When 用戶使用該 Token 發送請求
      Then 請求應成功
      And 回傳標頭應包含 "X-Token-Expiring-Soon: true"
  # ============================================================
  # Rule: Token 驗證 - 無效 Token
  # ============================================================

  Rule: 系統應拒絕無效的 Token

    Example: 失敗 - Token 已過期
      Given 用戶持有 Access Token，exp 為過去時間
      When 用戶使用該 Token 發送 GET 請求至 "/api/agents"
      Then 請求應失敗，回傳狀態碼 401
      And 錯誤訊息應為 "Token has expired"
      And 回傳標頭應包含 "WWW-Authenticate: Bearer error=\"invalid_token\", error_description=\"Token has expired\""

    Example: 失敗 - Token 簽名無效
      Given 用戶持有使用錯誤密鑰簽名的 Token
      When 用戶使用該 Token 發送請求
      Then 請求應失敗，回傳狀態碼 401
      And 錯誤訊息應為 "Invalid token signature"

    Example: 失敗 - Token 格式錯誤
      When 用戶使用 "invalid.token.format" 發送請求
      Then 請求應失敗，回傳狀態碼 401
      And 錯誤訊息應為 "Invalid token format"

    Example: 失敗 - Token 為空
      When 用戶發送請求，Authorization 標頭為空
      Then 請求應失敗，回傳狀態碼 401
      And 錯誤訊息應為 "Authorization header is required"

    Example: 失敗 - Token 類型錯誤
      When 用戶發送請求，Authorization 標頭為 "Basic abc123"
      Then 請求應失敗，回傳狀態碼 401
      And 錯誤訊息應為 "Bearer token is required"

    Example: 失敗 - Token 已被撤銷
      Given 用戶持有 Access Token，jti 為 "token-123"
      And token_registry 表中 jti "token-123" 的 revoked 為 true
      When 用戶使用該 Token 發送請求
      Then 請求應失敗，回傳狀態碼 401
      And 錯誤訊息應為 "Token has been revoked"
  # ============================================================
  # Rule: Refresh Token
  # ============================================================

  # [TODO] 以下 Refresh Token 相關 API 未在 spec.md 5.1 中定義，請確認是否需要實作
  # Rule: 系統支援使用 Refresh Token 更新 Access Token
  #
  #   Example: 成功 - 使用 Refresh Token 獲取新的 Access Token
  #     Given 用戶 "user-001" 持有有效的 Refresh Token
  #     And refresh_tokens 表中該 Token 記錄:
  #       | field      | value      |
  #       | user_id    | user-001   |
  #       | token_hash | (hash 值)  |
  #       | revoked    | false      |
  #       | expires_at | (未來時間) |
  #     # API: POST /api/v1/auth/refresh (未定義)
  #     When 用戶發送 POST 請求至 "/api/v1/auth/refresh":
  #       | refresh_token | (Refresh Token 值) |
  #     Then 請求應成功，回傳狀態碼 200
  #     And 回傳結果應包含:
  #       | field        | value          |
  #       | access_token | (新 JWT Token) |
  #       | token_type   | bearer         |
  #       | expires_in   |          86400 |
  #     And 新的 Access Token 應包含最新的用戶資訊
  #
  #   Example: 失敗 - Refresh Token 已過期
  #     Given 用戶持有 Refresh Token，expires_at 為過去時間
  #     When 用戶發送 POST 請求至 "/api/v1/auth/refresh"
  #     Then 請求應失敗，回傳狀態碼 401
  #     And 錯誤訊息應為 "Refresh token has expired"
  #
  #   Example: 失敗 - Refresh Token 已被撤銷
  #     Given 用戶持有 Refresh Token
  #     And refresh_tokens 表中該 Token 的 revoked 為 true
  #     When 用戶發送 POST 請求至 "/api/v1/auth/refresh"
  #     Then 請求應失敗，回傳狀態碼 401
  #     And 錯誤訊息應為 "Refresh token has been revoked"
  # ============================================================
  # Rule: Token 撤銷（登出）
  # ============================================================

  # [TODO] 以下 Logout 相關 API 未在 spec.md 5.1 中定義，請確認是否需要實作
  # Rule: 用戶可以撤銷自己的 Token
  #
  #   Example: 成功 - 登出撤銷當前 Token
  #     Given 用戶 "user-001" 持有 Access Token，jti 為 "token-abc"
  #     And token_registry 表中記錄:
  #       | jti       | user_id  | revoked |
  #       | token-abc | user-001 | false   |
  #     # API: POST /api/v1/auth/logout (未定義)
  #     When 用戶使用該 Token 發送 POST 請求至 "/api/v1/auth/logout"
  #     Then 請求應成功，回傳狀態碼 200
  #     And token_registry 表應更新:
  #       | jti       | revoked | revoked_at |
  #       | token-abc | true    | (當前時間) |
  #     And 該 Token 後續的請求應被拒絕
  #
  #   Example: 成功 - 登出撤銷所有 Token
  #     Given 用戶 "user-001" 有 3 個有效的 Token
  #     When 用戶發送 POST 請求至 "/api/v1/auth/logout":
  #       | revoke_all | true |
  #     Then 請求應成功
  #     And token_registry 表中 user_id 為 "user-001" 的所有記錄應標記為 revoked
  #     And refresh_tokens 表中 user_id 為 "user-001" 的所有記錄應標記為 revoked
  # ============================================================
  # Rule: Token 安全性
  # ============================================================

  Rule: Token 應符合安全性最佳實踐

    Example: Token 不應包含敏感資訊
      When 系統簽發 Access Token
      Then Token Payload 不應包含:
        | field         |
        | password      |
        | password_hash |
        | secret        |
        | api_key       |

    Example: Token 應有合理的大小限制
      When 系統簽發 Access Token
      Then Token 大小應小於 4KB

    Example: 使用安全的隨機數生成 jti
      When 系統簽發多個 Token
      Then 每個 jti 應為有效的 UUID v4 格式
      And jti 應使用密碼學安全的隨機數生成器
  # ============================================================
  # Rule: Token 監控
  # ============================================================

  Rule: 系統應記錄 Token 使用狀況

    Example: 記錄 Token 簽發
      When 系統為用戶 "user-001" 簽發 Token
      Then token_registry 表應新增一筆記錄:
        | field      | value       |
        | jti        | (Token ID)  |
        | user_id    | user-001    |
        | issued_at  | (當前時間)  |
        | expires_at | (24小時後)  |
        | ip_address | (簽發時 IP) |
        | user_agent | (簽發時 UA) |
        | revoked    | false       |

    Example: 查詢用戶的活躍 Token 數量
      Given 用戶 "user-001" 有以下 Token:
        | jti     | revoked | expires_at |
        | token-1 | false   | (未來時間) |
        | token-2 | false   | (未來時間) |
        | token-3 | true    | (未來時間) |
        | token-4 | false   | (過去時間) |
      When 管理員查詢用戶 "user-001" 的活躍 Token
      Then 應回傳 2 個活躍 Token（未撤銷且未過期）
