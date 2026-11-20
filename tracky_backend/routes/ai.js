const express = require('express');
const router = express.Router();
const pool = require('../config/db');
const authMiddleware = require('../middleware/auth');
const Groq = require('groq-sdk');

// Initialize Groq client
const groq = new Groq({
  apiKey: process.env.GROQ_API_KEY
});

// Protect the endpoint using existing authentication middleware
router.use(authMiddleware);

/**
 * @route   POST /api/ai/chat
 * @desc    Conversational AI fitness assistant with Groq streaming support
 */
router.post('/chat', async (req, res) => {
  try {
    const userId = req.userId;
    const { message, history = [], stream = false } = req.body;

    if (!message) {
      return res.status(400).json({ error: 'Message is required' });
    }

    if (!process.env.GROQ_API_KEY) {
      return res.status(500).json({ error: 'Groq API key is not configured on the server.' });
    }

    // 1. Retrieve the latest 20 workouts belonging only to that user
    const [workouts] = await pool.query(
      `SELECT id, workout_date, date, body_weight, body_weight_kg, notes, note, total_sets, total_reps, total_volume 
       FROM workout_logs 
       WHERE user_id = ? 
       ORDER BY COALESCE(date, workout_date) DESC, id DESC 
       LIMIT 20`,
      [userId]
    );

    let workoutHistory = [];
    if (workouts.length > 0) {
      const workoutIds = workouts.map(w => w.id);
      const [exercises] = await pool.query(
        `SELECT workout_id, exercise_name, sets, reps, weight_kg 
         FROM exercises 
         WHERE workout_id IN (?) 
         ORDER BY id ASC`,
        [workoutIds]
      );

      const exercisesMap = {};
      for (const ex of exercises) {
        if (!exercisesMap[ex.workout_id]) {
          exercisesMap[ex.workout_id] = [];
        }
        exercisesMap[ex.workout_id].push({
          name: ex.exercise_name,
          sets: Number(ex.sets),
          reps: Number(ex.reps),
          weightKg: Number(ex.weight_kg)
        });
      }

      workoutHistory = workouts.map(w => ({
        date: w.date || w.workout_date,
        bodyWeightKg: Number(w.body_weight_kg ?? w.body_weight ?? 0),
        totalSets: Number(w.total_sets ?? 0),
        totalReps: Number(w.total_reps ?? 0),
        totalVolume: Number(w.total_volume ?? 0),
        notes: w.note ?? w.notes ?? '',
        exercises: exercisesMap[w.id] || []
      }));
    }

    // 2. Prepare the system prompt with context
    const systemPrompt = `
You are Tracky's personal fitness assistant. You are having a conversation with a user about their fitness journey.
Always be encouraging, professional, and data-driven.

User's Workout History (last 20 sessions):
${workoutHistory.length > 0 ? JSON.stringify(workoutHistory, null, 2) : "No workout history logged yet."}

Guidelines:
- Use the user's actual workout history to provide personalized advice.
- If the user asks for an analysis, analyze frequency, muscle groups, and performance trends.
- If the user asks what to train, suggest exercises, sets, reps, and weights based on their history and recovery.
- Provide recovery and progression advice when appropriate.
- Never invent workout history; if data is missing, clearly mention it.
- Keep responses clean and easy to read in a mobile chat interface. Use bullet points or numbered lists for exercises.
- Do NOT use markdown headers like # or ##. Use bold text for emphasis.
`;

    // 3. Prepare messages for Groq
    const messages = [
      { role: 'system', content: systemPrompt },
      ...history.map(msg => ({
        role: msg.isUser ? 'user' : 'assistant',
        content: msg.text
      })),
      { role: 'user', content: message }
    ];

    // 4. Call Groq API
    const groqModel = process.env.GROQ_MODEL || 'llama3-8b-8192';

    if (stream) {
      // Set headers for Server-Sent Events (SSE)
      res.setHeader('Content-Type', 'text/event-stream');
      res.setHeader('Cache-Control', 'no-cache');
      res.setHeader('Connection', 'keep-alive');
      res.flushHeaders();

      try {
        const chatStream = await groq.chat.completions.create({
          messages: messages,
          model: groqModel,
          stream: true,
        });

        for await (const chunk of chatStream) {
          const content = chunk.choices[0]?.delta?.content || '';
          if (content) {
            res.write(`data: ${JSON.stringify({ content })}\n\n`);
          }
        }
        res.write('data: [DONE]\n\n');
      } catch (error) {
        console.error('Groq Streaming error:', error);
        res.write(`data: ${JSON.stringify({ error: 'Streaming interrupted: ' + error.message })}\n\n`);
      } finally {
        res.end();
      }
    } else {
      // Non-streaming response
      const chatCompletion = await groq.chat.completions.create({
        messages: messages,
        model: groqModel,
      });

      res.status(200).json({
        reply: chatCompletion.choices[0]?.message?.content || '',
        hasHistory: workoutHistory.length > 0
      });
    }

  } catch (error) {
    console.error('Error in AI chat with Groq:', error);
    
    // Handle specific Groq errors if possible
    const statusCode = error.status || 500;
    const errorMessage = error.message || 'Failed to generate AI response. Please try again later.';

    if (!res.headersSent) {
      res.status(statusCode).json({ error: errorMessage });
    }
  }
});

/**
 * @route   POST /api/ai/recommendations
 * @desc    DEPRECATED: Use /api/ai/chat instead.
 */
router.post('/recommendations', async (req, res) => {
  req.body.message = "Analyze my workout progress and provide a recommendation.";
  req.body.stream = false;
  return router.handle(req, res);
});

module.exports = router;
