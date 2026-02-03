# AGUI 兼容 Chat SSE 事件規格

## 1. 核心概念映射 (Mapping)

為了符合 AGUI，我們需要將您原有的 ID 系統與 AGUI 的命名慣例對接：

* **`thread_id`** (原)  **`threadId`** (AGUI): 代表一個對話線程，屬於某個 ChatTopic。
* **`trace_id`** (原)  **`runId`** (AGUI): 代表 Agent 的一次執行（一次推論）。
* **`message_id`** (原)  **`messageId`** (AGUI): 每個對話氣泡的唯一 ID。
* **`tool_call_id`** (原)  **`toolCallId`** (AGUI): 工具調用的唯一 ID。

---

## 2. SSE 事件類型總覽 (AGUI Standard)

AGUI 使用 PascalCase 作為事件名稱。

| Event Type (AGUI) | 對應原事件 | 觸發時機 | 關鍵 Payload 欄位 |
| --- | --- | --- | --- |
| **`RunStarted`** | `stream.started` | Agent 開始處理請求時 | `runId`, `threadId` |
| **`TextMessageStart`** | (新) | 準備輸出一段文字訊息時 | `messageId`, `role` |
| **`TextMessageContent`** | `stream.chunk` | 串流傳輸文字內容片段 | `messageId`, `delta` |
| **`TextMessageEnd`** | (新) | 該段文字訊息傳輸結束 | `messageId` |
| **`ToolCallStart`** | `tool.started` | Agent 決定調用工具時 | `toolCallId`, `toolCallName` |
| **`ToolCallArgs`** | (新) | 串流傳輸工具參數 (JSON 片段) | `toolCallId`, `delta` |
| **`ToolCallEnd`** | (新) | 工具參數傳輸結束 | `toolCallId` |
| **`ToolCallResult`** | `tool.completed` | 工具執行完畢回傳結果 | `toolCallId`, `result` |
| **`RunFinished`** | `stream.done` | 整個推論流程正常結束 | `runId` |
| **`RunError`** | `stream.error` | 發生錯誤導致流程終止 | `code`, `message` |

> **註：** AGUI 也有 `StepStarted`/`StepFinished`，若您的 Agent 邏輯較簡單，可暫時省略，或將「思考過程」映射為 Step。

---

## 3. 資料格式詳細說明 (Payloads)

AGUI 偏好使用 `camelCase` (小駝峰) 命名欄位。

### 3.1 Lifecycle Events (運行生命週期)

#### `RunStarted`

初始化 UI 狀態（如顯示 Loading）。

```json
{
  "runId": "run-abc123",
  "threadId": "thread-xyz789",  // 對應 ChatThread.thread_id
  "timestamp": "2026-02-03T14:30:05Z",
  "input": { ... } // (可選) 觸發這次 run 的輸入
}

```

#### `RunFinished`

標記本次互動完全結束。

```json
{
  "runId": "run-abc123",
  "threadId": "thread-xyz789",
  "timestamp": "2026-02-03T14:30:20Z",
  "usage": { "total_tokens": 350 } // 可放在 result 或自定義欄位
}

```

#### `RunError`

取代 `stream.error` 與 `stream.aborted`。

```json
{
  "runId": "run-abc123",
  "code": "token_limit", // 原 error_type
  "message": "單次訊息過長，請嘗試縮減內容"
}

```

### 3.2 Text Message Events (文字訊息流)

AGUI 將訊息拆分為 Start -> Content -> End，確保前端能精確控制何時建立氣泡、何時結束 Loading。

#### `TextMessageStart`

```json
{
  "messageId": "msg-new-001",
  "role": "assistant",
  "timestamp": "2026-02-03T14:30:06Z"
}

```

#### `TextMessageContent` (核心串流)

注意：AGUI 使用 `delta` 而非 `content`，且通常不依賴 `index`，而是依賴 TCP/SSE 的順序性。

```json
{
  "messageId": "msg-new-001",
  "delta": "量子"
}

```

#### `TextMessageEnd`

```json
{
  "messageId": "msg-new-001",
  "timestamp": "2026-02-03T14:30:07Z"
}

```

### 3.3 Tool Call Events (工具調用流)

AGUI 支援工具參數的串流 (Streaming Arguments)，這對於參數很長的情況（如生成程式碼或長文本參數）非常有用。

#### `ToolCallStart`

