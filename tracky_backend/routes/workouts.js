const express = require('express');
const router = express.Router();
const pool = require('../config/db');

/**
 * Helper function to calculate workout metrics:
 * - totalSets: sum of sets across all exercises
 * - totalReps: sum of (sets * reps) across all exercises
 * - totalVolume: sum of (sets * reps * weight) across all exercises (in kg)
 */
function calculateWorkoutTotals(exercises = []) {
  let totalSets = 0;
  let totalReps = 0;
  let totalVolume = 0;

  for (const exercise of exercises) {
    const sets = Number(exercise.sets) || 0;
    const reps = Number(exercise.reps) || 0;
    const weightKg = Number(exercise.weightKg ?? exercise.weight_kg ?? exercise.weight ?? 0);

    totalSets += sets;
    totalReps += sets * reps;
    totalVolume += sets * reps * weightKg;
  }

  return {
    totalSets,
    totalReps,
    totalVolume: Math.round(totalVolume * 100) / 100 // Round to 2 decimal places
  };
}

function formatDbDate(d) {
  // Use LOCAL year/month/day to avoid UTC-offset shifting the date
  // e.g. MySQL returns 2026-11-18 as Date("2026-11-17T18:30:00.000Z") in IST,
  // so toISOString() would wrongly give "2026-11-17". We use local date parts instead.
  const date = d ? (d instanceof Date ? d : new Date(d)) : new Date();
  const yyyy = date.getFullYear();
  const mm   = String(date.getMonth() + 1).padStart(2, '0');
  const dd   = String(date.getDate()).padStart(2, '0');
  return `${yyyy}-${mm}-${dd}`;
}

/**
 * @route   POST /api/workouts
 * @desc    Save a new workout and its exercises
 */
