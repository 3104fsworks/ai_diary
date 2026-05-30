/**
 * AI Diary — Firebase Functions API proxy
 *
 * Routes (all POST):
 *   /gemini   → Google Gemini generateContent
 *   /tts      → OpenAI TTS → returns { audioBase64, format }
 *   /whisper  → OpenAI Whisper transcription (multipart)
 *
 * Secrets (set once with `firebase functions:secrets:set <NAME>`):
 *   GEMINI_API_KEY   — Google AI Studio key (AIzaSy...)
 *   OPENAI_API_KEY   — OpenAI key (sk-proj-...)
 *   APP_TOKEN        — Shared token the Flutter app sends as X-App-Token.
 *                      Leave unset to skip token validation during local dev.
 *
 * Deploy:
 *   firebase functions:secrets:set GEMINI_API_KEY
 *   firebase functions:secrets:set OPENAI_API_KEY
 *   firebase functions:secrets:set APP_TOKEN
 *   firebase deploy --only functions
 *
 * The deployed URL looks like:
 *   https://api-<hash>-an.a.run.app   (asia-northeast1)
 * Enter that URL as "プロキシURL" in the app's カスタム設定 screen.
 */

import { onRequest } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import express, { Request, Response, NextFunction } from 'express';
import axios from 'axios';
import Busboy from 'busboy';
import FormData from 'form-data';

// ── Secrets (Google Secret Manager) ──────────────────────────────────────────

const geminiApiKey = defineSecret('GEMINI_API_KEY');
const openaiApiKey = defineSecret('OPENAI_API_KEY');
const appToken = defineSecret('APP_TOKEN');

// ── Express app ───────────────────────────────────────────────────────────────

const app = express();

// Parse JSON bodies (skipped automatically for non-JSON content types,
// so multipart /whisper requests pass through unmodified).
app.use(express.json());

// ── Token auth middleware ─────────────────────────────────────────────────────

app.use((req: Request, res: Response, next: NextFunction): void => {
  const required = (appToken.value() ?? '').trim();
  if (required.length > 0) {
    const sent = ((req.headers['x-app-token'] as string) ?? '').trim();
    if (sent !== required) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }
  }
  next();
});

// ── POST /gemini ──────────────────────────────────────────────────────────────
//
// Request body (JSON):
//   { "model": "gemini-2.5-flash", "body": { ...Gemini generateContent payload... } }
//
// Response: the Gemini API response JSON (passed through verbatim).

app.post('/gemini', async (req: Request, res: Response): Promise<void> => {
  const key = geminiApiKey.value().trim();
  if (!key) {
    res.status(500).json({ error: 'GEMINI_API_KEY not configured on server' });
    return;
  }

  const payload = req.body as { model?: string; body?: unknown };
  const model = (payload.model ?? 'gemini-2.5-flash').trim();
  const geminiBody = payload.body;

  if (!geminiBody || typeof geminiBody !== 'object') {
    res.status(400).json({ error: 'Missing or invalid "body" field' });
    return;
  }

  const url =
    `https://generativelanguage.googleapis.com/v1beta/models/` +
    `${encodeURIComponent(model)}:generateContent?key=${key}`;

  try {
    const resp = await axios.post(url, geminiBody, {
      headers: { 'Content-Type': 'application/json; charset=utf-8' },
      timeout: 60_000,
    });
    res.status(resp.status).json(resp.data);
  } catch (err: unknown) {
    if (axios.isAxiosError(err) && err.response) {
      res.status(err.response.status).json(err.response.data);
    } else {
      res.status(500).json({ error: String(err) });
    }
  }
});

// ── POST /tts ─────────────────────────────────────────────────────────────────
//
// Request body (JSON):
//   { "model": "tts-1", "input": "...", "voice": "nova",
//     "response_format": "mp3", "speed": 1.0 }
//
// Response (JSON):
//   { "audioBase64": "<base64-encoded MP3>", "format": "mp3" }

app.post('/tts', async (req: Request, res: Response): Promise<void> => {
  const key = openaiApiKey.value().trim();
  if (!key) {
    res.status(500).json({ error: 'OPENAI_API_KEY not configured on server' });
    return;
  }

  const body = req.body as {
    model?: string;
    input?: string;
    voice?: string;
    response_format?: string;
    speed?: number;
  };
  const model = body.model ?? 'tts-1';
  const input = body.input;
  const voice = body.voice;
  const responseFormat = body.response_format ?? 'mp3';
  const speed = body.speed ?? 1.0;

  if (!input || !voice) {
    res.status(400).json({ error: 'Missing "input" or "voice" field' });
    return;
  }

  try {
    const resp = await axios.post(
      'https://api.openai.com/v1/audio/speech',
      { model, input, voice, response_format: responseFormat, speed },
      {
        headers: {
          Authorization: `Bearer ${key}`,
          'Content-Type': 'application/json',
        },
        responseType: 'arraybuffer',
        timeout: 120_000,
      },
    );
    const audioBase64 = Buffer.from(resp.data as ArrayBuffer).toString('base64');
    res.status(200).json({ audioBase64, format: responseFormat });
  } catch (err: unknown) {
    if (axios.isAxiosError(err) && err.response) {
      const errData = err.response.data;
      const msg = Buffer.isBuffer(errData) ? errData.toString() : String(errData);
      res.status(err.response.status).json({ error: msg });
    } else {
      res.status(500).json({ error: String(err) });
    }
  }
});

// ── POST /whisper ─────────────────────────────────────────────────────────────
//
// Receives the same multipart/form-data that the Flutter app sends.
// Parses it with busboy, re-sends to OpenAI Whisper with the server key.
// Returns plain-text transcript (response_format=text).

app.post('/whisper', (req: Request, res: Response): void => {
  const key = openaiApiKey.value().trim();
  if (!key) {
    res.status(500).json({ error: 'OPENAI_API_KEY not configured on server' });
    return;
  }

  const bb = Busboy({ headers: req.headers });
  const form = new FormData();
  const pending: Promise<void>[] = [];

  bb.on('file', (fieldname, file, info) => {
    const chunks: Buffer[] = [];
    file.on('data', (chunk: Buffer) => chunks.push(chunk));
    pending.push(
      new Promise<void>((resolve) => {
        file.on('end', () => {
          form.append(fieldname, Buffer.concat(chunks), {
            filename: info.filename,
            contentType: info.mimeType,
          });
          resolve();
        });
      }),
    );
  });

  bb.on('field', (name: string, value: string) => {
    form.append(name, value);
  });

  bb.on('finish', () => {
    void (async () => {
      await Promise.all(pending);
      try {
        const resp = await axios.post(
          'https://api.openai.com/v1/audio/transcriptions',
          form,
          {
            headers: {
              Authorization: `Bearer ${key}`,
              ...form.getHeaders(),
            },
            timeout: 60_000,
          },
        );
        // response_format=text → OpenAI returns plain text (not JSON)
        res.status(200).send(resp.data);
      } catch (err: unknown) {
        if (axios.isAxiosError(err) && err.response) {
          res.status(err.response.status).json({ error: String(err.response.data) });
        } else {
          res.status(500).json({ error: String(err) });
        }
      }
    })();
  });

  bb.on('error', (err: Error) => {
    res.status(500).json({ error: `Multipart parse error: ${err.message}` });
  });

  req.pipe(bb);
});

// ── Firebase Function export ───────────────────────────────────────────────────

export const api = onRequest(
  {
    region: 'asia-northeast1',
    timeoutSeconds: 180,
    memory: '512MiB',
    secrets: [geminiApiKey, openaiApiKey, appToken],
  },
  app,
);
