import {
  CopilotRuntime,
  LangChainAdapter,
  copilotRuntimeNextJSAppRouterEndpoint,
} from '@copilotkit/runtime';
import { NextRequest } from 'next/server';
import { ChatOllama } from '@langchain/ollama';

// 建立 Ollama 模型（透過 LangChain）
const model = new ChatOllama({
  baseUrl: 'http://localhost:11434',
  model: 'llama3.1:latest',
});

// 建立 CopilotKit Runtime
const runtime = new CopilotRuntime();

export const POST = async (req: NextRequest) => {
  const { handleRequest } = copilotRuntimeNextJSAppRouterEndpoint({
    runtime,
    serviceAdapter: new LangChainAdapter({
      chainFn: async ({ messages, tools }) => {
        // 如果有 tools，綁定到模型
        if (tools && tools.length > 0) {
          return model.bindTools(tools).stream(messages);
        }
        return model.stream(messages);
      },
    }),
    endpoint: '/api/copilotkit',
  });

  return handleRequest(req);
};



