import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/exercise_model.dart';
import '../models/workout_model.dart';
import 'api_service.dart';

/// Abstract repository interface representing data source contracts.
abstract class WorkoutRepository {
  Future<List<Workout>> getWorkouts();
  Future<void> saveWorkout(Workout workout);
  Future<void> updateWorkout(Workout workout);
  Future<void> deleteWorkout(String id);
  Future<void> clearAll();
}

/// Node.js + Express + MySQL API repository implementing [WorkoutRepository].
class ApiWorkoutRepository implements WorkoutRepository {
  final ApiService _apiService;

  ApiWorkoutRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  @override
  Future<List<Workout>> getWorkouts() => _apiService.getWorkouts();

  @override
  Future<void> saveWorkout(Workout workout) async {
    await _apiService.createWorkout(workout);
  }

  @override
  Future<void> updateWorkout(Workout workout) async {
    await _apiService.updateWorkout(workout);
  }

  @override
  Future<void> deleteWorkout(String id) => _apiService.deleteWorkout(id);

  @override
  Future<void> clearAll() async {
    final list = await _apiService.getWorkouts();
    for (final w in list) {
      try {
        await _apiService.deleteWorkout(w.id);
      } catch (_) {}
    }
  }
}

/// In-memory and local repository implementing [WorkoutRepository].
/// Provides seamless local storage and comes with initial realistic workout data.
class LocalWorkoutRepository implements WorkoutRepository {
  final List<Workout> _storage = [];

  LocalWorkoutRepository({bool seedInitialData = true}) {
    if (seedInitialData) {
      _seedDemoWorkouts();
    }
  }

  void _seedDemoWorkouts() {
    final now = DateTime.now();
    _storage.addAll([
      Workout(
        id: 'workout_seed_1',
        date: now.subtract(const Duration(days: 1)),
        bodyWeightKg: 75.5,
        note: 'Chest and Triceps push day. Felt strong on bench!',
        exercises: const [
          Exercise(
            id: 'ex_1_1',
            name: 'Barbell Bench Press',
            sets: 4,
            reps: 8,
            weightKg: 80.0,
          ),
          Exercise(
            id: 'ex_1_2',
            name: 'Incline Dumbbell Press',
            sets: 3,
            reps: 10,
            weightKg: 28.0,
          ),
          Exercise(
            id: 'ex_1_3',
            name: 'Cable Tricep Pushdown',
            sets: 3,
            reps: 12,
            weightKg: 35.0,
          ),
        ],
      ),
      Workout(
        id: 'workout_seed_2',
        date: now.subtract(const Duration(days: 3)),
        bodyWeightKg: 75.8,
        note: 'Leg day focus on quad strength.',
        exercises: const [
          Exercise(
            id: 'ex_2_1',
            name: 'Barbell Back Squat',
            sets: 5,
            reps: 5,
            weightKg: 100.0,
          ),
          Exercise(
            id: 'ex_2_2',
            name: 'Romanian Deadlift',
            sets: 4,
            reps: 8,
            weightKg: 90.0,
          ),
          Exercise(
            id: 'ex_2_3',
            name: 'Leg Press',
            sets: 3,
            reps: 12,
            weightKg: 160.0,
          ),
        ],
      ),
      Workout(
        id: 'workout_seed_3',
        date: now.subtract(const Duration(days: 5)),
        bodyWeightKg: 76.0,
        note: 'Back & Biceps pull day.',
        exercises: const [
          Exercise(
            id: 'ex_3_1',
            name: 'Deadlift',
            sets: 4,
            reps: 6,
            weightKg: 120.0,
          ),
          Exercise(
            id: 'ex_3_2',
            name: 'Pull-ups',
            sets: 3,
            reps: 10,
            weightKg: 0.0,
          ),
          Exercise(
            id: 'ex_3_3',
            name: 'Barbell Bicep Curl',
            sets: 3,
            reps: 12,
            weightKg: 30.0,
          ),
        ],
      ),
    ]);
  }

  @override
  Future<List<Workout>> getWorkouts() async {
    // Simulate brief asynchronous database retrieval
    await Future.delayed(const Duration(milliseconds: 150));
    return List<Workout>.from(_storage);
  }

