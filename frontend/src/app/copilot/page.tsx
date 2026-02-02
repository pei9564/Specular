'use client';

import { CopilotChat } from '@copilotkit/react-ui';
import { useCopilotAction } from '@copilotkit/react-core';

export default function CopilotChatPage() {
  // 定義一個需要確認的 Action (Human-in-the-Loop)
  useCopilotAction({
    name: 'execute_calculation',
    description: '執行數學計算',
    parameters: [
      { name: 'expression', type: 'string', description: '數學表達式', required: true },
    ],
    renderAndWait: ({ args, handler }) => (
      <div className="card p-4 my-2 bg-yellow-900/20 border-yellow-600">
        <h3 className="font-bold mb-2">🔧 Tool 確認</h3>
        <p className="text-sm mb-3">
          AI 想要執行計算：<code className="bg-black/30 px-1 rounded">{args.expression}</code>
        </p>
        <div className="flex gap-2">
          <button 
            className="btn btn-primary text-sm"
            onClick={() => handler.proceed()}
          >
            ✅ 確認執行
          </button>
          <button 
            className="btn btn-secondary text-sm"
            onClick={() => handler.cancel()}
          >
            ❌ 取消
          </button>
        </div>
      </div>
    ),
    handler: async ({ expression }) => {
      try {
        // 簡單的數學計算（實際應用中應該調用後端）
        const result = eval(expression);
        return `計算結果：${expression} = ${result}`;
      } catch {
        return `無法計算表達式：${expression}`;
      }
    },
  });

  return (
    <div className="h-[calc(100vh-4rem)]">
      <div className="mb-4">
        <h1 className="text-2xl font-bold">CopilotKit Chat</h1>
        <p className="text-[var(--muted)]">AG-UI 整合測試頁面</p>
      </div>
      
      <div className="h-[calc(100%-4rem)] rounded-lg overflow-hidden border border-[var(--border)]">
        <CopilotChat
          labels={{
            title: 'Specular AI Assistant',
            initial: '你好！我是 Specular AI 助手。有什麼我可以幫助你的嗎？',
            placeholder: '輸入訊息...',
          }}
          className="h-full"
        />
      </div>
    </div>
  );
}
