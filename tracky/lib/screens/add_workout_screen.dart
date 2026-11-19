import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/exercise_model.dart';
import '../models/workout_model.dart';
import '../services/workout_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_formatter.dart';
import '../widgets/exercise_form_card.dart';

class AddWorkoutScreen extends StatefulWidget {
  final Workout? workoutToEdit;

  const AddWorkoutScreen({super.key, this.workoutToEdit});

  @override
  State<AddWorkoutScreen> createState() => _AddWorkoutScreenState();
}

class _AddWorkoutScreenState extends State<AddWorkoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final List<ExerciseFormData> _exerciseForms = [];
  bool _isSaving = false;

  bool get isEditing => widget.workoutToEdit != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final workout = widget.workoutToEdit!;
      _weightController.text = workout.bodyWeightKg.toStringAsFixed(1);
      _noteController.text = workout.note ?? '';
      if (workout.exercises.isNotEmpty) {
        for (final ex in workout.exercises) {
          _exerciseForms.add(
            ExerciseFormData(
              id: ex.id.isNotEmpty ? ex.id : 'ex_${DateTime.now().microsecondsSinceEpoch}',
              initialName: ex.name,
              initialSets: ex.sets.toString(),
              initialReps: ex.reps.toString(),
              initialWeight: ex.weightKg.toStringAsFixed(ex.weightKg % 1 == 0 ? 0 : 1),
            ),
          );
        }
      } else {
        _addExercise();
      }
    } else {
      // Pre-fill body weight with the latest recorded weight if available
      final latestWeight = WorkoutService().latestBodyWeight;
      if (latestWeight != null) {
        _weightController.text = latestWeight.toStringAsFixed(1);
      }
      // Start with one exercise ready to fill
      _addExercise();
    }
  }

  void _addExercise() {
    setState(() {
      _exerciseForms.add(
        ExerciseFormData(
          id: 'temp_${DateTime.now().microsecondsSinceEpoch}',
          initialName: '',
          initialSets: '3',
          initialReps: '10',
          initialWeight: '50',
        ),
      );
    });
  }

  void _removeExercise(int index) {
    if (_exerciseForms.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least one exercise is required in a workout.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() {
      final removed = _exerciseForms.removeAt(index);
      removed.dispose();
    });
  }

  Future<void> _saveWorkout() async {
    // Dismiss soft keyboard
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please correct the highlighted fields before saving.'),
          backgroundColor: AppTheme.errorRed,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_exerciseForms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one exercise.'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    final bodyWeight = double.tryParse(_weightController.text.trim());
    if (bodyWeight == null || bodyWeight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid positive body weight.'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final exercises = _exerciseForms.map((form) {
        return Exercise(
          id: 'ex_${DateTime.now().microsecondsSinceEpoch}_${form.id}',
          name: form.nameController.text.trim(),
          sets: int.tryParse(form.setsController.text.trim()) ?? 1,
          reps: int.tryParse(form.repsController.text.trim()) ?? 1,
          weightKg: double.tryParse(form.weightController.text.trim()) ?? 0.0,
        );
      }).toList();

      final now = DateTime.now();
      final workout = Workout(
        id: isEditing ? widget.workoutToEdit!.id : '',
        date: isEditing ? widget.workoutToEdit!.date : now,
        bodyWeightKg: bodyWeight,
        exercises: exercises,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );

      final success = isEditing
          ? await WorkoutService().updateWorkout(workout)
          : await WorkoutService().addWorkout(workout);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.primaryBlack,
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  isEditing
                      ? 'Workout updated successfully! 💪'
                      : 'Workout saved successfully! 💪',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              WorkoutService().errorMessage ??
                  (isEditing ? 'Failed to update workout.' : 'Failed to save workout.'),
            ),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _noteController.dispose();
    for (final form in _exerciseForms) {
      form.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenDate = isEditing ? widget.workoutToEdit!.date : DateTime.now();
    final todayFormatted = DateFormatter.formatFull(screenDate);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditing ? 'Edit Workout' : 'Today\'s Workout',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              todayFormatted,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveWorkout,
            child: Text(
              isEditing ? 'Update' : 'Save',
              style: const TextStyle(
                color: AppTheme.primaryBlack,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 90),
          children: [
            // Section 1: Body Weight Section
            _buildSectionHeader(
              title: 'Body Weight',
              icon: Icons.monitor_weight_outlined,
              badge: 'Required',
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Record your weight before the session to track body composition trends.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Today\'s Body Weight *',
                      hintText: 'e.g. 74.5',
                      suffixText: 'kg',
                      prefixIcon: Icon(
                        Icons.monitor_weight_outlined,
                        size: 18,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter your body weight';
                      }
                      final weight = double.tryParse(val);
                      if (weight == null || weight <= 0) {
                        return 'Please enter a valid positive weight';
                      }
                      if (weight > 500) {
                        return 'Please enter a realistic weight value';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section 2: Exercise Section
            _buildSectionHeader(
              title: 'Exercises',
              icon: Icons.fitness_center_rounded,
              badge: '${_exerciseForms.length} added',
            ),
            const SizedBox(height: 10),

            // Exercise Cards List
            ..._exerciseForms.asMap().entries.map((entry) {
              final index = entry.key;
              final formData = entry.value;
              return ExerciseFormCard(
                key: ValueKey(formData.id),
                index: index,
                data: formData,
                canRemove: _exerciseForms.length > 1,
                onRemove: () => _removeExercise(index),
              );
            }),

            // Add Another Exercise Button
            OutlinedButton.icon(
              onPressed: _addExercise,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Another Exercise'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
                side: const BorderSide(color: AppTheme.primaryBlack, width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Section 3: Optional Workout Note
            _buildSectionHeader(
              title: 'Workout Note (Optional)',
              icon: Icons.note_alt_outlined,
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border, width: 1),
              ),
              child: TextFormField(
                controller: _noteController,
                maxLines: 2,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                decoration: const InputDecoration(
                  fillColor: Colors.transparent,
                  hintText: 'How was your energy? e.g. Felt great on bench press, hit a new PR!',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 24),
                    child: Icon(Icons.edit_note_rounded, size: 18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // Prominent Solid Black Save Workout Button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: const Border(
            top: BorderSide(color: AppTheme.border, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(6),
              blurRadius: 14,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveWorkout,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        isEditing ? 'Update Workout' : 'Save Workout',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    String? badge,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.textPrimary),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        if (badge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.surfaceMuted,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.border, width: 0.8),
            ),
            child: Text(
              badge,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}
