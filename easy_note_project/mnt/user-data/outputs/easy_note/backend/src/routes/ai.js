// src/routes/ai.js
const express = require('express');
const multer = require('multer');
const fs = require('fs');
const path = require('path');
const OpenAI = require('openai');
const { verifyToken } = require('../middleware/auth');
const logger = require('../utils/logger');

const router = express.Router();

// Initialize OpenAI
const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

// Multer for audio upload (in-memory)
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 25 * 1024 * 1024 }, // 25MB max for OpenAI Whisper
  fileFilter: (req, file, cb) => {
    const allowed = ['audio/m4a', 'audio/mp4', 'audio/mpeg', 'audio/wav', 'audio/ogg', 'audio/webm'];
    if (allowed.includes(file.mimetype) || file.originalname.match(/\.(m4a|mp3|wav|ogg|webm)$/i)) {
      cb(null, true);
    } else {
      cb(new Error('Invalid audio format'), false);
    }
  },
});

// All AI routes require authentication
router.use(verifyToken);

/**
 * POST /api/ai/transcribe
 * Transcribe audio using OpenAI Whisper
 */
router.post('/transcribe', upload.single('audio'), async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: 'No audio file provided' });
  }

  // Write buffer to temp file (Whisper SDK needs file path or stream)
  const tmpPath = path.join('/tmp', `audio_${Date.now()}.m4a`);
  fs.writeFileSync(tmpPath, req.file.buffer);

  try {
    const transcript = await openai.audio.transcriptions.create({
      file: fs.createReadStream(tmpPath),
      model: 'whisper-1',
      language: req.body.language || 'en',
      response_format: 'text',
    });

    res.json({ transcript: transcript.trim() });
  } catch (error) {
    logger.error('Transcription error:', error.message);
    res.status(500).json({ error: 'Transcription failed' });
  } finally {
    // Clean up temp file
    fs.unlink(tmpPath, () => {});
  }
});

/**
 * POST /api/ai/summarize
 * Summarize note content
 */
router.post('/summarize', async (req, res) => {
  const { content } = req.body;
  if (!content || content.trim().length < 50) {
    return res.status(400).json({ error: 'Content too short to summarize' });
  }

  try {
    const completion = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        {
          role: 'system',
          content: 'You are a helpful assistant that summarizes notes concisely. Respond with a 1-3 sentence summary. Be direct and informative. No preamble.',
        },
        {
          role: 'user',
          content: `Summarize this note:\n\n${content.substring(0, 4000)}`,
        },
      ],
      max_tokens: 150,
      temperature: 0.3,
    });

    const summary = completion.choices[0]?.message?.content?.trim();
    res.json({ summary });
  } catch (error) {
    logger.error('Summarization error:', error.message);
    res.status(500).json({ error: 'Summarization failed' });
  }
});

/**
 * POST /api/ai/tags
 * Generate smart tags
 */
router.post('/tags', async (req, res) => {
  const { content } = req.body;
  if (!content || content.trim().length < 20) {
    return res.status(400).json({ error: 'Content too short' });
  }

  try {
    const completion = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        {
          role: 'system',
          content: 'Generate 3-6 relevant single-word or two-word tags for the note content. Return only a JSON array of lowercase strings. No explanation.',
        },
        {
          role: 'user',
          content: content.substring(0, 2000),
        },
      ],
      max_tokens: 80,
      temperature: 0.3,
      response_format: { type: 'json_object' },
    });

    const raw = completion.choices[0]?.message?.content;
    let tags = [];
    try {
      const parsed = JSON.parse(raw);
      tags = parsed.tags || parsed.result || Object.values(parsed)[0] || [];
    } catch {
      tags = [];
    }

    res.json({ tags: tags.slice(0, 6) });
  } catch (error) {
    logger.error('Tagging error:', error.message);
    res.status(500).json({ error: 'Tag generation failed' });
  }
});

/**
 * POST /api/ai/checklist
 * Convert note to actionable checklist
 */
router.post('/checklist', async (req, res) => {
  const { content } = req.body;
  if (!content || content.trim().length < 10) {
    return res.status(400).json({ error: 'Content too short' });
  }

  try {
    const completion = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        {
          role: 'system',
          content: 'Extract actionable items from the text and return them as a JSON object with a "items" array. Each item has "text" (string) and "done" (boolean, default false). No explanation.',
        },
        {
          role: 'user',
          content: content.substring(0, 2000),
        },
      ],
      max_tokens: 400,
      temperature: 0.2,
      response_format: { type: 'json_object' },
    });

    const raw = completion.choices[0]?.message?.content;
    let items = [];
    try {
      const parsed = JSON.parse(raw);
      items = parsed.items || [];
    } catch {
      items = [];
    }

    res.json({ items });
  } catch (error) {
    logger.error('Checklist error:', error.message);
    res.status(500).json({ error: 'Checklist conversion failed' });
  }
});

/**
 * POST /api/ai/detect-type
 * Detect content category: shopping, medicine, reminder, recipe, meeting, general
 */
router.post('/detect-type', async (req, res) => {
  const { content } = req.body;
  if (!content || content.trim().length < 10) {
    return res.status(400).json({ error: 'Content too short' });
  }

  try {
    const completion = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        {
          role: 'system',
          content: `Classify this note into exactly ONE category. Return JSON with "type" key.
Categories: shopping, medicine, reminder, recipe, meeting, travel, fitness, finance, general.
Example: {"type": "shopping"}`,
        },
        {
          role: 'user',
          content: content.substring(0, 1000),
        },
      ],
      max_tokens: 20,
      temperature: 0.1,
      response_format: { type: 'json_object' },
    });

    const raw = completion.choices[0]?.message?.content;
    let type = 'general';
    try {
      const parsed = JSON.parse(raw);
      type = parsed.type || 'general';
    } catch {
      type = 'general';
    }

    res.json({ type });
  } catch (error) {
    logger.error('Detection error:', error.message);
    res.status(500).json({ error: 'Content detection failed' });
  }
});

module.exports = router;
