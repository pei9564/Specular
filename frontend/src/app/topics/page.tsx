'use client';

import { useState } from 'react';
import Link from 'next/link';

interface Topic {
  topic_id: string;
  agent_id: string | null;
  llm_id: string;
  stm_setting: number;
  created_at: string;
  message_count: number;
}

const initialTopics: Topic[] = [
  { topic_id: 't_001', agent_id: 'MathGuru', llm_id: 'gpt-4o', stm_setting: 10, created_at: '2026-02-02 14:30', message_count: 25 },
  { topic_id: 't_002', agent_id: 'CodeHelper', llm_id: 'claude-3-opus', stm_setting: 5, created_at: '2026-02-02 13:15', message_count: 42 },
  { topic_id: 't_003', agent_id: null, llm_id: 'gpt-3.5-turbo', stm_setting: 0, created_at: '2026-02-01 10:00', message_count: 8 },
];

const availableAgents = [
  { name: 'MathGuru', llm_id: 'gpt-4o' },
  { name: 'CodeHelper', llm_id: 'claude-3-opus' },
  { name: 'Generic Helper', llm_id: null },
];

const availableLLMs = ['gpt-4o', 'claude-3-opus', 'gpt-3.5-turbo'];

export default function TopicsPage() {
  const [topics, setTopics] = useState<Topic[]>(initialTopics);
  const [showModal, setShowModal] = useState(false);
  const [alert, setAlert] = useState<{ type: 'success' | 'error'; message: string } | null>(null);
  const [createMode, setCreateMode] = useState<'agent' | 'raw'>('agent');
  const [formData, setFormData] = useState({
    agent_id: '',
    llm_id: 'gpt-4o',
    stm_setting: 10,
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    
    const newTopic: Topic = {
      topic_id: `t_${String(topics.length + 1).padStart(3, '0')}`,
      agent_id: createMode === 'agent' ? formData.agent_id : null,
      llm_id: createMode === 'agent' 
        ? availableAgents.find(a => a.name === formData.agent_id)?.llm_id || formData.llm_id
        : formData.llm_id,
      stm_setting: formData.stm_setting,
      created_at: new Date().toLocaleString('zh-TW'),
      message_count: 0,
    };
    
    setTopics([newTopic, ...topics]);
    setShowModal(false);
    setFormData({ agent_id: '', llm_id: 'gpt-4o', stm_setting: 10 });
    setAlert({ type: 'success', message: 'Topic 建立成功！' });
    
    setTimeout(() => setAlert(null), 3000);
  };

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold">對話主題</h1>
          <p className="text-[var(--muted)]">管理對話 Topic 與歷史紀錄</p>
        </div>
        <button className="btn btn-primary" onClick={() => setShowModal(true)}>
          新增 Topic
        </button>
      </div>

      {alert && (
        <div role="alert" className={`alert-${alert.type}`}>
          {alert.message}
        </div>
      )}

      <div className="grid gap-4">
        {topics.map((topic) => (
          <Link href={`/topics/${topic.topic_id}`} key={topic.topic_id}>
            <div className="card hover:border-[var(--primary)] transition-colors cursor-pointer">
              <div className="flex items-center justify-between">
                <div>
                  <div className="flex items-center gap-3 mb-2">
                    <span className="text-lg font-semibold">{topic.topic_id}</span>
                    {topic.agent_id ? (
                      <span className="badge badge-success">{topic.agent_id}</span>
                    ) : (
                      <span className="badge badge-warning">Raw Mode</span>
                    )}
                  </div>
                  <div className="flex gap-4 text-sm text-[var(--muted)]">
                    <span>模型: {topic.llm_id}</span>
                    <span>STM: {topic.stm_setting}</span>
                    <span>訊息數: {topic.message_count}</span>
                  </div>
                </div>
                <div className="text-sm text-[var(--muted)]">
                  {topic.created_at}
                </div>
              </div>
            </div>
          </Link>
        ))}
      </div>

      {/* Create Topic Modal */}
      {showModal && (
        <div className="modal-overlay" onClick={() => setShowModal(false)}>
          <div className="modal-content" onClick={(e) => e.stopPropagation()}>
            <h2 className="text-xl font-bold mb-4">新增 Topic</h2>
            
            {/* Mode Selector */}
            <div className="flex gap-2 mb-4">
              <button
                type="button"
                className={`btn flex-1 ${createMode === 'agent' ? 'btn-primary' : 'btn-secondary'}`}
                onClick={() => setCreateMode('agent')}
              >
                從 Agent 建立
              </button>
              <button
                type="button"
                className={`btn flex-1 ${createMode === 'raw' ? 'btn-primary' : 'btn-secondary'}`}
                onClick={() => setCreateMode('raw')}
              >
                直接指定 LLM
              </button>
            </div>

            <form onSubmit={handleSubmit}>
              {createMode === 'agent' ? (
                <div className="mb-4">
                  <label htmlFor="agent_id" className="form-label">選擇 Agent</label>
                  <select
                    id="agent_id"
                    className="form-input"
                    value={formData.agent_id}
                    onChange={(e) => setFormData({ ...formData, agent_id: e.target.value })}
                    required
                  >
                    <option value="">請選擇...</option>
                    {availableAgents.map((agent) => (
                      <option key={agent.name} value={agent.name}>
                        {agent.name} {agent.llm_id ? `(${agent.llm_id})` : '(未綁定)'}
                      </option>
                    ))}
                  </select>
                </div>
              ) : (
                <div className="mb-4">
                  <label htmlFor="llm_id" className="form-label">選擇 LLM</label>
                  <select
                    id="llm_id"
                    className="form-input"
                    value={formData.llm_id}
                    onChange={(e) => setFormData({ ...formData, llm_id: e.target.value })}
                    required
                  >
                    {availableLLMs.map((llm) => (
                      <option key={llm} value={llm}>{llm}</option>
                    ))}
                  </select>
                </div>
              )}

              <div className="mb-6">
                <label htmlFor="stm_setting" className="form-label">
                  短期記憶 (STM) - 保留最近 N 則訊息
                </label>
                <input
                  type="number"
                  id="stm_setting"
                  className="form-input"
                  min="0"
                  max="100"
                  value={formData.stm_setting}
                  onChange={(e) => setFormData({ ...formData, stm_setting: parseInt(e.target.value) })}
                />
                <p className="text-xs text-[var(--muted)] mt-1">
                  設為 0 表示 One-shot 模式（不記憶歷史）
                </p>
              </div>

              <div className="flex gap-3 justify-end">
                <button type="button" className="btn btn-secondary" onClick={() => setShowModal(false)}>
                  取消
                </button>
                <button type="submit" className="btn btn-primary">
                  建立
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
