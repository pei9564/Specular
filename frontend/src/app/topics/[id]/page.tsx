'use client';

import { useState, useRef, useEffect } from 'react';
import { useParams, useRouter } from 'next/navigation';
import Link from 'next/link';

interface Message {
  id: string;
  role: 'user' | 'assistant' | 'system';
  content: string;
  timestamp: string;
}

interface TopicConfig {
  topic_id: string;
  agent_id: string | null;
  llm_id: string;
  stm_setting: number;
}

// Mock data
const mockTopics: Record<string, TopicConfig> = {
  't_001': { topic_id: 't_001', agent_id: 'MathGuru', llm_id: 'gpt-4o', stm_setting: 10 },
  't_002': { topic_id: 't_002', agent_id: 'CodeHelper', llm_id: 'claude-3-opus', stm_setting: 5 },
  't_003': { topic_id: 't_003', agent_id: null, llm_id: 'gpt-3.5-turbo', stm_setting: 0 },
};

const mockMessages: Record<string, Message[]> = {
  't_001': [
    { id: 'm1', role: 'user', content: '請幫我計算 123 * 456', timestamp: '14:30:15' },
    { id: 'm2', role: 'assistant', content: '123 × 456 = 56,088\n\n計算過程：\n- 123 × 400 = 49,200\n- 123 × 56 = 6,888\n- 49,200 + 6,888 = 56,088', timestamp: '14:30:18' },
    { id: 'm3', role: 'user', content: '那 56088 / 12 呢？', timestamp: '14:31:00' },
    { id: 'm4', role: 'assistant', content: '56,088 ÷ 12 = 4,674\n\n這是一個整除的結果。', timestamp: '14:31:02' },
  ],
  't_002': [
    { id: 'm1', role: 'user', content: '用 Python 寫一個 bubble sort', timestamp: '13:15:00' },
    { id: 'm2', role: 'assistant', content: '```python\ndef bubble_sort(arr):\n    n = len(arr)\n    for i in range(n):\n        for j in range(0, n-i-1):\n            if arr[j] > arr[j+1]:\n                arr[j], arr[j+1] = arr[j+1], arr[j]\n    return arr\n\n# 使用範例\nprint(bubble_sort([64, 34, 25, 12, 22, 11, 90]))\n```', timestamp: '13:15:05' },
  ],
  't_003': [],
};

