'use client';

import { useState, useCallback, useRef } from 'react';

interface Message {
  id: string;
  role: 'user' | 'assistant' | 'system' | 'tool';
  content: string;
}

interface ToolCall {
  toolCallId: string;
  toolName: string;
  args: Record<string, unknown>;
  status: 'pending' | 'approved' | 'rejected' | 'executed';
  result?: string;
}

interface UseAGUIOptions {
  model?: string;
  onError?: (error: string) => void;
}

interface AGUIEvent {
  type: string;
  messageId?: string;
  toolCallId?: string;
  toolName?: string;
  content?: string;
  args?: string | Record<string, unknown>;
  result?: string;
  error?: string;
  requiresApproval?: boolean;
}

export function useAGUI(options: UseAGUIOptions = {}) {
  const { model = 'llama3.1:latest', onError } = options;
  
  const [messages, setMessages] = useState<Message[]>([]);
  const [pendingToolCalls, setPendingToolCalls] = useState<ToolCall[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const abortControllerRef = useRef<AbortController | null>(null);

  const processSSEStream = useCallback(async (response: Response) => {
    const reader = response.body?.getReader();
    const decoder = new TextDecoder();
    let currentMessageId = '';
    let accumulatedContent = '';

    if (!reader) return;

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
                setMessages(prev => [...prev, {
                  id: currentMessageId,
                  role: 'assistant',
                  content: '',
                }]);
                break;

              case 'TEXT_MESSAGE_CONTENT':
                accumulatedContent += event.content || '';
                setMessages(prev => {
                  const updated = [...prev];
                  const index = updated.findIndex(m => m.id === currentMessageId);
                  if (index !== -1) {
                    updated[index] = { ...updated[index], content: accumulatedContent };
                  }
                  return updated;
                });
                break;

              case 'TOOL_CALL_END':
                if (event.requiresApproval && event.toolCallId && event.toolName) {
                  const newToolCall: ToolCall = {
                    toolCallId: event.toolCallId,
                    toolName: event.toolName,
                    args: typeof event.args === 'string' 
                      ? JSON.parse(event.args) 
                      : (event.args as Record<string, unknown>) || {},
                    status: 'pending',
                  };
                  setPendingToolCalls(prev => [...prev, newToolCall]);
                }
                break;

              case 'TOOL_CALL_RESULT':
                if (event.toolCallId && event.result) {
                  setPendingToolCalls(prev => 
                    prev.map(tc => 
                      tc.toolCallId === event.toolCallId 
                        ? { ...tc, status: 'executed', result: event.result }
                        : tc
                    )
                  );
                  setMessages(prev => [...prev, {
                    id: `tool_${event.toolCallId}`,
                    role: 'tool',
                    content: event.result,
                  }]);
                }
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
  }, [onError]);

  const sendMessage = useCallback(async (content: string) => {
    if (!content.trim() || isLoading) return;

    const userMessage: Message = {
      id: `user_${Date.now()}`,
      role: 'user',
      content,
    };
    setMessages(prev => [...prev, userMessage]);
    setIsLoading(true);
    abortControllerRef.current = new AbortController();

    try {
      const response = await fetch('/api/agui', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ message: content, model }),
        signal: abortControllerRef.current.signal,
      });

      if (!response.ok) throw new Error(`API error: ${response.status}`);
      await processSSEStream(response);
    } catch (error) {
      if (error instanceof Error && error.name !== 'AbortError') {
        onError?.(error.message);
      }
    } finally {
      setIsLoading(false);
    }
  }, [isLoading, model, onError, processSSEStream]);

  const approveToolCall = useCallback(async (toolCallId: string) => {
    const toolCall = pendingToolCalls.find(tc => tc.toolCallId === toolCallId);
    if (!toolCall) return;

    setPendingToolCalls(prev => 
      prev.map(tc => tc.toolCallId === toolCallId ? { ...tc, status: 'approved' } : tc)
    );
    setIsLoading(true);

    try {
      const response = await fetch('/api/agui', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          pendingToolCallId: toolCallId,
          toolCallApproved: true,
          toolExecutions: [toolCall],
        }),
      });

      if (!response.ok) throw new Error(`API error: ${response.status}`);
      await processSSEStream(response);
    } catch (error) {
      if (error instanceof Error) onError?.(error.message);
    } finally {
      setIsLoading(false);
    }
  }, [pendingToolCalls, onError, processSSEStream]);

  const rejectToolCall = useCallback((toolCallId: string) => {
    setPendingToolCalls(prev => 
      prev.map(tc => tc.toolCallId === toolCallId ? { ...tc, status: 'rejected' } : tc)
    );
    setMessages(prev => [...prev, {
      id: `rejected_${toolCallId}`,
      role: 'system',
      content: '❌ 工具執行已被拒絕',
    }]);
  }, []);

  const stopGeneration = useCallback(() => {
    abortControllerRef.current?.abort();
  }, []);

  const clearMessages = useCallback(() => {
    setMessages([]);
    setPendingToolCalls([]);
  }, []);

  return {
    messages,
    pendingToolCalls,
    isLoading,
    sendMessage,
    approveToolCall,
    rejectToolCall,
    stopGeneration,
    clearMessages,
  };
}