```json
{
  "toolCallId": "call-xyz",
  "toolCallName": "search_arxiv",
  "parentMessageId": "msg-new-001" // 關聯到哪則訊息觸發的
}

```

#### `ToolCallArgs` (可多次發送)

```json
{
  "toolCallId": "call-xyz",
  "delta": "{\"query\": \"quantum" 
}

```

*(下一幀)*

```json
{
  "toolCallId": "call-xyz",
  "delta": " entanglement\"}" 
}

```

#### `ToolCallEnd` (參數傳輸結束，開始執行)

```json
{
  "toolCallId": "call-xyz"
}

```

#### `ToolCallResult` (執行結果)

```json
{
  "toolCallId": "call-xyz",
  "result": { "papers": [...] },
  "isError": false
}

```

---

## 4. 完整事件序列範例

### 4.1 正常回答 (無工具)

```text
RunStarted         -> { runId: "run-1" }
TextMessageStart   -> { messageId: "msg-1", role: "assistant" }
TextMessageContent -> { messageId: "msg-1", delta: "你好" }
TextMessageContent -> { messageId: "msg-1", delta: "，" }
TextMessageContent -> { messageId: "msg-1", delta: "請問" }
TextMessageEnd     -> { messageId: "msg-1" }
RunFinished        -> { runId: "run-1" }

```

### 4.2 包含工具呼叫 (Tool Usage)

```text
RunStarted         -> { runId: "run-2" }

// Agent 決定使用工具
ToolCallStart      -> { toolCallId: "call-1", toolCallName: "Weather" }
ToolCallArgs       -> { toolCallId: "call-1", delta: "{\"city\"" }
ToolCallArgs       -> { toolCallId: "call-1", delta: ":\"Taipei\"}" }
ToolCallEnd        -> { toolCallId: "call-1" }

// (此時後端正在執行工具...)

ToolCallResult     -> { toolCallId: "call-1", result: "25°C" }

// Agent 根據結果生成回應
TextMessageStart   -> { messageId: "msg-2", role: "assistant" }
TextMessageContent -> { messageId: "msg-2", delta: "台北現在" }
TextMessageContent -> { messageId: "msg-2", delta: "25度" }
TextMessageEnd     -> { messageId: "msg-2" }

RunFinished        -> { runId: "run-2" }

```

---

## 5. 前端實作修正 (JavaScript 範例)

修正後的 EventSource 監聽邏輯，針對 AGUI 事件進行處理。

```javascript
async function startChat(topicId, content) {
  // ... POST request ...
  const eventSource = new EventSource(response.url);
  
  // 暫存目前的訊息內容，用於 UI 拼接
  let currentMessageBuffer = "";
  
  // 1. 運行開始
  eventSource.addEventListener('RunStarted', (e) => {
    const data = JSON.parse(e.data);
    console.log(`Run started: ${data.runId}`);
    setLoading(true);
  });

  // 2. 文字訊息生命週期
  eventSource.addEventListener('TextMessageStart', (e) => {
    const data = JSON.parse(e.data);
    createMessageBubble(data.messageId, data.role); // 建立空的對話框
  });

  eventSource.addEventListener('TextMessageContent', (e) => {
    const data = JSON.parse(e.data);
    appendMessageContent(data.messageId, data.delta); // 將文字片段加入 UI
  });

  eventSource.addEventListener('TextMessageEnd', (e) => {
    const data = JSON.parse(e.data);
    finalizeMessage(data.messageId); // 結束游標閃爍等
  });

  // 3. 工具調用生命週期
  eventSource.addEventListener('ToolCallStart', (e) => {
    const data = JSON.parse(e.data);
    showToolIndicator(data.toolCallName);
  });
  
  // 略過 Args 與 End，直接處理結果，或可做進階顯示
  
  eventSource.addEventListener('ToolCallResult', (e) => {
    const data = JSON.parse(e.data);
    updateToolResult(data.toolCallId, data.result);
  });

  // 4. 運行結束
  eventSource.addEventListener('RunFinished', (e) => {
    setLoading(false);
    eventSource.close();
  });

  // 5. 錯誤處理
  eventSource.addEventListener('RunError', (e) => {
    const data = JSON.parse(e.data);
    showErrorAlert(`Error (${data.code}): ${data.message}`);
    setLoading(false);
    eventSource.close();
  });
}