export default function TopicChatPage() {
  const params = useParams();
  const router = useRouter();
  const topicId = params.id as string;
  
  const topic = mockTopics[topicId];
  const [messages, setMessages] = useState<Message[]>(mockMessages[topicId] || []);
  const [input, setInput] = useState('');
  const [isStreaming, setIsStreaming] = useState(false);
  const [showSettings, setShowSettings] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  if (!topic) {
    return (
      <div className="flex flex-col items-center justify-center h-[60vh]">
        <p className="text-[var(--muted)] mb-4">找不到此 Topic</p>
        <Link href="/topics" className="btn btn-primary">返回列表</Link>
      </div>
    );
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!input.trim() || isStreaming) return;

    const userMessage: Message = {
      id: `m${Date.now()}`,
      role: 'user',
      content: input,
      timestamp: new Date().toLocaleTimeString('zh-TW', { hour: '2-digit', minute: '2-digit', second: '2-digit' }),
    };
    
    setMessages(prev => [...prev, userMessage]);
    setInput('');
    setIsStreaming(true);

    // Simulate streaming response
    const assistantMessage: Message = {
      id: `m${Date.now() + 1}`,
      role: 'assistant',
      content: '',
      timestamp: new Date().toLocaleTimeString('zh-TW', { hour: '2-digit', minute: '2-digit', second: '2-digit' }),
    };
    
    setMessages(prev => [...prev, assistantMessage]);

    // Mock streaming effect
    const mockResponse = `這是一個模擬的 AI 回應。\n\n您的訊息是：「${input}」\n\n目前使用的模型是 ${topic.llm_id}，STM 設定為 ${topic.stm_setting}。`;
    
    for (let i = 0; i <= mockResponse.length; i++) {
      await new Promise(resolve => setTimeout(resolve, 20));
      setMessages(prev => {
        const updated = [...prev];
        updated[updated.length - 1] = {
          ...updated[updated.length - 1],
          content: mockResponse.slice(0, i),
        };
        return updated;
      });
    }
    
    setIsStreaming(false);
  };

  const handleClearHistory = () => {
    if (confirm('確定要清除對話歷史嗎？這將開啟一個新的 Session。')) {
      setMessages([]);
    }
  };

  return (
    <div className="flex flex-col h-[calc(100vh-4rem)]">
      {/* Header */}
      <div className="flex items-center justify-between pb-4 border-b border-[var(--border)]">
        <div className="flex items-center gap-4">
          <Link href="/topics" className="text-[var(--muted)] hover:text-white">
            ← 返回
          </Link>
          <div>
            <div className="flex items-center gap-2">
              <h1 className="text-xl font-bold">{topic.topic_id}</h1>
              {topic.agent_id ? (
                <span className="badge badge-success">{topic.agent_id}</span>
              ) : (
                <span className="badge badge-warning">Raw Mode</span>
              )}
            </div>
            <div className="text-sm text-[var(--muted)]">
              {topic.llm_id} · STM: {topic.stm_setting}
            </div>
          </div>
        </div>
        <div className="flex gap-2">
          <button 
            className="btn btn-secondary"
            onClick={() => setShowSettings(!showSettings)}
          >
            ⚙️ 設定
          </button>
          <button 
            className="btn btn-secondary"
            onClick={handleClearHistory}
          >
            🗑️ 清除歷史
          </button>
        </div>
      </div>

      {/* Settings Panel */}
      {showSettings && (
        <div className="p-4 bg-[var(--secondary)] border-b border-[var(--border)]">
          <div className="grid grid-cols-3 gap-4">
            <div>
              <label className="form-label">模型</label>
              <select className="form-input" defaultValue={topic.llm_id}>
                <option value="gpt-4o">gpt-4o</option>
                <option value="claude-3-opus">claude-3-opus</option>
                <option value="gpt-3.5-turbo">gpt-3.5-turbo</option>
              </select>
            </div>
            <div>
              <label className="form-label">STM (短期記憶)</label>
              <input type="number" className="form-input" defaultValue={topic.stm_setting} min="0" max="100" />
            </div>
            <div className="flex items-end">
              <button className="btn btn-primary">儲存設定</button>
            </div>
          </div>
        </div>
      )}

      {/* Messages */}
      <div className="flex-1 overflow-y-auto py-4 space-y-4">
        {messages.length === 0 ? (
          <div className="flex items-center justify-center h-full text-[var(--muted)]">
            開始新的對話...
          </div>
        ) : (
          messages.map((message) => (
            <div
              key={message.id}
              className={`flex ${message.role === 'user' ? 'justify-end' : 'justify-start'}`}
            >
              <div
                className={`max-w-[70%] rounded-lg p-4 ${
                  message.role === 'user'
                    ? 'bg-[var(--primary)] text-white'
                    : 'bg-[var(--secondary)] border border-[var(--border)]'
                }`}
              >
                <div className="whitespace-pre-wrap">{message.content}</div>
                <div className={`text-xs mt-2 ${message.role === 'user' ? 'text-blue-200' : 'text-[var(--muted)]'}`}>
                  {message.timestamp}
                </div>
              </div>
            </div>
          ))
        )}
        <div ref={messagesEndRef} />
      </div>

      {/* Input */}
      <form onSubmit={handleSubmit} className="pt-4 border-t border-[var(--border)]">
        <div className="flex gap-2">
          <input
            type="text"
            className="form-input flex-1"
            placeholder="輸入訊息..."
            value={input}
            onChange={(e) => setInput(e.target.value)}
            disabled={isStreaming}
          />
          <button
            type="submit"
            className="btn btn-primary"
            disabled={isStreaming || !input.trim()}
          >
            {isStreaming ? '⏳' : '發送'}
          </button>
        </div>
      </form>
    </div>
  );
}
