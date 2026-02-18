// prediction-market/my-workflow/gemini.ts

import {
  cre,
  ok,
  consensusIdenticalAggregation,
  type Runtime,
  type HTTPSendRequester,
} from "@chainlink/cre-sdk";

// Inline types
type Config = {
  geminiModel: string;
  evms: Array<{
    marketAddress: string;
    chainSelectorName: string;
    gasLimit: string;
  }>;
};

interface GeminiData {
  system_instruction: {
    parts: Array<{ text: string }>;
  };
  tools: Array<{ google_search: object }>;
  contents: Array<{
    parts: Array<{ text: string }>;
  }>;
}

interface GeminiApiResponse {
  candidates?: Array<{
    content?: {
      parts?: Array<{ text?: string }>;
    };
  }>;
  responseId?: string;
}

interface GeminiResponse {
  statusCode: number;
  geminiResponse: string;
  responseId: string;
  rawJsonString: string;
}

const SYSTEM_PROMPT = `
You are a fact-checking system for resolving prediction markets based on real-world outcomes.

Your task:
- Verify whether a given HISTORICAL EVENT has occurred based on publicly verifiable information.
- Use Google Search to find the most current and accurate information.
- Answer objectively based ONLY on facts, not opinion or speculation.

OUTPUT FORMAT (CRITICAL):
- Respond with ONLY this JSON format: {"result": "YES" | "NO", "confidence": <0-10000>}
- No prose, no explanation, no markdown, no code fences.
- Single line, minified JSON only.

DECISION RULES:
- "YES" = the event happened as stated in the question
- "NO" = the event did NOT happen as stated
- confidence: 0-10000 scale representing certainty level
  - 0-2000: Very uncertain
  - 2000-4000: Somewhat uncertain  
  - 4000-6000: Moderate confidence
  - 6000-8000: High confidence
  - 8000-10000: Very high confidence / definitive factual answer

INSTRUCTIONS:
- Use Google Search tool to verify facts
- Only use publicly verifiable information
- If information conflicts, use most authoritative sources
- Never speculate about future events or unknown outcomes
- Be precise: interpret the question exactly as written

REMINDER:
- Your ENTIRE response must be ONLY the JSON object: {"result": "YES" | "NO", "confidence": <number>}
- If unable to produce valid JSON, output: {"result":"NO","confidence":0}
`;

const USER_PROMPT = `Resolve this historical prediction market question using factual information and Google Search:

Return ONLY this JSON format:
{"result": "YES" | "NO", "confidence": <0-10000>}

Question:
`;

export function askGemini(
  runtime: Runtime<Config>,
  question: string,
): GeminiResponse {
  runtime.log("[Gemini] Querying AI for market outcome...");

  const geminiApiKey = runtime.getSecret({ id: "GEMINI_API_KEY" }).result();
  const httpClient = new cre.capabilities.HTTPClient();

  const result = httpClient
    .sendRequest(runtime, buildGeminiRequest(
        question,
        geminiApiKey.value,
      ), consensusIdenticalAggregation<GeminiResponse>())(runtime.config)
    .result();

  runtime.log(`[Gemini] Response received: ${result.geminiResponse}`);
  return result;
}

const buildGeminiRequest =
  (question: string, apiKey: string) =>
  (sendRequester: HTTPSendRequester, config: Config): GeminiResponse => {
    const requestData: GeminiData = {
      system_instruction: {
        parts: [{ text: SYSTEM_PROMPT }],
      },
      tools: [
        {
          google_search: {},
        },
      ],
      contents: [
        {
          parts: [{ text: USER_PROMPT + question }],
        },
      ],
    };

    const bodyBytes = new TextEncoder().encode(JSON.stringify(requestData));
    const body = Buffer.from(bodyBytes).toString("base64");

    const req = {
      url: `https://generativelanguage.googleapis.com/v1beta/models/${config.geminiModel}:generateContent`,
      method: "POST" as const,
      body,
      headers: {
        "Content-Type": "application/json",
        "x-goog-api-key": apiKey,
      },
      cacheSettings: {
        store: true,
        maxAge: "60s",
      },
    };

    const resp = sendRequester.sendRequest(req).result();
    const bodyText = new TextDecoder().decode(resp.body);

    if (!ok(resp)) {
      throw new Error(`Gemini API error: ${resp.statusCode} - ${bodyText}`);
    }

    const apiResponse = JSON.parse(bodyText) as GeminiApiResponse;
    const text = apiResponse?.candidates?.[0]?.content?.parts?.[0]?.text;

    if (!text) {
      throw new Error("Malformed Gemini response: missing text");
    }

    return {
      statusCode: resp.statusCode,
      geminiResponse: text,
      responseId: apiResponse.responseId || "",
      rawJsonString: bodyText,
    };
  };
