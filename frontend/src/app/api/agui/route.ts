import { NextRequest } from 'next/server';

// AG-UI 事件類型 (完整版)
type AGUIEventType =
  | 'RUN_STARTED'
  | 'TEXT_MESSAGE_START'
  | 'TEXT_MESSAGE_CONTENT'
  | 'TEXT_MESSAGE_END'
  | 'TOOL_CALL_START'
  | 'TOOL_CALL_ARGS'
  | 'TOOL_CALL_END'
  | 'TOOL_CALL_RESULT'
  | 'RUN_FINISHED'
  | 'RUN_ERROR';

interface AGUIEvent {
  type: AGUIEventType;
  [key: string]: unknown;
}

// 可用的 Tools 定義
const AVAILABLE_TOOLS = [
  {
    name: 'get_weather',
    description: '查詢指定城市的天氣資訊',
    parameters: {
      type: 'object',
      properties: {
        city: { type: 'string', description: '城市名稱' },
      },
      required: ['city'],
    },
  },
  {
    name: 'calculate',
    description: '執行數學計算',
    parameters: {
      type: 'object',
      properties: {
        expression: { type: 'string', description: '數學表達式' },
      },
      required: ['expression'],
    },
  },
  {
    name: 'search_database',
    description: '搜尋資料庫',
    parameters: {
      type: 'object',
      properties: {
        query: { type: 'string', description: '搜尋關鍵字' },
        limit: { type: 'number', description: '結果數量限制' },
      },
      required: ['query'],
    },
  },
];

// 發送 AG-UI 事件
function formatSSE(event: AGUIEvent): string {
  return `data: ${JSON.stringify(event)}\n\n`;
}

// 生成唯一 ID
function generateId(): string {
  return `${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
}

// 動態地理編碼 - 使用 Open-Meteo Geocoding API
async function geocodeCity(cityName: string): Promise<{ lat: number; lon: number; name: string; country: string } | null> {
  try {
    const url = `https://geocoding-api.open-meteo.com/v1/search?name=${encodeURIComponent(cityName)}&count=1&language=zh`;
    const response = await fetch(url);

    if (!response.ok) {
      console.error(`Geocoding API error: ${response.status}`);
      return null;
    }

    const data = await response.json();

    if (!data.results || data.results.length === 0) {
      return null;
    }

    const result = data.results[0];
    return {
      lat: result.latitude,
      lon: result.longitude,
      name: result.name,
      country: result.country || '',
    };
  } catch (error) {
    console.error('Geocoding error:', error);
    return null;
  }
}

// WMO 天氣代碼對照
const WMO_CODES: Record<number, string> = {
  0: '晴天 ☀️',
  1: '大致晴朗 🌤️',
  2: '多雲 ⛅',
  3: '陰天 ☁️',
  45: '霧 🌫️',
  48: '霧凇 🌫️',
  51: '小毛毛雨 🌧️',
  53: '毛毛雨 🌧️',
  55: '大毛毛雨 🌧️',
  61: '小雨 🌧️',
  63: '中雨 🌧️',
  65: '大雨 🌧️',
  71: '小雪 ❄️',
  73: '中雪 ❄️',
  75: '大雪 ❄️',
  80: '陣雨 🌦️',
  81: '中等陣雨 🌦️',
  82: '強陣雨 🌦️',
  95: '雷暴 ⛈️',
  96: '雷暴+小冰雹 ⛈️',
  99: '雷暴+大冰雹 ⛈️',
};

// 真實工具執行
async function executeTool(toolName: string, args: Record<string, unknown>): Promise<string> {
  switch (toolName) {
    case 'get_weather': {
      const cityInput = (args.city as string || '').trim();

      // 動態查詢城市座標
      const cityData = await geocodeCity(cityInput);

      if (!cityData) {
        return JSON.stringify({
          error: `找不到城市: ${args.city}`,
          hint: '請嘗試使用城市名稱（如：台北、東京、瑞士、蘇黎世）',
        });
      }

      try {
        // 使用 Open-Meteo 免費天氣 API
        const url = `https://api.open-meteo.com/v1/forecast?latitude=${cityData.lat}&longitude=${cityData.lon}&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m&timezone=auto`;

        const response = await fetch(url);
        if (!response.ok) {
          throw new Error(`Weather API error: ${response.status}`);
        }

        const data = await response.json();
        const current = data.current;

        return JSON.stringify({
          city: cityData.name,
          country: cityData.country,
          temperature: `${current.temperature_2m}°C`,
          condition: WMO_CODES[current.weather_code] || `代碼 ${current.weather_code}`,
          humidity: `${current.relative_humidity_2m}%`,
          wind_speed: `${current.wind_speed_10m} km/h`,
          source: 'Open-Meteo API (真實數據)',
          timestamp: new Date().toLocaleString('zh-TW', { timeZone: 'Asia/Taipei' }),
        });
      } catch (error) {
        return JSON.stringify({
          error: `天氣查詢失敗: ${error instanceof Error ? error.message : 'Unknown error'}`,
        });
      }
    }

    case 'calculate': {
      try {
        // 安全的數學計算（只允許數字和基本運算符）
        const expr = (args.expression as string).replace(/[^0-9+\-*/().%\s]/g, '');
        const result = Function(`"use strict"; return (${expr})`)();
        return JSON.stringify({
          expression: args.expression,
          result,
          note: '使用安全沙箱計算',
        });
      } catch {
        return JSON.stringify({ error: '無法計算此表達式' });
      }
    }

    case 'search_database': {
      // 模擬資料庫搜尋（實際應用中會連接真實資料庫）
      return JSON.stringify({
        query: args.query,
        results: [
          { id: 1, title: `${args.query} 相關結果 1` },
          { id: 2, title: `${args.query} 相關結果 2` },
        ],
        note: '模擬結果 - 請連接真實資料庫',
      });
    }

    default:
      return JSON.stringify({ error: '未知工具' });
  }
}


