'use client';

import { useState } from 'react';

interface Agent {
  name: string;
  llm_id: string | null;
  description: string;
  status: 'Active' | 'Draft' | 'Retired' | 'Unbound';
  tools: string[];
}

const initialAgents: Agent[] = [
  { name: 'MathGuru', llm_id: 'gpt-4o', description: '專精數學計算的助手', status: 'Active', tools: ['Calculator'] },
  { name: 'CodeHelper', llm_id: 'claude-3-opus', description: '程式碼撰寫與除錯助手', status: 'Active', tools: ['CodeRunner', 'WebSearch'] },
  { name: 'Generic Helper', llm_id: null, description: '通用助手 (未綁定模型)', status: 'Unbound', tools: [] },
];

export default function AgentsPage() {
  const [agents, setAgents] = useState<Agent[]>(initialAgents);
  const [showModal, setShowModal] = useState(false);
  const [alert, setAlert] = useState<{ type: 'success' | 'error'; message: string } | null>(null);
  const [formData, setFormData] = useState({
    name: '',
    llm_id: '',
    description: '',
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    
    const newAgent: Agent = {
      name: formData.name,
      llm_id: formData.llm_id || null,
      description: formData.description,
      status: formData.llm_id ? 'Draft' : 'Unbound',
      tools: [],
    };
    
    setAgents([...agents, newAgent]);
    setShowModal(false);
    setFormData({ name: '', llm_id: '', description: '' });
    setAlert({ type: 'success', message: 'Agent 建立成功！' });
    
    setTimeout(() => setAlert(null), 3000);
  };

  const getStatusBadge = (status: Agent['status']) => {
    const classes = {
      Active: 'badge-success',
      Draft: 'badge-warning',
      Retired: 'badge-danger',
      Unbound: 'badge-warning',
    };
    return <span className={`badge ${classes[status]}`}>{status}</span>;
  };

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold">Agent 管理</h1>
          <p className="text-[var(--muted)]">建立與配置 AI Agent</p>
        </div>
        <button className="btn btn-primary" onClick={() => setShowModal(true)}>
          新增 Agent
        </button>
      </div>

      {alert && (
        <div role="alert" className={`alert-${alert.type}`}>
          {alert.message}
        </div>
      )}

      <div className="card">
        <table className="table">
          <thead>
            <tr>
              <th>名稱</th>
              <th>描述</th>
              <th>綁定模型</th>
              <th>狀態</th>
              <th>工具</th>
            </tr>
          </thead>
          <tbody>
            {agents.map((agent) => (
              <tr key={agent.name}>
                <td className="font-medium">{agent.name}</td>
                <td className="text-[var(--muted)]">{agent.description}</td>
                <td>{agent.llm_id || <span className="text-[var(--muted)]">未綁定</span>}</td>
                <td>{getStatusBadge(agent.status)}</td>
                <td>
                  {agent.tools.length > 0 
                    ? agent.tools.join(', ') 
                    : <span className="text-[var(--muted)]">-</span>
                  }
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Modal */}
      {showModal && (
        <div className="modal-overlay" onClick={() => setShowModal(false)}>
          <div className="modal-content" onClick={(e) => e.stopPropagation()}>
            <h2 className="text-xl font-bold mb-4">新增 Agent</h2>
            <form onSubmit={handleSubmit}>
              <div className="mb-4">
                <label htmlFor="name" className="form-label">名稱</label>
                <input
                  type="text"
                  id="name"
                  className="form-input"
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  required
                />
              </div>
              <div className="mb-4">
                <label htmlFor="description" className="form-label">描述</label>
                <input
                  type="text"
                  id="description"
                  className="form-input"
                  value={formData.description}
                  onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                />
              </div>
              <div className="mb-6">
                <label htmlFor="llm_id" className="form-label">綁定模型 (選填)</label>
                <select
                  id="llm_id"
                  className="form-input"
                  value={formData.llm_id}
                  onChange={(e) => setFormData({ ...formData, llm_id: e.target.value })}
                >
                  <option value="">不綁定</option>
                  <option value="gpt-4o">gpt-4o</option>
                  <option value="claude-3-opus">claude-3-opus</option>
                  <option value="gpt-3.5-turbo">gpt-3.5-turbo</option>
                </select>
              </div>
              <div className="flex gap-3 justify-end">
                <button type="button" className="btn btn-secondary" onClick={() => setShowModal(false)}>
                  取消
                </button>
                <button type="submit" className="btn btn-primary">
                  儲存
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
