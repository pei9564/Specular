export default function HomePage() {
  return (
    <div>
      <h1 className="text-2xl font-bold mb-2">歡迎使用 Specular AI</h1>
      <p className="text-[var(--muted)] mb-8">AI Agent 配置與管理平台</p>
      
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="card">
          <div className="text-3xl mb-2">🤖</div>
          <h2 className="text-lg font-semibold mb-1">LLM 管理</h2>
          <p className="text-sm text-[var(--muted)]">管理語言模型配置與權限</p>
        </div>
        <div className="card">
          <div className="text-3xl mb-2">🎯</div>
          <h2 className="text-lg font-semibold mb-1">Agent 管理</h2>
          <p className="text-sm text-[var(--muted)]">建立與配置 AI Agent</p>
        </div>
        <div className="card">
          <div className="text-3xl mb-2">🔧</div>
          <h2 className="text-lg font-semibold mb-1">Tool 管理</h2>
          <p className="text-sm text-[var(--muted)]">管理 Agent 可使用的工具</p>
        </div>
      </div>
    </div>
  );
}
