'use client';

import { useState } from 'react';

interface LLM {
  model_id: string;
  provider: string;
  status: 'Active' | 'Draft' | 'Deprecated';
  context_window: number;
  access_level: 'Public' | 'Admin-Only';
}

const initialLLMs: LLM[] = [
  { model_id: 'gpt-4o', provider: 'OpenAI', status: 'Active', context_window: 128000, access_level: 'Public' },
  { model_id: 'claude-3-opus', provider: 'Anthropic', status: 'Active', context_window: 200000, access_level: 'Admin-Only' },
  { model_id: 'gpt-3.5-turbo', provider: 'OpenAI', status: 'Deprecated', context_window: 16000, access_level: 'Public' },
];

export default function LLMsPage() {
  const [llms, setLlms] = useState<LLM[]>(initialLLMs);
  const [showModal, setShowModal] = useState(false);
  const [alert, setAlert] = useState<{ type: 'success' | 'error'; message: string } | null>(null);
  const [formData, setFormData] = useState({
    model_id: '',
    provider: '',
    context_window: 128000,
    access_level: 'Public' as const,
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    
    const newLLM: LLM = {
      ...formData,
      status: 'Draft',
    };
    
    setLlms([...llms, newLLM]);
    setShowModal(false);
    setFormData({ model_id: '', provider: '', context_window: 128000, access_level: 'Public' });
    setAlert({ type: 'success', message: 'LLM 新增成功！' });
    
    setTimeout(() => setAlert(null), 3000);
  };

  const getStatusBadge = (status: LLM['status']) => {
    const classes = {
      Active: 'badge-success',
      Draft: 'badge-warning',
      Deprecated: 'badge-danger',
    };
    return <span className={`badge ${classes[status]}`}>{status}</span>;
  };

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold">LLM 管理</h1>
          <p className="text-[var(--muted)]">管理系統中的語言模型配置</p>
        </div>
        <button className="btn btn-primary" onClick={() => setShowModal(true)}>
          新增 LLM
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
              <th>模型 ID</th>
              <th>供應商</th>
              <th>狀態</th>
              <th>Context Window</th>
              <th>存取權限</th>
            </tr>
          </thead>
          <tbody>
            {llms.map((llm) => (
              <tr key={llm.model_id}>
                <td className="font-medium">{llm.model_id}</td>
                <td>{llm.provider}</td>
                <td>{getStatusBadge(llm.status)}</td>
                <td>{llm.context_window.toLocaleString()}</td>
                <td>{llm.access_level}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Modal */}
      {showModal && (
        <div className="modal-overlay" onClick={() => setShowModal(false)}>
          <div className="modal-content" onClick={(e) => e.stopPropagation()}>
            <h2 className="text-xl font-bold mb-4">新增 LLM</h2>
            <form onSubmit={handleSubmit}>
              <div className="mb-4">
                <label htmlFor="model_id" className="form-label">模型 ID</label>
                <input
                  type="text"
                  id="model_id"
                  className="form-input"
                  value={formData.model_id}
                  onChange={(e) => setFormData({ ...formData, model_id: e.target.value })}
                  required
                />
              </div>
              <div className="mb-4">
                <label htmlFor="provider" className="form-label">供應商</label>
                <input
                  type="text"
                  id="provider"
                  className="form-input"
                  value={formData.provider}
                  onChange={(e) => setFormData({ ...formData, provider: e.target.value })}
                  required
                />
              </div>
              <div className="mb-4">
                <label htmlFor="context_window" className="form-label">Context Window</label>
                <input
                  type="number"
                  id="context_window"
                  className="form-input"
                  value={formData.context_window}
                  onChange={(e) => setFormData({ ...formData, context_window: parseInt(e.target.value) })}
                  required
                />
              </div>
              <div className="mb-6">
                <label htmlFor="access_level" className="form-label">存取權限</label>
                <select
                  id="access_level"
                  className="form-input"
                  value={formData.access_level}
                  onChange={(e) => setFormData({ ...formData, access_level: e.target.value as 'Public' | 'Admin-Only' })}
                >
                  <option value="Public">Public</option>
                  <option value="Admin-Only">Admin-Only</option>
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
