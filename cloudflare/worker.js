/**
 * AI Diary — Cloudflare Workers API Proxy
 *
 * Routes:
 *   POST /whisper  → OpenAI Whisper transcription
 *   POST /gemini   → Google Gemini generateContent
 *
 * Secrets (set via `wrangler secret put` — never commit these):
 *   OPENAI_API_KEY   — OpenAI platform API key (sk-proj-...)
 *   GEMINI_API_KEY   — Google AI Studio API key (AIzaSy...)
 *   APP_TOKEN        — Shared secret the app sends as X-App-Token header.
 *                      Set to any random 32+ char string. Leave unset / empty
 *                      to disable token validation during local dev.
 *
 * Deploy:
 *   npm install -g wrangler
 *   wrangler login
 *   wrangler secret put OPENAI_API_KEY
 *   wrangler secret put GEMINI_API_KEY
 *   wrangler secret put APP_TOKEN
 *   wrangler deploy
 *
 * The worker URL will be something like:
 *   https://ai-diary-proxy.<your-subdomain>.workers.dev
 * Enter that URL in the app under カスタム設定 → プロキシ設定.
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

// ── Helpers ───────────────────────────────────────────────────────────────────

function jsonResponse(obj, status = 200) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { ...CORS_HEADERS, 'Content-Type': 'application/json; charset=utf-8' },
  });
}
