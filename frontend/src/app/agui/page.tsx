'use client';

import { useState, useRef, useEffect } from 'react';
import { useAGUI } from '@/hooks/useAGUI';

export default function AGUIChatPage() {
    const [input, setInput] = useState('');
    const [error, setError] = useState<string | null>(null);
    const messagesEndRef = useRef<HTMLDivElement>(null);

    const { messages, isLoading, sendMessage, stopGeneration, clearMessages } = useAGUI({
        model: 'llama3.1:latest',
        onError: (err) => setError(err),
    });

    // 自動滾動到底部
    useEffect(() => {
        messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
    }, [messages]);

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!input.trim() || isLoading) return;

        setError(null);
        const message = input;
        setInput('');
        await sendMessage(message);
    };

    return (
        <div className="h-[calc(100vh-4rem)] flex flex-col">
            {/* Header */}
            <div className="mb-4 flex justify-between items-center">
                <div>
                    <h1 className="text-2xl font-bold">AG-UI Chat</h1>
                    <p className="text-[var(--muted)]">原生 AG-UI Protocol + Ollama (llama3.1)</p>
                </div>
                <button
                    onClick={clearMessages}
                    className="btn btn-secondary text-sm"
                >
                    🗑️ 清除對話
                </button>
            </div>

            {/* Error Banner */}
            {error && (
                <div className="mb-4 p-3 bg-red-900/20 border border-red-600 rounded-lg text-sm text-red-400">
                    ❌ {error}
                    <button onClick={() => setError(null)} className="ml-2 underline">關閉</button>
                </div>
            )}

            {/* Messages */}
            <div className="flex-1 overflow-y-auto border border-[var(--border)] rounded-lg p-4 mb-4 bg-[var(--card)]">
                {messages.length === 0 ? (
                    <div className="text-center text-[var(--muted)] py-8">
                        <p className="text-4xl mb-4">🤖</p>
                        <p>你好！我是本地 AI 助手 (llama3.1)</p>
                        <p className="text-sm mt-2">輸入訊息開始對話...</p>
                    </div>
                ) : (
                    messages.map((msg) => (
                        <div
                            key={msg.id}
                            className={`mb-4 ${msg.role === 'user' ? 'text-right' : ''}`}
                        >
                            <div
                                className={`inline-block max-w-[80%] px-4 py-2 rounded-lg ${msg.role === 'user'
                                        ? 'bg-blue-600 text-white'
                                        : 'bg-[var(--background)] border border-[var(--border)]'
                                    }`}
                            >
                                <p className="whitespace-pre-wrap">{msg.content}</p>
                            </div>
                        </div>
                    ))
                )}
                {isLoading && messages[messages.length - 1]?.role !== 'assistant' && (
                    <div className="mb-4">
                        <div className="inline-block px-4 py-2 rounded-lg bg-[var(--background)] border border-[var(--border)]">
                            <span className="animate-pulse">思考中...</span>
                        </div>
                    </div>
                )}
                <div ref={messagesEndRef} />
            </div>

            {/* Input */}
            <form onSubmit={handleSubmit} className="flex gap-2">
                <input
                    type="text"
                    value={input}
                    onChange={(e) => setInput(e.target.value)}
                    placeholder="輸入訊息..."
                    className="input flex-1"
                    disabled={isLoading}
                />
                {isLoading ? (
                    <button
                        type="button"
                        onClick={stopGeneration}
                        className="btn btn-secondary"
                    >
                        ⏹️ 停止
                    </button>
                ) : (
                    <button
                        type="submit"
                        className="btn btn-primary"
                        disabled={!input.trim()}
                    >
                        發送 →
                    </button>
                )}
            </form>
        </div>
    );
}
