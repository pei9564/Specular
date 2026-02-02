import { NextRequest } from 'next/server';

// AG-UI 事件類型
type AGUIEventType =
    | 'RUN_STARTED'
    | 'TEXT_MESSAGE_START'
    | 'TEXT_MESSAGE_CONTENT'
    | 'TEXT_MESSAGE_END'
    | 'RUN_FINISHED'
    | 'RUN_ERROR';

interface AGUIEvent {
    type: AGUIEventType;
    [key: string]: unknown;
}

// 發送 AG-UI 事件
function formatSSE(event: AGUIEvent): string {
    return `data: ${JSON.stringify(event)}\n\n`;
}

// 生成唯一 ID
function generateId(): string {
    return `msg_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
}

export async function POST(req: NextRequest) {
    const { message, model = 'llama3.1:latest' } = await req.json();

    const runId = generateId();
    const messageId = generateId();

    // 建立 SSE 串流
    const encoder = new TextEncoder();
    const stream = new ReadableStream({
        async start(controller) {
            try {
                // 1. RUN_STARTED
                controller.enqueue(encoder.encode(formatSSE({
                    type: 'RUN_STARTED',
                    runId,
                    threadId: 'default',
                })));

                // 2. TEXT_MESSAGE_START
                controller.enqueue(encoder.encode(formatSSE({
                    type: 'TEXT_MESSAGE_START',
                    messageId,
                    role: 'assistant',
                })));

                // 3. 呼叫 Ollama API (串流模式)
                const ollamaResponse = await fetch('http://localhost:11434/api/chat', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        model,
                        messages: [{ role: 'user', content: message }],
                        stream: true,
                    }),
                });

                if (!ollamaResponse.ok) {
                    throw new Error(`Ollama error: ${ollamaResponse.status}`);
                }

                const reader = ollamaResponse.body?.getReader();
                const decoder = new TextDecoder();

                if (reader) {
                    while (true) {
                        const { done, value } = await reader.read();
                        if (done) break;

                        const chunk = decoder.decode(value, { stream: true });
                        const lines = chunk.split('\n').filter(line => line.trim());

                        for (const line of lines) {
                            try {
                                const data = JSON.parse(line);
                                if (data.message?.content) {
                                    // 4. TEXT_MESSAGE_CONTENT (逐字串流)
                                    controller.enqueue(encoder.encode(formatSSE({
                                        type: 'TEXT_MESSAGE_CONTENT',
                                        messageId,
                                        content: data.message.content,
                                    })));
                                }
                            } catch {
                                // Skip invalid JSON
                            }
                        }
                    }
                }

                // 5. TEXT_MESSAGE_END
                controller.enqueue(encoder.encode(formatSSE({
                    type: 'TEXT_MESSAGE_END',
                    messageId,
                })));

                // 6. RUN_FINISHED
                controller.enqueue(encoder.encode(formatSSE({
                    type: 'RUN_FINISHED',
                    runId,
                })));

            } catch (error) {
                // 錯誤處理
                controller.enqueue(encoder.encode(formatSSE({
                    type: 'RUN_ERROR',
                    runId,
                    error: error instanceof Error ? error.message : 'Unknown error',
                })));
            } finally {
                controller.close();
            }
        },
    });

    return new Response(stream, {
        headers: {
            'Content-Type': 'text/event-stream',
            'Cache-Control': 'no-cache',
            'Connection': 'keep-alive',
        },
    });
}
