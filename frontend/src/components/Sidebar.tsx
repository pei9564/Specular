'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';

const navItems = [
  { href: '/', label: '首頁', icon: '🏠' },
  { href: '/topics', label: '對話主題', icon: '💬' },
  { href: '/agui', label: 'AG-UI Chat', icon: '🚀' },
  { href: '/copilot', label: 'Copilot Chat', icon: '🤖' },
  { href: '/history', label: '歷史查詢', icon: '📜' },
  { href: '/llms', label: 'LLM 管理', icon: '⚙️' },
  { href: '/agents', label: 'Agent 管理', icon: '🎯' },
  { href: '/tools', label: 'Tool 管理', icon: '🔧' },
];

export default function Sidebar() {
  const pathname = usePathname();

  return (
    <aside className="sidebar w-64 min-h-screen p-4">
      <div className="mb-8">
        <h1 className="text-xl font-bold text-white">Specular AI</h1>
        <p className="text-sm text-[var(--muted)]">管理控制台</p>
      </div>
      <nav className="space-y-1">
        {navItems.map((item) => (
          <Link
            key={item.href}
            href={item.href}
            className={`sidebar-link ${pathname === item.href ? 'active' : ''}`}
          >
            <span>{item.icon}</span>
            <span>{item.label}</span>
          </Link>
        ))}
      </nav>
    </aside>
  );
}
