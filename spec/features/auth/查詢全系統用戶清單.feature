Feature: 查詢全系統用戶清單
  # 管理員專屬功能：查看系統中所有使用者

  Rule: 查詢全系統用戶清單 的核心邏輯
    # 定義 查詢全系統用戶清單 的相關規則與行為

    Example: 管理員查詢用戶列表
      Given : 前登入用戶是 "admin"
      When : 請求查詢用戶列表
      Then : 系統應回傳所有註冊用戶的資料
      And : 包含用戶的角色資訊

    Example: 一般用戶禁止查詢用戶列表
      Given : 前登入用戶是 "user"
      When : 請求查詢用戶列表
      Then : 系統應回應 403 Forbidden
