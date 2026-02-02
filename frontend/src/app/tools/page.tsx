'use client';

import { useState } from 'react';

interface Tool {
  name: string;
  capabilities: string[];
}

const initialTools: Tool[] = [
  { name: 'Calculator', capabilities: ['math', 'calculation'] },
  { name: 'WebSearch', capabilities: ['search', 'web'] },
  { name: 'CodeRunner', capabilities: ['code', 'execution'] },
];

export default function ToolsPage() {
  const [tools] = useState<Tool[]>(initialTools);

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold">Tool 管理</h1>
          <p className="text-[var(--muted)]">管理 Agent 可使用的工具</p>
        </div>
        <button className="btn btn-primary">
          新增 Tool
        </button>
      </div>

      <div className="card">
        <table className="table">
          <thead>
            <tr>
              <th>名稱</th>
              <th>能力標籤</th>
            </tr>
          </thead>
          <tbody>
            {tools.map((tool) => (
              <tr key={tool.name}>
                <td className="font-medium">{tool.name}</td>
                <td>
                  <div className="flex gap-2">
                    {tool.capabilities.map((cap) => (
                      <span key={cap} className="badge badge-success">{cap}</span>
                    ))}
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
