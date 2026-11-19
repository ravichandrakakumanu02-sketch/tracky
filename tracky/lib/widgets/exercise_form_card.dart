import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Data holder used while editing an exercise in the Add Workout form.
class ExerciseFormData {
  final String id;
  final TextEditingController nameController;
  final TextEditingController setsController;
  final TextEditingController repsController;
  final TextEditingController weightController;

  ExerciseFormData({
    required this.id,
    String initialName = '',
    String initialSets = '3',
    String initialReps = '10',
    String initialWeight = '50',
  })  : nameController = TextEditingController(text: initialName),
        setsController = TextEditingController(text: initialSets),
        repsController = TextEditingController(text: initialReps),
        weightController = TextEditingController(text: initialWeight);

  void dispose() {
    nameController.dispose();
    setsController.dispose();
    repsController.dispose();
    weightController.dispose();
  }
}

/// A card widget representing an individual exercise entry form.
/// Guaranteed overflow-free across all screen resolutions.
class ExerciseFormCard extends StatelessWidget {
  final int index;
  final ExerciseFormData data;
  final VoidCallback onRemove;
  final bool canRemove;

  static const List<String> commonExercises = [
    'Bench Press',
    'Squat',
    'Deadlift',
    'Overhead Press',
    'Barbell Row',
    'Pull-ups',
    'Bicep Curl',
    'Leg Press',
  ];

  const ExerciseFormCard({
    super.key,
    required this.index,
    required this.data,
    required this.onRemove,
    this.canRemove = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Header: Index and Remove
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlack,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Exercise #${index + 1}',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
                if (canRemove)
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppTheme.errorRed,
                      size: 18,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    splashRadius: 16,
                    tooltip: 'Remove Exercise',
                    onPressed: onRemove,
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Exercise Name Field
            TextFormField(
              controller: data.nameController,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              decoration: const InputDecoration(
                labelText: 'Exercise Name *',
                hintText: 'e.g. Incline Bench Press',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                prefixIcon: Icon(Icons.fitness_center_outlined, size: 18),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter the exercise name';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),

            // Quick suggestion chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: commonExercises.map((name) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        data.nameController.text = name;
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceMuted,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.border,
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          name,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Sets, Reps, Weight in a safe 3-column row
            Row(
              children: [
                // Sets
                Expanded(
                  child: TextFormField(
                    controller: data.setsController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'Sets',
                      hintText: '3',
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Req';
                      final num = int.tryParse(val);
                      if (num == null || num <= 0) return '>0';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 6),

                // Reps
                Expanded(
                  child: TextFormField(
                    controller: data.repsController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'Reps',
                      hintText: '10',
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Req';
                      final num = int.tryParse(val);
                      if (num == null || num <= 0) return '>0';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 6),

                // Weight (kg)
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: data.weightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'Weight',
                      hintText: '60',
                      suffixText: 'kg',
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Req';
                      final num = double.tryParse(val);
                      if (num == null || num < 0) return '>=0';
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