router.post('/', async (req, res) => {
  const {
    date,
    workout_date,
    bodyWeightKg,
    body_weight_kg,
    body_weight,
    note,
    notes,
    exercises = []
  } = req.body;

  // Compute calculated metrics
  const { totalSets, totalReps, totalVolume } = calculateWorkoutTotals(exercises);

  const workoutDate = workout_date || date || new Date().toISOString().slice(0, 10);
  const weight = bodyWeightKg ?? body_weight_kg ?? body_weight ?? 0.0;
  const workoutNote = note !== undefined ? note : (notes !== undefined ? notes : null);

  // Obtain a single connection from the pool for a transaction
  const connection = await pool.getConnection();

  try {
    // Start SQL Transaction to ensure all-or-nothing execution
    await connection.beginTransaction();

    // 1. Insert workout into workout_logs table
    const [workoutResult] = await connection.query(
      `INSERT INTO workout_logs
   (workout_date, body_weight, notes, total_sets, total_reps, total_volume, date, body_weight_kg, note)
   VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [workoutDate, weight, workoutNote, totalSets, totalReps, totalVolume, workoutDate, weight, workoutNote]
    );

    const workoutId = workoutResult.insertId;
    const savedExercises = [];

    // 2. Insert associated exercises into exercises table
    if (Array.isArray(exercises) && exercises.length > 0) {
      for (const ex of exercises) {
        const name = ex.exercise_name || ex.name || 'Unnamed Exercise';
        const sets = Number(ex.sets) || 0;
        const reps = Number(ex.reps) || 0;
        const weightKg = Number(ex.weightKg ?? ex.weight_kg ?? ex.weight ?? 0);

        const [exResult] = await connection.query(
          `INSERT INTO exercises
(workout_id, exercise_name, sets, reps, weight_kg)
VALUES (?, ?, ?, ?, ?)`,
          [workoutId, name, sets, reps, weightKg]
        );

        savedExercises.push({
          id: String(exResult.insertId),
          name,
          sets,
          reps,
          weightKg
        });
      }
    }

    // Commit the transaction after all inserts succeed
    await connection.commit();

    // Return the newly created workout
    res.status(201).json({
      message: 'Workout saved successfully',
      id: String(workoutId),
      date: workoutDate,
      bodyWeightKg: Number(weight),
      note: workoutNote,
      totalSets,
      totalReps,
      totalVolume,
      exercises: savedExercises
    });
  } catch (error) {
    // Roll back changes if any query failed
    await connection.rollback();
    console.error('Error creating workout:', error);
    res.status(500).json({ error: 'Failed to save workout' });
  } finally {
    // Always release the connection back to the pool
    connection.release();
  }
});

/**
 * @route   GET /api/workouts
 * @desc    Retrieve all workouts with their exercises and totals
 */
router.get('/', async (req, res) => {
  try {
    // 1. Fetch all workouts ordered by date descending (newest first)
    const [workouts] = await pool.query(
      'SELECT * FROM workout_logs ORDER BY COALESCE(date, workout_date) DESC, id DESC'
    );

    if (workouts.length === 0) {
      return res.status(200).json([]);
    }

    // 2. Fetch all exercises for these workouts in a single efficient query
    const workoutIds = workouts.map(w => w.id);
    const [exercises] = await pool.query(
      'SELECT * FROM exercises WHERE workout_id IN (?) ORDER BY id ASC',
      [workoutIds]
    );

    // 3. Group exercises by workout_id
    const exercisesMap = {};
    for (const ex of exercises) {
      if (!exercisesMap[ex.workout_id]) {
        exercisesMap[ex.workout_id] = [];
      }
      exercisesMap[ex.workout_id].push({
        id: String(ex.id),
        name: ex.exercise_name,
        sets: Number(ex.sets),
        reps: Number(ex.reps),
        weightKg: Number(ex.weight_kg)
      });
    }

    // 4. Combine workouts with their respective exercises and ensure totals
    const formattedWorkouts = workouts.map(w => {
      const workoutExercises = exercisesMap[w.id] || [];
      const totals = calculateWorkoutTotals(workoutExercises);

      return {
        id: String(w.id),
        date: formatDbDate(w.date || w.workout_date),
        bodyWeightKg: Number(w.body_weight_kg ?? w.body_weight ?? 0),
        note: w.note ?? w.notes ?? '',
        totalSets: w.total_sets !== null && w.total_sets !== undefined ? Number(w.total_sets) : totals.totalSets,
        totalReps: w.total_reps !== null && w.total_reps !== undefined ? Number(w.total_reps) : totals.totalReps,
        totalVolume: w.total_volume !== null && w.total_volume !== undefined ? Number(w.total_volume) : totals.totalVolume,
        exercises: workoutExercises
      };
    });

    res.status(200).json(formattedWorkouts);
  } catch (error) {
    console.error('Error fetching workouts:', error);
    res.status(500).json({ error: 'Failed to retrieve workouts' });
  }
});

/**
 * @route   GET /api/workouts/:id
 * @desc    Retrieve a particular workout by ID
 */
router.get('/:id', async (req, res) => {
  const { id } = req.params;

  try {
    // 1. Fetch workout record by ID
    const [workouts] = await pool.query(
      'SELECT * FROM workout_logs WHERE id = ?',
      [id]
    );

    if (workouts.length === 0) {
      return res.status(404).json({ error: `Workout with ID ${id} not found` });
    }

    const workout = workouts[0];

    // 2. Fetch all exercises for this workout
    const [exercises] = await pool.query(
      'SELECT * FROM exercises WHERE workout_id = ? ORDER BY id ASC',
      [id]
    );

    const formattedExercises = exercises.map(ex => ({
      id: String(ex.id),
      name: ex.exercise_name,
      sets: Number(ex.sets),
      reps: Number(ex.reps),
      weightKg: Number(ex.weight_kg)
    }));

    const totals = calculateWorkoutTotals(formattedExercises);

    res.status(200).json({
      id: String(workout.id),
      date: formatDbDate(workout.date || workout.workout_date),
      bodyWeightKg: Number(workout.body_weight_kg ?? workout.body_weight ?? 0),
      note: workout.note ?? workout.notes ?? '',
      totalSets: workout.total_sets !== null && workout.total_sets !== undefined ? Number(workout.total_sets) : totals.totalSets,
      totalReps: workout.total_reps !== null && workout.total_reps !== undefined ? Number(workout.total_reps) : totals.totalReps,
      totalVolume: workout.total_volume !== null && workout.total_volume !== undefined ? Number(workout.total_volume) : totals.totalVolume,
      exercises: formattedExercises
    });
  } catch (error) {
    console.error('Error fetching workout:', error);
    res.status(500).json({ error: 'Failed to retrieve workout' });
  }
});

/**
 * @route   PUT /api/workouts/:id
 * @desc    Update an existing workout and optionally its exercises
 */
router.put('/:id', async (req, res) => {
  const { id } = req.params;
  const {
    date,
    workout_date,
    bodyWeightKg,
    body_weight_kg,
    body_weight,
    note,
    notes,
    exercises
  } = req.body;

  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();

    // 1. Check if the workout exists
    const [existing] = await connection.query(
      'SELECT * FROM workout_logs WHERE id = ?',
      [id]
    );

    if (existing.length === 0) {
      await connection.rollback();
      return res.status(404).json({ error: `Workout with ID ${id} not found` });
    }

    const currentWorkout = existing[0];
    const updatedDate = workout_date || date || currentWorkout.workout_date;

    const updatedBodyWeight =
      bodyWeightKg ?? body_weight_kg ?? body_weight ?? currentWorkout.body_weight;

    const updatedNote =
      note !== undefined ? note : (notes !== undefined ? notes : currentWorkout.notes);

    let updatedExercises = [];
    let totals;

    // 2. If exercises are provided, replace existing exercises and recalculate totals
    if (Array.isArray(exercises)) {
      totals = calculateWorkoutTotals(exercises);

      // Delete existing exercises for this workout
      await connection.query('DELETE FROM exercises WHERE workout_id = ?', [id]);

      // Re-insert updated exercises
      for (const ex of exercises) {
        const name = ex.exercise_name || ex.name || 'Unnamed Exercise';
        const sets = Number(ex.sets) || 0;
        const reps = Number(ex.reps) || 0;
        const weightKg = Number(ex.weightKg ?? ex.weight_kg ?? ex.weight ?? 0);

        const [exResult] = await connection.query(
          `INSERT INTO exercises (workout_id, exercise_name, sets, reps, weight_kg)
           VALUES (?, ?, ?, ?, ?)`,
          [id, name, sets, reps, weightKg]
        );

        updatedExercises.push({
          id: String(exResult.insertId),
          name,
          sets,
          reps,
          weightKg
        });
      }

      // Update workout_logs with new totals
      await connection.query(
        `UPDATE workout_logs
         SET workout_date = ?, body_weight = ?, notes = ?, total_sets = ?, total_reps = ?, total_volume = ?,
             date = ?, body_weight_kg = ?, note = ?
         WHERE id = ?`,
        [updatedDate, updatedBodyWeight, updatedNote, totals.totalSets, totals.totalReps, totals.totalVolume, updatedDate, updatedBodyWeight, updatedNote, id]
      );
    } else {
      // If exercises not provided, only update the workout metadata
      await connection.query(
        `UPDATE workout_logs
         SET workout_date = ?, body_weight = ?, notes = ?,
             date = ?, body_weight_kg = ?, note = ?
         WHERE id = ?`,
        [updatedDate, updatedBodyWeight, updatedNote, updatedDate, updatedBodyWeight, updatedNote, id]
      );

      // Fetch existing exercises
      const [currentExercises] = await connection.query(
        'SELECT * FROM exercises WHERE workout_id = ? ORDER BY id ASC',
        [id]
      );

      updatedExercises = currentExercises.map(ex => ({
        id: String(ex.id),
        name: ex.exercise_name,
        sets: Number(ex.sets),
        reps: Number(ex.reps),
        weightKg: Number(ex.weight_kg)
      }));
      totals = calculateWorkoutTotals(updatedExercises);
    }

    await connection.commit();

    res.status(200).json({
      message: 'Workout updated successfully',
      id: String(id),
      date: updatedDate,
      bodyWeightKg: Number(updatedBodyWeight),
      note: updatedNote,
      totalSets: totals.totalSets,
      totalReps: totals.totalReps,
      totalVolume: totals.totalVolume,
      exercises: updatedExercises
    });
  } catch (error) {
    await connection.rollback();
    console.error('Error updating workout:', error);
    res.status(500).json({ error: 'Failed to update workout' });
  } finally {
    connection.release();
  }
});

/**
 * @route   DELETE /api/workouts/:id
 * @desc    Delete a workout and its associated exercises
 */
router.delete('/:id', async (req, res) => {
  const { id } = req.params;

  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();

    // 1. Verify that the workout exists
    const [existing] = await connection.query(
      'SELECT id FROM workout_logs WHERE id = ?',
      [id]
    );

    if (existing.length === 0) {
      await connection.rollback();
      return res.status(404).json({ error: `Workout with ID ${id} not found` });
    }

    // 2. Delete child exercises first to maintain referential integrity
    await connection.query('DELETE FROM exercises WHERE workout_id = ?', [id]);

    // 3. Delete the parent workout log
    await connection.query('DELETE FROM workout_logs WHERE id = ?', [id]);

    await connection.commit();

    res.status(200).json({
      message: `Workout with ID ${id} deleted successfully`,
      id: String(id)
    });
  } catch (error) {
    await connection.rollback();
    console.error('Error deleting workout:', error);
    res.status(500).json({ error: 'Failed to delete workout' });
  } finally {
    connection.release();
  }
});

module.exports = router;
