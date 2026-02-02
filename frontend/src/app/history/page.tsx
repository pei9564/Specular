'use client';

import { useState, useMemo } from 'react';
import Link from 'next/link';

interface ChatMessage {
  id: string;
  topic_id: string;
  session_id: string;
  role: 'user' | 'assistant' | 'system';
  content: string;
  timestamp: string;
  token_count: number;
}

interface Topic {
  topic_id: string;
  agent_id: string | null;
  llm_id: string;
}

// Mock data for demonstration
const mockTopics: Topic[] = [
  { topic_id: 't_001', agent_id: 'MathGuru', llm_id: 'gpt-4o' },
  { topic_id: 't_002', agent_id: 'CodeHelper', llm_id: 'claude-3-opus' },
  { topic_id: 't_003', agent_id: null, llm_id: 'gpt-3.5-turbo' },
];

const mockMessages: ChatMessage[] = [
  { id: 'm1', topic_id: 't_001', session_id: 's_1', role: 'user', content: '請幫我計算 123 * 456', timestamp: '2026-02-02 14:30:15', token_count: 12 },
  { id: 'm2', topic_id: 't_001', session_id: 's_1', role: 'assistant', content: '123 × 456 = 56,088\n\n計算過程：\n- 123 × 400 = 49,200\n- 123 × 56 = 6,888\n- 49,200 + 6,888 = 56,088', timestamp: '2026-02-02 14:30:18', token_count: 58 },
  { id: 'm3', topic_id: 't_001', session_id: 's_1', role: 'user', content: '那 56088 / 12 呢？', timestamp: '2026-02-02 14:31:00', token_count: 10 },
  { id: 'm4', topic_id: 't_001', session_id: 's_1', role: 'assistant', content: '56,088 ÷ 12 = 4,674\n\n這是一個整除的結果。', timestamp: '2026-02-02 14:31:02', token_count: 25 },
  { id: 'm5', topic_id: 't_002', session_id: 's_2', role: 'user', content: '用 Python 寫一個 bubble sort', timestamp: '2026-02-02 13:15:00', token_count: 15 },
  { id: 'm6', topic_id: 't_002', session_id: 's_2', role: 'assistant', content: '```python\ndef bubble_sort(arr):\n    n = len(arr)\n    for i in range(n):\n        for j in range(0, n-i-1):\n            if arr[j] > arr[j+1]:\n                arr[j], arr[j+1] = arr[j+1], arr[j]\n    return arr\n```', timestamp: '2026-02-02 13:15:05', token_count: 85 },
  { id: 'm7', topic_id: 't_002', session_id: 's_2', role: 'user', content: '可以加上時間複雜度的說明嗎？', timestamp: '2026-02-02 13:16:00', token_count: 18 },
  { id: 'm8', topic_id: 't_002', session_id: 's_2', role: 'assistant', content: 'Bubble Sort 的時間複雜度：\n- 最佳情況：O(n) - 已排序的陣列\n- 平均情況：O(n²)\n- 最差情況：O(n²)\n\n空間複雜度：O(1) - 原地排序', timestamp: '2026-02-02 13:16:08', token_count: 65 },
  { id: 'm9', topic_id: 't_003', session_id: 's_3', role: 'user', content: '什麼是機器學習？', timestamp: '2026-02-01 10:00:00', token_count: 8 },
  { id: 'm10', topic_id: 't_003', session_id: 's_3', role: 'assistant', content: '機器學習是人工智慧的一個分支，讓電腦系統能夠從數據中學習和改進，而無需明確編程。', timestamp: '2026-02-01 10:00:15', token_count: 42 },
];

