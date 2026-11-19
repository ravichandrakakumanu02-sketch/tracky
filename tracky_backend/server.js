
const express = require('express');
const cors = require('cors');
require('dotenv').config();

const db = require('./config/db');
const authRoutes = require('./routes/auth');
const workoutRoutes = require('./routes/workouts');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Health check
app.get('/', (req, res) => {
  res.json({
    status: 'success',
    message: 'Tracky Gym Tracker backend is up and running!'
  });
});

// Authentication routes
app.use('/api/auth', authRoutes);

// Workout routes
app.use('/api/workouts', workoutRoutes);

// Start server after checking MySQL
async function startServer() {
  try {
    await db.query('SELECT 1');

    console.log('MySQL connected successfully!');

    app.listen(PORT, '0.0.0.0', () => {
      console.log(`Server running on port ${PORT}`);
      console.log(`Health check: http://localhost:${PORT}/`);
      console.log(`Workouts API: http://localhost:${PORT}/api/workouts`);
    });

  } catch (error) {
    console.error('MySQL connection failed:', error.message);
    process.exit(1);
  }
}

startServer();
