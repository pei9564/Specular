'use client';

import { useState, useRef, useEffect } from 'react';
import { useAGUI } from '@/hooks/useAGUI';

export default function AGUIChatPage() {
  const [input, setInput] = useState('');
  const [error, setError] = useState<string | null>(null);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  const { 
    messages, 
    pendingToolCalls, 
    isLoading, 
    sendMessage, 
    approveToolCall,
    rejectToolCall,
    clearMessages 
  } = useAGUI({
    model: 'llama3.1:latest',
    onError: (err) => setError(err),
  });

  // 自動滾動到底部
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages, pendingToolCalls]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!input.trim() || isLoading) return;
    
    setError(null);
    const message = input;
    setInput('');
    await sendMessage(message);
  };

  // 取得待確認的 tool calls
  const pendingApprovals = pendingToolCalls.filter(tc => tc.status === 'pending');

  return (
    <div className="h-[calc(100vh-4rem)] flex flex-col">
      {/* Header */}
      <div className="mb-4 flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-bold">AG-UI Chat</h1>
          <p className="text-[var(--muted)]">原生 AG-UI Protocol + Ollama (llama3.1) + HIL</p>
        </div>
        <button onClick={clearMessages} className="btn btn-secondary text-sm">
          🗑️ 清除
        </button>
      </div>

      {/* Error Banner */}
      {error && (
        <div className="mb-4 p-3 bg-red-900/20 border border-red-600 rounded-lg text-sm text-red-400">
          ❌ {error}
          <button onClick={() => setError(null)} className="ml-2 underline">關閉</button>
        </div>
      )}

      {/* Messages */}
      <div className="flex-1 overflow-y-auto border border-[var(--border)] rounded-lg p-4 mb-4 bg-[var(--card)]">
        {messages.length === 0 ? (
          <div className="text-center text-[var(--muted)] py-8">
            <p className="text-4xl mb-4">🤖</p>
            <p>你好！我是本地 AI 助手 (llama3.1)</p>
            <p className="text-sm mt-2">試試：「台北今天天氣如何？」或「計算 123 * 456」</p>
          </div>
        ) : (
          messages.map((msg) => (
            <div
              key={msg.id}
              className={`mb-4 ${msg.role === 'user' ? 'text-right' : ''}`}
            >
              <div
                className={`inline-block max-w-[80%] px-4 py-2 rounded-lg ${
                  msg.role === 'user'
                    ? 'bg-blue-600 text-white'
                    : msg.role === 'tool'
                    ? 'bg-green-900/30 border border-green-600'
                    : msg.role === 'system'
                    ? 'bg-yellow-900/30 border border-yellow-600 text-sm'
                    : 'bg-[var(--background)] border border-[var(--border)]'
                }`}
              >
                {msg.role === 'tool' && (
                  <div className="text-xs text-green-400 mb-1">🔧 工具執行結果</div>
                )}
                <p className="whitespace-pre-wrap">{msg.content}</p>
              </div>
            </div>
          ))
        )}

        {/* Pending Tool Call Approval UI */}
        {pendingApprovals.map((tc) => (
          <div key={tc.toolCallId} className="mb-4 p-4 bg-yellow-900/20 border border-yellow-500 rounded-lg">
            <div className="flex items-center gap-2 mb-2">
              <span className="text-xl">🔧</span>
              <span className="font-bold">工具執行確認</span>
              <span className="badge badge-warning text-xs">需要確認</span>
            </div>
            <div className="mb-3 text-sm">
              <p><strong>工具：</strong>{tc.toolName}</p>
              <p><strong>參數：</strong></p>
              <pre className="mt-1 p-2 bg-black/30 rounded text-xs overflow-x-auto">
                {JSON.stringify(tc.args, null, 2)}
              </pre>
            </div>
            <div className="flex gap-2">
              <button
                onClick={() => approveToolCall(tc.toolCallId)}
                disabled={isLoading}
                className="btn btn-primary text-sm"
              >
                ✅ 確認執行
              </button>
              <button
                onClick={() => rejectToolCall(tc.toolCallId)}
                disabled={isLoading}
                className="btn btn-secondary text-sm"
              >
                ❌ 拒絕
              </button>
            </div>
          </div>
        ))}

        {isLoading && messages[messages.length - 1]?.role !== 'assistant' && pendingApprovals.length === 0 && (
          <div className="mb-4">
            <div className="inline-block px-4 py-2 rounded-lg bg-[var(--background)] border border-[var(--border)]">
              <span className="animate-pulse">思考中...</span>
            </div>
          </div>
        )}
        <div ref={messagesEndRef} />
      </div>

      {/* Input */}
      <form onSubmit={handleSubmit} className="flex gap-2">
        <input
          type="text"
          value={input}
          onChange={(e) => setInput(e.target.value)}
          placeholder="輸入訊息...（試試：台北天氣、計算 2+2）"
          className="input flex-1"
          disabled={isLoading}
        />
        <button
          type="submit"
          className="btn btn-primary"
          disabled={!input.trim() || isLoading}
        >
          發送 →
        </button>
      </form>
    </div>
  );
}
