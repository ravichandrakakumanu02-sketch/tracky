import 'exercise_model.dart';

/// Represents a workout session log in Tracky.
class Workout {
  final String id;
  final DateTime date;
  final double bodyWeightKg;
  final List<Exercise> exercises;
  final String? note;

  const Workout({
    required this.id,
    required this.date,
    required this.bodyWeightKg,
    required this.exercises,
    this.note,
  });

  /// Total number of sets completed across all exercises in this workout.
  int get totalSets => exercises.fold(0, (sum, e) => sum + e.sets);

  /// Total number of reps completed across all exercises in this workout.
  int get totalReps => exercises.fold(0, (sum, e) => sum + (e.sets * e.reps));

  /// Total volume lifted across all exercises in kg.
  double get totalVolumeKg =>
      exercises.fold(0.0, (sum, e) => sum + e.totalVolumeKg);

  /// Number of unique exercises in this workout.
  int get exerciseCount => exercises.length;

  Map<String, dynamic> toMap() {
    final dateString = date.toIso8601String().split('T').first;
    return {
      if (id.isNotEmpty) 'id': id,
      'date': dateString,
      'workout_date': dateString,
      'bodyWeightKg': bodyWeightKg,
      'body_weight': bodyWeightKg,
      'body_weight_kg': bodyWeightKg,
      'note': note,
      'notes': note,
      'exercises': exercises.map((e) => e.toMap()).toList(),
    };
  }

  factory Workout.fromMap(Map<String, dynamic> map) {
    DateTime parsedDate = DateTime.now();
    final rawDate = map['date'] ?? map['workout_date'];
    if (rawDate != null) {
      parsedDate = DateTime.tryParse(rawDate.toString()) ?? DateTime.now();
    }

    final rawWeight = map['bodyWeightKg'] ?? map['body_weight_kg'] ?? map['body_weight'];
    final bodyWeight = (rawWeight is num)
        ? rawWeight.toDouble()
        : (double.tryParse(rawWeight?.toString() ?? '0') ?? 0.0);

    final rawExercises = map['exercises'];
    List<Exercise> exercisesList = [];
    if (rawExercises is List) {
      exercisesList = rawExercises
          .map((e) => Exercise.fromMap(
              e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    final rawNote = map['note'] ?? map['notes'];

    return Workout(
      id: map['id']?.toString() ?? '',
      date: parsedDate,
      bodyWeightKg: bodyWeight,
      exercises: exercisesList,
      note: rawNote?.toString(),
    );
  }

  Workout copyWith({
    String? id,
    DateTime? date,
    double? bodyWeightKg,
    List<Exercise>? exercises,
    String? note,
  }) {
    return Workout(
      id: id ?? this.id,
      date: date ?? this.date,
      bodyWeightKg: bodyWeightKg ?? this.bodyWeightKg,
      exercises: exercises ?? this.exercises,
      note: note ?? this.note,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Workout &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          date == other.date &&
          bodyWeightKg == other.bodyWeightKg &&
          note == other.note;

  @override
  int get hashCode =>
      id.hashCode ^ date.hashCode ^ bodyWeightKg.hashCode ^ (note?.hashCode ?? 0);
}
