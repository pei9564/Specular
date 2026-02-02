'use client';

import { CopilotChat } from '@copilotkit/react-ui';
import { useCopilotAction, useCopilotReadable } from '@copilotkit/react-core';
import { useState } from 'react';

// 模擬 Agent 資料
const mockAgents = [
  { name: 'MathGuru', llm_id: 'gpt-4o', tools: ['Calculator', 'PlotGraph'] },
  { name: 'CodeHelper', llm_id: 'claude-3-opus', tools: ['CodeRunner', 'FileManager'] },
  { name: 'DataAnalyst', llm_id: 'gpt-4o', tools: ['DatabaseQuery', 'ChartGenerator'] },
];

export default function CopilotChatPage() {
  const [selectedAgent, setSelectedAgent] = useState<string | null>(null);
  const [lastToolResult, setLastToolResult] = useState<string | null>(null);

  // 讓 AI 可以讀取當前可用的 Agents
  useCopilotReadable({
    description: '目前系統中可用的 AI Agents 列表',
    value: mockAgents,
  });

  // 讓 AI 可以讀取當前選擇的 Agent
  useCopilotReadable({
    description: '目前選擇的 Agent',
    value: selectedAgent,
  });

  // Action 1: 查詢 Agent 資訊
  useCopilotAction({
    name: 'get_agent_info',
    description: '查詢特定 Agent 的詳細資訊',
    parameters: [
      { name: 'agent_name', type: 'string', description: 'Agent 名稱', required: true },
    ],
    handler: async ({ agent_name }) => {
      const agent = mockAgents.find(a => a.name.toLowerCase() === agent_name.toLowerCase());
      if (agent) {
        return `Agent "${agent.name}":\n- 模型: ${agent.llm_id}\n- 工具: ${agent.tools.join(', ')}`;
      }
      return `找不到名為 "${agent_name}" 的 Agent`;
    },
  });

  // Action 2: 選擇 Agent
  useCopilotAction({
    name: 'select_agent',
    description: '選擇一個 Agent 進行後續操作',
    parameters: [
      { name: 'agent_name', type: 'string', description: 'Agent 名稱', required: true },
    ],
    handler: async ({ agent_name }) => {
      const agent = mockAgents.find(a => a.name.toLowerCase() === agent_name.toLowerCase());
      if (agent) {
        setSelectedAgent(agent.name);
        return `已選擇 Agent: ${agent.name}\n模型: ${agent.llm_id}\n可用工具: ${agent.tools.join(', ')}`;
      }
      return `找不到名為 "${agent_name}" 的 Agent`;
    },
  });

  // Action 3: 執行 Tool
  useCopilotAction({
    name: 'execute_tool',
    description: '執行指定的工具（如 Calculator, CodeRunner 等）',
    parameters: [
      { name: 'tool_name', type: 'string', description: '工具名稱', required: true },
      { name: 'input', type: 'string', description: '工具輸入', required: true },
    ],
    handler: async ({ tool_name, input }) => {
      // 模擬工具執行
      const result = `工具 "${tool_name}" 執行完成\n輸入: ${input}\n結果: 操作成功 ✅`;
      setLastToolResult(result);
      return result;
    },
  });

  // Action 4: 列出所有 Agent
  useCopilotAction({
    name: 'list_agents',
    description: '列出所有可用的 AI Agents',
    parameters: [],
    handler: async () => {
      const list = mockAgents.map(a => `• ${a.name} (${a.llm_id})`).join('\n');
      return `可用的 Agents:\n${list}`;
    },
  });

  return (
    <div className="h-[calc(100vh-4rem)]">
      <div className="mb-4 flex justify-between items-start">
        <div>
          <h1 className="text-2xl font-bold">CopilotKit Chat</h1>
          <p className="text-[var(--muted)]">AG-UI 整合測試頁面</p>
        </div>
        <div className="flex gap-2">
          {selectedAgent && (
            <div className="badge badge-success">
              Agent: {selectedAgent}
            </div>
          )}
        </div>
      </div>
      
      {lastToolResult && (
        <div className="mb-4 p-3 bg-green-900/20 border border-green-600 rounded-lg text-sm">
          <strong>最近執行結果:</strong>
          <pre className="mt-1 text-xs">{lastToolResult}</pre>
        </div>
      )}
      
      <div className="h-[calc(100%-6rem)] rounded-lg overflow-hidden border border-[var(--border)]">
        <CopilotChat
          labels={{
            title: 'Specular AI Assistant',
            initial: '你好！我是 Specular AI 助手。\n\n你可以：\n• 問我有哪些 Agent 可用\n• 選擇一個 Agent\n• 執行工具操作\n\n需要我幫你做什麼？',
            placeholder: '輸入訊息...',
          }}
          className="h-full"
        />
      </div>
    </div>
  );
}


