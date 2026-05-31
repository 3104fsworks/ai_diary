/**
 * Shared Cloudflare Workers API Proxy
 * Used by: AI Diary (ai_diary) / Voice Brain (voice_brain)
 *
 * Routes:
 *   POST /whisper              → OpenAI Whisper transcription (multipart)
 *   POST /gemini               → Google Gemini generateContent (JSON)
 *   POST /tts                  → OpenAI TTS → { audioBase64, format }
 *   POST /voice-brain/process  → Gemini audio→JSON (Voice Brain)
 *
 * Secrets (set via `wrangler secret put` — never commit these):
 *   OPENAI_API_KEY   — OpenAI platform API key (sk-proj-...)
 *   GEMINI_API_KEY   — Google AI Studio API key (AIzaSy...)
 *   APP_TOKEN        — Shared secret sent as X-App-Token header.
 *                      Leave unset to skip validation during local dev.
 *
 * Deploy:
 *   cd cloudflare
 *   wrangler secret put OPENAI_API_KEY
 *   wrangler secret put GEMINI_API_KEY
 *   wrangler secret put APP_TOKEN
 *   wrangler deploy
 */

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, X-App-Token',
};

export default {
  /** @param {Request} request @param {Env} env */
  async fetch(request, env) {
    // Handle CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: CORS_HEADERS });
    }

    if (request.method !== 'POST') {
      return jsonResponse({ error: 'Method not allowed' }, 405);
    }

    // ── Token validation ────────────────────────────────────────────────────
    // Skip when APP_TOKEN secret is not configured (local dev / first deploy).
    const requiredToken = (env.APP_TOKEN ?? '').trim();
    if (requiredToken.length > 0) {
      const sentToken = (request.headers.get('X-App-Token') ?? '').trim();
      if (sentToken !== requiredToken) {
        return jsonResponse({ error: 'Unauthorized' }, 401);
      }
    }

    const { pathname } = new URL(request.url);

    if (pathname === '/whisper') return handleWhisper(request, env);
    if (pathname === '/gemini') return handleGemini(request, env);
    if (pathname === '/tts') return handleTts(request, env);
    if (pathname === '/voice-brain/process') return handleVoiceBrainProcess(request, env);

    return jsonResponse({ error: 'Not found' }, 404);
  },
};

// ── /whisper ─────────────────────────────────────────────────────────────────
// Receives the same multipart/form-data the Flutter app would normally send
// directly to OpenAI, strips the client-side auth, and re-sends with the
// server-side key injected.