export async function POST(req: NextRequest) {
  const {
    message,
    model = 'llama3.1:latest',
    toolExecutions = [],  // 已確認執行的 tool calls
    pendingToolCallId,     // 待確認的 tool call ID（用於 HIL 回應）
    toolCallApproved,      // HIL 確認結果
  } = await req.json();

  const runId = generateId();
  const messageId = generateId();
  const encoder = new TextEncoder();

  // 如果是 HIL 確認回應
  if (pendingToolCallId && typeof toolCallApproved === 'boolean') {
    const stream = new ReadableStream({
      async start(controller) {
        controller.enqueue(encoder.encode(formatSSE({
          type: 'RUN_STARTED',
          runId,
          threadId: 'default',
        })));

        if (toolCallApproved) {
          // 執行已確認的 Tool
          const execution = toolExecutions.find(
            (e: { toolCallId: string }) => e.toolCallId === pendingToolCallId
          );
          if (execution) {
            const result = await executeTool(execution.toolName, execution.args);
            controller.enqueue(encoder.encode(formatSSE({
              type: 'TOOL_CALL_RESULT',
              toolCallId: pendingToolCallId,
              result,
            })));
          }
        }

        controller.enqueue(encoder.encode(formatSSE({
          type: 'RUN_FINISHED',
          runId,
        })));
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

  // 建立正常的對話 SSE 串流
  const stream = new ReadableStream({
    async start(controller) {
      try {
        // 1. RUN_STARTED
        controller.enqueue(encoder.encode(formatSSE({
          type: 'RUN_STARTED',
          runId,
          threadId: 'default',
        })));

        // 2. 呼叫 Ollama API（帶 tools）
        const ollamaResponse = await fetch('http://localhost:11434/api/chat', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            model,
            messages: [
              {
                role: 'system',
                content: `你是一個 AI 助手。你可以使用以下工具：
${AVAILABLE_TOOLS.map(t => `- ${t.name}: ${t.description}`).join('\n')}

當需要使用工具時，請使用以下格式回應：
[TOOL_CALL:工具名稱:{"參數":"值"}]

例如：查天氣請使用 [TOOL_CALL:get_weather:{"city":"台北"}]
計算請使用 [TOOL_CALL:calculate:{"expression":"2+2"}]
搜尋請使用 [TOOL_CALL:search_database:{"query":"關鍵字"}]

如果不需要使用工具，直接回答即可。`,
              },
              { role: 'user', content: message },
            ],
            stream: true,
          }),
        });

        if (!ollamaResponse.ok) {
          throw new Error(`Ollama error: ${ollamaResponse.status}`);
        }

        const reader = ollamaResponse.body?.getReader();
        const decoder = new TextDecoder();
        let fullContent = '';
        let messageStarted = false;

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
                  fullContent += data.message.content;

                  // 延遲發送 TEXT_MESSAGE_START 直到有內容
                  if (!messageStarted) {
                    controller.enqueue(encoder.encode(formatSSE({
                      type: 'TEXT_MESSAGE_START',
                      messageId,
                      role: 'assistant',
                    })));
                    messageStarted = true;
                  }

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

        // 3. TEXT_MESSAGE_END
        if (messageStarted) {
          controller.enqueue(encoder.encode(formatSSE({
            type: 'TEXT_MESSAGE_END',
            messageId,
          })));
        }

        // 4. 解析是否有 Tool Call
        const toolCallMatch = fullContent.match(/\[TOOL_CALL:(\w+):(\{[^}]+\})\]/);
        if (toolCallMatch) {
          const toolName = toolCallMatch[1];
          const toolArgs = JSON.parse(toolCallMatch[2]);
          const toolCallId = `tc_${generateId()}`;

          // 發送 TOOL_CALL 事件（等待前端 HIL 確認）
          controller.enqueue(encoder.encode(formatSSE({
            type: 'TOOL_CALL_START',
            toolCallId,
            toolName,
          })));

          controller.enqueue(encoder.encode(formatSSE({
            type: 'TOOL_CALL_ARGS',
            toolCallId,
            args: JSON.stringify(toolArgs),
          })));

          controller.enqueue(encoder.encode(formatSSE({
            type: 'TOOL_CALL_END',
            toolCallId,
            toolName,
            args: toolArgs,
            requiresApproval: true,  // 標記需要 HIL 確認
          })));
        }

        // 5. RUN_FINISHED
        controller.enqueue(encoder.encode(formatSSE({
          type: 'RUN_FINISHED',
          runId,
        })));

      } catch (error) {
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

