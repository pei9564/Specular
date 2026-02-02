# language: zh-TW
功能: Agent 管理介面

  場景: 使用者進入 Agent 列表頁面
    假設使用者已開啟瀏覽器
    當使用者導航到 "/agents" 頁面
    那麼頁面標題應包含 "Agent"

  場景: 使用者建立新的 Agent
    假設使用者在 Agent 列表頁面
    當使用者點擊 "新增 Agent" 按鈕
    並且使用者在 "名稱" 欄位輸入 "TestAgent"
    並且使用者點擊 "儲存" 按鈕
    那麼應顯示成功訊息
    並且列表應包含 "TestAgent"
