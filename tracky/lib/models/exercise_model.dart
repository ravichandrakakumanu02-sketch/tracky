/// Represents an individual exercise performed in a workout session.
class Exercise {
  final String id;
  final String name;
  final int sets;
  final int reps;
  final double weightKg;

  const Exercise({
    required this.id,
    required this.name,
    required this.sets,
    required this.reps,
    required this.weightKg,
  });

  /// Total volume lifted for this exercise in kg (sets * reps * weight).
  double get totalVolumeKg => sets * reps * weightKg;

  Map<String, dynamic> toMap() {
    return {
      if (id.isNotEmpty) 'id': id,
      'name': name,
      'exercise_name': name,
      'sets': sets,
      'reps': reps,
      'weightKg': weightKg,
      'weight_kg': weightKg,
    };
  }

  factory Exercise.fromMap(Map<String, dynamic> map) {
    final rawWeight = map['weightKg'] ?? map['weight_kg'] ?? map['weight'];
    final weight = (rawWeight is num)
        ? rawWeight.toDouble()
        : (double.tryParse(rawWeight?.toString() ?? '0') ?? 0.0);

    final rawSets = map['sets'];
    final sets = (rawSets is num)
        ? rawSets.toInt()
        : (int.tryParse(rawSets?.toString() ?? '0') ?? 0);

    final rawReps = map['reps'];
    final reps = (rawReps is num)
        ? rawReps.toInt()
        : (int.tryParse(rawReps?.toString() ?? '0') ?? 0);

    return Exercise(
      id: map['id']?.toString() ?? '',
      name: (map['name'] ?? map['exercise_name'] ?? '') as String,
      sets: sets,
      reps: reps,
      weightKg: weight,
    );
  }

  Exercise copyWith({
    String? id,
    String? name,
    int? sets,
    int? reps,
    double? weightKg,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weightKg: weightKg ?? this.weightKg,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Exercise &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          sets == other.sets &&
          reps == other.reps &&
          weightKg == other.weightKg;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      sets.hashCode ^
      reps.hashCode ^
      weightKg.hashCode;
}
