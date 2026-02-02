'use client';

import { useState, useCallback, useRef } from 'react';

interface Message {
    id: string;
    role: 'user' | 'assistant' | 'system';
    content: string;
}

interface UseAGUIOptions {
    model?: string;
    onError?: (error: string) => void;
}

interface AGUIEvent {
    type: string;
    messageId?: string;
    content?: string;
    error?: string;
    [key: string]: unknown;
}

export function useAGUI(options: UseAGUIOptions = {}) {
    const { model = 'llama3.1:latest', onError } = options;

    const [messages, setMessages] = useState<Message[]>([]);
    const [isLoading, setIsLoading] = useState(false);
    const abortControllerRef = useRef<AbortController | null>(null);

    const sendMessage = useCallback(async (content: string) => {
        if (!content.trim() || isLoading) return;

        // 新增使用者訊息
        const userMessage: Message = {
            id: `user_${Date.now()}`,
            role: 'user',
            content,
        };
        setMessages(prev => [...prev, userMessage]);
        setIsLoading(true);

        // 建立 AbortController 用於取消請求
        abortControllerRef.current = new AbortController();

        try {
            const response = await fetch('/api/agui', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ message: content, model }),
                signal: abortControllerRef.current.signal,
            });

            if (!response.ok) {
                throw new Error(`API error: ${response.status}`);
            }

            const reader = response.body?.getReader();
            const decoder = new TextDecoder();
            let currentMessageId = '';
            let accumulatedContent = '';

            if (reader) {
                while (true) {
                    const { done, value } = await reader.read();
                    if (done) break;

                    const chunk = decoder.decode(value, { stream: true });
                    const lines = chunk.split('\n');

                    for (const line of lines) {
                        if (line.startsWith('data: ')) {
                            try {
                                const event: AGUIEvent = JSON.parse(line.slice(6));

                                switch (event.type) {
                                    case 'TEXT_MESSAGE_START':
                                        currentMessageId = event.messageId || `msg_${Date.now()}`;
                                        accumulatedContent = '';
                                        // 新增空的 assistant 訊息
                                        setMessages(prev => [...prev, {
                                            id: currentMessageId,
                                            role: 'assistant',
                                            content: '',
                                        }]);
                                        break;

                                    case 'TEXT_MESSAGE_CONTENT':
                                        accumulatedContent += event.content || '';
                                        // 更新 assistant 訊息內容
                                        setMessages(prev => {
                                            const updated = [...prev];
                                            const lastIndex = updated.findIndex(m => m.id === currentMessageId);
                                            if (lastIndex !== -1) {
                                                updated[lastIndex] = {
                                                    ...updated[lastIndex],
                                                    content: accumulatedContent,
                                                };
                                            }
                                            return updated;
                                        });
                                        break;

                                    case 'TEXT_MESSAGE_END':
                                        // 訊息結束，不需額外處理
                                        break;

                                    case 'RUN_ERROR':
                                        onError?.(event.error || 'Unknown error');
                                        break;
                                }
                            } catch {
                                // Skip invalid JSON
                            }
                        }
                    }
                }
            }
        } catch (error) {
            if (error instanceof Error && error.name !== 'AbortError') {
                onError?.(error.message);
            }
        } finally {
            setIsLoading(false);
            abortControllerRef.current = null;
        }
    }, [isLoading, model, onError]);

    const stopGeneration = useCallback(() => {
        abortControllerRef.current?.abort();
    }, []);

    const clearMessages = useCallback(() => {
        setMessages([]);
    }, []);

    return {
        messages,
        isLoading,
        sendMessage,
        stopGeneration,
        clearMessages,
    };
}