export default function HistoryPage() {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedTopic, setSelectedTopic] = useState<string>('all');
  const [selectedRole, setSelectedRole] = useState<string>('all');
  const [dateFrom, setDateFrom] = useState('');
  const [dateTo, setDateTo] = useState('');

  const filteredMessages = useMemo(() => {
    return mockMessages.filter((msg) => {
      // Text search
      if (searchQuery && !msg.content.toLowerCase().includes(searchQuery.toLowerCase())) {
        return false;
      }
      // Topic filter
      if (selectedTopic !== 'all' && msg.topic_id !== selectedTopic) {
        return false;
      }
      // Role filter
      if (selectedRole !== 'all' && msg.role !== selectedRole) {
        return false;
      }
      // Date filter
      if (dateFrom && msg.timestamp < dateFrom) {
        return false;
      }
      if (dateTo && msg.timestamp > dateTo + ' 23:59:59') {
        return false;
      }
      return true;
    });
  }, [searchQuery, selectedTopic, selectedRole, dateFrom, dateTo]);

  const totalTokens = useMemo(() => {
    return filteredMessages.reduce((sum, msg) => sum + msg.token_count, 0);
  }, [filteredMessages]);

  const getTopic = (topicId: string) => mockTopics.find(t => t.topic_id === topicId);

  return (
    <div>
      <div className="mb-6">
        <h1 className="text-2xl font-bold">歷史查詢</h1>
        <p className="text-[var(--muted)]">搜尋與瀏覽對話歷史紀錄</p>
      </div>

      {/* Search & Filters */}
      <div className="card mb-6">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4">
          <div className="lg:col-span-2">
            <label htmlFor="search" className="form-label">關鍵字搜尋</label>
            <input
              type="text"
              id="search"
              className="form-input"
              placeholder="搜尋訊息內容..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
          </div>
          <div>
            <label htmlFor="topic" className="form-label">Topic</label>
            <select
              id="topic"
              className="form-input"
              value={selectedTopic}
              onChange={(e) => setSelectedTopic(e.target.value)}
            >
              <option value="all">全部</option>
              {mockTopics.map((topic) => (
                <option key={topic.topic_id} value={topic.topic_id}>
                  {topic.topic_id} ({topic.agent_id || 'Raw'})
                </option>
              ))}
            </select>
          </div>
          <div>
            <label htmlFor="role" className="form-label">角色</label>
            <select
              id="role"
              className="form-input"
              value={selectedRole}
              onChange={(e) => setSelectedRole(e.target.value)}
            >
              <option value="all">全部</option>
              <option value="user">使用者</option>
              <option value="assistant">AI</option>
            </select>
          </div>
          <div>
            <label htmlFor="dateFrom" className="form-label">起始日期</label>
            <input
              type="date"
              id="dateFrom"
              className="form-input"
              value={dateFrom}
              onChange={(e) => setDateFrom(e.target.value)}
            />
          </div>
        </div>
      </div>

      {/* Stats */}
      <div className="flex gap-4 mb-4 text-sm text-[var(--muted)]">
        <span>找到 {filteredMessages.length} 則訊息</span>
        <span>|</span>
        <span>總 Token 數: {totalTokens.toLocaleString()}</span>
      </div>

      {/* Results */}
      <div className="space-y-3">
        {filteredMessages.length === 0 ? (
          <div className="card text-center text-[var(--muted)] py-12">
            沒有找到符合條件的訊息
          </div>
        ) : (
          filteredMessages.map((msg) => {
            const topic = getTopic(msg.topic_id);
            return (
              <div key={msg.id} className="card hover:border-[var(--primary)] transition-colors">
                <div className="flex items-start justify-between gap-4">
                  <div className="flex-1">
                    <div className="flex items-center gap-2 mb-2">
                      <span className={`badge ${msg.role === 'user' ? 'badge-success' : 'badge-warning'}`}>
                        {msg.role === 'user' ? '👤 User' : '🤖 AI'}
                      </span>
                      <Link href={`/topics/${msg.topic_id}`} className="text-[var(--primary)] text-sm hover:underline">
                        {msg.topic_id}
                      </Link>
                      {topic?.agent_id && (
                        <span className="text-xs text-[var(--muted)]">({topic.agent_id})</span>
                      )}
                    </div>
                    <div className="text-sm whitespace-pre-wrap line-clamp-3">
                      {msg.content}
                    </div>
                  </div>
                  <div className="text-right text-xs text-[var(--muted)] shrink-0">
                    <div>{msg.timestamp}</div>
                    <div>{msg.token_count} tokens</div>
                  </div>
                </div>
              </div>
            );
          })
        )}
      </div>
    </div>
  );
}