  @override
  Future<void> saveWorkout(Workout workout) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final existingIndex =
        workout.id.isEmpty ? -1 : _storage.indexWhere((w) => w.id == workout.id);
    if (existingIndex >= 0) {
      _storage[existingIndex] = workout;
    } else {
      final toAdd = workout.id.isEmpty
          ? workout.copyWith(id: 'workout_${DateTime.now().millisecondsSinceEpoch}')
          : workout;
      _storage.add(toAdd);
    }
  }

  @override
  Future<void> updateWorkout(Workout workout) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final index = _storage.indexWhere((w) => w.id == workout.id);
    if (index >= 0) {
      _storage[index] = workout;
    }
  }

  @override
  Future<void> deleteWorkout(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _storage.removeWhere((w) => w.id == id);
  }

  @override
  Future<void> clearAll() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _storage.clear();
  }
}

/// Service that coordinates workout data, manages loading states,
/// exposes analytics/metrics, and notifies listeners on updates.
class WorkoutService extends ChangeNotifier {
  static final WorkoutService _instance = WorkoutService._internal();
  factory WorkoutService() => _instance;

  WorkoutRepository _repository;

  WorkoutService._internal({WorkoutRepository? repository})
      : _repository = repository ?? ApiWorkoutRepository() {
    loadWorkouts();
  }

  // Visible for testing or injecting alternative repositories
  WorkoutService.withRepository(this._repository) {
    loadWorkouts();
  }

  /// Change data source repository at runtime (e.g. for testing or local mode).
  void setRepository(WorkoutRepository repository) {
    _repository = repository;
    loadWorkouts();
  }

  List<Workout> _workouts = [];
  bool _isLoading = false;
  String? _errorMessage;

  /// Workouts in reverse chronological order (newest first).
  List<Workout> get workouts => List.unmodifiable(_workouts);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Total workout days (distinct calendar dates).
  int get totalWorkoutDays {
    final uniqueDates = <String>{};
    for (final w in _workouts) {
      final key = '${w.date.year}-${w.date.month.toString().padLeft(2, '0')}-${w.date.day.toString().padLeft(2, '0')}';
      uniqueDates.add(key);
    }
    return uniqueDates.length;
  }

  /// Latest recorded body weight from the most recent workout, or null if none.
  double? get latestBodyWeight {
    if (_workouts.isEmpty) return null;
    // Workouts are kept sorted reverse-chronologically, so first item is latest.
    return _workouts.first.bodyWeightKg;
  }

  /// Total workout sessions logged.
  int get totalWorkoutSessions => _workouts.length;

  /// Fetch workouts from the repository.
  Future<void> loadWorkouts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final list = await _repository.getWorkouts();
      _sortReverseChronological(list);
      _workouts = list;
    } catch (e) {
      _errorMessage = 'Failed to load workouts: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new workout log.
  Future<bool> addWorkout(Workout workout) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.saveWorkout(workout);
      await loadWorkouts();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to save workout: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete a workout log by id.
  Future<bool> deleteWorkout(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.deleteWorkout(id);
      _workouts.removeWhere((w) => w.id == id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete workout: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update an existing workout log.
  Future<bool> updateWorkout(Workout workout) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.updateWorkout(workout);
      await loadWorkouts();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update workout: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Clears in-memory workout state upon user logout without affecting database.
  void clearActiveSessionWorkouts() {
    _workouts.clear();
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Clear all workouts (useful for testing empty states).
  Future<void> clearAll() async {
    await _repository.clearAll();
    _workouts.clear();
    notifyListeners();
  }

  /// Reset to sample workout data.
  Future<void> resetToSampleData() async {
    await _repository.clearAll();
    final repo = LocalWorkoutRepository(seedInitialData: true);
    final demoList = await repo.getWorkouts();
    for (final w in demoList) {
      await _repository.saveWorkout(w);
    }
    await loadWorkouts();
  }

  void _sortReverseChronological(List<Workout> list) {
    list.sort((a, b) => b.date.compareTo(a.date));
  }
}
