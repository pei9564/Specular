import { NextRequest } from 'next/server';

export async function POST(request: NextRequest) {
  const { message, model, stm } = await request.json();

  // Create a readable stream for SSE
  const encoder = new TextEncoder();
  
  const stream = new ReadableStream({
    async start(controller) {
      // Simulate AI response
      const response = generateMockResponse(message, model, stm);
      
      // Stream the response character by character
      for (let i = 0; i < response.length; i++) {
        const chunk = response[i];
        const data = JSON.stringify({ 
          type: 'delta', 
          content: chunk,
          index: i,
          total: response.length 
        });
        controller.enqueue(encoder.encode(`data: ${data}\n\n`));
        
        // Add slight delay for realistic streaming effect
        await new Promise(resolve => setTimeout(resolve, 15));
      }
      
      // Send completion message
      const doneData = JSON.stringify({ 
        type: 'done', 
        total_tokens: response.length,
        model: model 
      });
      controller.enqueue(encoder.encode(`data: ${doneData}\n\n`));
      controller.close();
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

function generateMockResponse(message: string, model: string, stm: number): string {
  const responses: Record<string, string> = {
    'gpt-4o': `這是來自 GPT-4o 的回應。

您的訊息是：「${message}」

我已經收到您的訊息並進行了處理。目前設定的短期記憶 (STM) 為 ${stm}，這意味著我會記住最近 ${stm} 則對話。

如果您有任何問題，請隨時告訴我！`,
    
    'claude-3-opus': `您好！我是 Claude 3 Opus。

收到您的訊息：「${message}」

讓我為您提供詳細的回答。根據您的 STM 設定 (${stm})，我會保持對話的上下文連貫性。

有什麼我可以幫助您的嗎？`,

    'gpt-3.5-turbo': `收到！

訊息：「${message}」

這是 GPT-3.5 Turbo 的快速回應。STM 設定為 ${stm}。`,
  };

  return responses[model] || responses['gpt-4o'];
}