async function handleWhisper(request, env) {
  const apiKey = (env.OPENAI_API_KEY ?? '').trim();
  if (!apiKey) {
    return jsonResponse({ error: 'OPENAI_API_KEY not configured on server' }, 500);
  }

  // Forward multipart body verbatim; only swap the Authorization header.
  const contentType = request.headers.get('Content-Type') ?? '';
  const upstream = new Request(
    'https://api.openai.com/v1/audio/transcriptions',
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${apiKey}`,
        // Must preserve the original Content-Type boundary for multipart.
        'Content-Type': contentType,
      },
      body: request.body,
    },
  );

  const res = await fetch(upstream);
  const resText = await res.text();

  return new Response(resText, {
    status: res.status,
    headers: {
      ...CORS_HEADERS,
      'Content-Type': res.headers.get('Content-Type') ?? 'text/plain; charset=utf-8',
    },
  });
}

// ── /gemini ───────────────────────────────────────────────────────────────────
// Expected request body (JSON):
//   { "model": "gemini-2.5-flash", "body": { ...full Gemini request... } }
//
// The worker injects the API key into the query string and proxies to
// the Generative Language REST API.

async function handleGemini(request, env) {
  const apiKey = (env.GEMINI_API_KEY ?? '').trim();
  if (!apiKey) {
    return jsonResponse({ error: 'GEMINI_API_KEY not configured on server' }, 500);
  }

  let payload;
  try {
    payload = await request.json();
  } catch {
    return jsonResponse({ error: 'Request body must be valid JSON' }, 400);
  }

  const model = (payload.model ?? 'gemini-2.5-flash').trim();
  const geminiBody = payload.body;
  if (!geminiBody || typeof geminiBody !== 'object') {
    return jsonResponse({ error: 'Missing or invalid "body" field' }, 400);
  }

  const geminiUrl =
    `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent?key=${apiKey}`;

  const res = await fetch(geminiUrl, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=utf-8' },
    body: JSON.stringify(geminiBody),
  });

  const resText = await res.text();
  return new Response(resText, {
    status: res.status,
    headers: {
      ...CORS_HEADERS,
      'Content-Type': res.headers.get('Content-Type') ?? 'application/json; charset=utf-8',
    },
  });
}

// ── /tts ──────────────────────────────────────────────────────────────────────
// Calls OpenAI TTS, converts the binary MP3 to base64, and returns:
//   { audioBase64: string, format: "mp3" }
// The Flutter TtsService decodes this and writes the MP3 to disk.
//
// Expected request body (JSON):
//   { "model": "tts-1", "input": "...", "voice": "nova",
//     "response_format": "mp3", "speed": 1.0 }

async function handleTts(request, env) {
  const apiKey = (env.OPENAI_API_KEY ?? '').trim();
  if (!apiKey) {
    return jsonResponse({ error: 'OPENAI_API_KEY not configured on server' }, 500);
  }

  let payload;
  try {
    payload = await request.json();
  } catch {
    return jsonResponse({ error: 'Request body must be valid JSON' }, 400);
  }

  const {
    model = 'tts-1',
    input,
    voice,
    response_format: responseFormat = 'mp3',
    speed = 1.0,
  } = payload;

  if (!input || !voice) {
    return jsonResponse({ error: 'Missing "input" or "voice" field' }, 400);
  }

  const res = await fetch('https://api.openai.com/v1/audio/speech', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ model, input, voice, response_format: responseFormat, speed }),
  });

  if (!res.ok) {
    const errText = await res.text();
    return jsonResponse({ error: `OpenAI TTS ${res.status}: ${errText}` }, res.status);
  }

  // Convert binary MP3 to base64 using Cloudflare Workers' btoa + Uint8Array
  const arrayBuffer = await res.arrayBuffer();
  const bytes = new Uint8Array(arrayBuffer);
  // btoa only handles latin-1; build a binary string first
  let binary = '';
  for (let i = 0; i < bytes.byteLength; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  const audioBase64 = btoa(binary);

  return new Response(
    JSON.stringify({ audioBase64, format: responseFormat }),
    {
      status: 200,
      headers: {
        ...CORS_HEADERS,
        'Content-Type': 'application/json; charset=utf-8',
      },
    },
  );
}

// ── /voice-brain/process ──────────────────────────────────────────────────────
//
// Sends an audio file (base64) + category to Gemini 2.0 Flash, which
// transcribes and structures the content in a single pass (no Whisper needed).
//
// Request body (JSON):
//   {
//     "audioBase64": "<base64-encoded audio>",
//     "mimeType":    "audio/m4a",      // or audio/mp4, audio/wav, audio/webm
//     "category":    "アイデア"        // see CATEGORY_HINTS below
//   }
//
// Response (JSON):
//   {
//     "transcript": "音声の逐語テキスト",
//     "title":      "20文字以内のタイトル",
//     "body":       "整理・清書した本文",
//     "tags":       ["タグ1", "タグ2", "タグ3"],
//     "category":   "アイデア"
//   }

const CATEGORY_HINTS = {
  'アイデア':  'アイデア・着想・インスピレーション',
  'タスク':    'タスク・やること・TODO',
  'メモ':      'メモ・覚え書き・情報',
  '学習':      '学んだこと・気づき・読書メモ',
  '会議':      '会議・打ち合わせ・議事録',
  '振り返り':  '振り返り・リフレクション・感想',
};

async function handleVoiceBrainProcess(request, env) {
  const apiKey = (env.GEMINI_API_KEY ?? '').trim();
  if (!apiKey) {
    return jsonResponse({ error: 'GEMINI_API_KEY not configured on server' }, 500);
  }

  let payload;
  try {
    payload = await request.json();
  } catch {
    return jsonResponse({ error: 'Request body must be valid JSON' }, 400);
  }

  const { audioBase64, mimeType = 'audio/m4a', category = 'メモ' } = payload;
  if (!audioBase64 || typeof audioBase64 !== 'string') {
    return jsonResponse({ error: 'Missing or invalid "audioBase64" field' }, 400);
  }

  const categoryLabel = CATEGORY_HINTS[category] ?? category;
  const prompt =
    `この音声を文字起こしして「${categoryLabel}」として整理してください。\n\n` +
    '以下の4フィールドをもつJSONだけを返すこと（コードブロック・説明文は不要）:\n' +
    '{\n' +
    '  "transcript": "音声の逐語テキスト",\n' +
    '  "title": "内容を表すタイトル（20字以内）",\n' +
    '  "body": "話し言葉を整理した読みやすい本文（言い淀み・繰り返し除去）",\n' +
    '  "tags": ["キーワード1", "キーワード2", "キーワード3"]\n' +
    '}\n\n' +
    'tagsは3〜5個の短い日本語キーワードで。';

  const geminiBody = {
    contents: [
      {
        role: 'user',
        parts: [
          // Inline audio — Gemini 2.0 Flash natively understands audio
          { inlineData: { mimeType, data: audioBase64 } },
          { text: prompt },
        ],
      },
    ],
    generationConfig: {
      temperature: 0.3,
      maxOutputTokens: 1024,
      responseMimeType: 'application/json', // forces valid JSON output
    },
  };

  const model = 'gemini-2.0-flash';
  const geminiUrl =
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;

  const res = await fetch(geminiUrl, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=utf-8' },
    body: JSON.stringify(geminiBody),
  });

  if (!res.ok) {
    const errText = await res.text();
    return jsonResponse({ error: `Gemini ${res.status}: ${errText}` }, res.status);
  }

  const geminiResp = await res.json();
  const rawText = geminiResp?.candidates?.[0]?.content?.parts?.[0]?.text ?? '';

  let result;
  try {
    result = JSON.parse(rawText);
  } catch {
    // Gemini returned something non-JSON — wrap it gracefully
    result = { transcript: rawText, title: '', body: rawText, tags: [] };
  }

  // Always echo the requested category back to the client
  result.category = category;

  return jsonResponse(result);
}

// ── Helpers ───────────────────────────────────────────────────────────────────

function jsonResponse(obj, status = 200) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { ...CORS_HEADERS, 'Content-Type': 'application/json; charset=utf-8' },
  });
}
