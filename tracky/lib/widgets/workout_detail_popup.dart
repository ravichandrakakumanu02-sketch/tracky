import 'package:flutter/material.dart';
import '../models/exercise_model.dart';
import '../models/workout_model.dart';
import '../screens/add_workout_screen.dart';
import '../theme/app_theme.dart';
import '../utils/date_formatter.dart';
import 'app_logo.dart';

/// Modal popup displaying a comprehensive, clear view of a particular day's
/// workout session in a sleek White & Black design with micro orange touches.
class WorkoutDetailPopup extends StatelessWidget {
  final Workout workout;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const WorkoutDetailPopup({
    super.key,
    required this.workout,
    this.onDelete,
    this.onEdit,
  });

  /// Static helper to pop up this workout detail modal
  static Future<void> show(
    BuildContext context, {
    required Workout workout,
    VoidCallback? onDelete,
    VoidCallback? onEdit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => WorkoutDetailPopup(
        workout: workout,
        onDelete: onDelete,
        onEdit: onEdit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final relativeDate = DateFormatter.formatRelativeOrDate(workout.date);
    final fullDate = DateFormatter.formatFull(workout.date);

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.40,
      maxChildSize: 0.94,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.backgroundWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 24,
                offset: Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            children: [
              // Top Drag Handle & Title Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.border,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            const AppLogo(size: 34, borderRadius: 10),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      relativeDate,
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceMuted,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${workout.exercises.length} ex',
                                        style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  fullDate,
                                  style: const TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Action buttons (Edit & Close)
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                Navigator.pop(context);
                                if (onEdit != null) {
                                  onEdit!();
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          AddWorkoutScreen(workoutToEdit: workout),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.edit_outlined, size: 17),
                              color: AppTheme.textPrimary,
                              style: IconButton.styleFrom(
                                backgroundColor: AppTheme.surfaceMuted,
                                padding: const EdgeInsets.all(6),
                                minimumSize: const Size(32, 32),
                              ),
                              tooltip: 'Edit Workout',
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close_rounded, size: 20),
                              color: AppTheme.textSecondary,
                              style: IconButton.styleFrom(
                                backgroundColor: AppTheme.surfaceMuted,
                                padding: const EdgeInsets.all(6),
                                minimumSize: const Size(32, 32),
                              ),
                              tooltip: 'Close',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Scrollable Details
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 40),
                  children: [
                    // Key Metrics Cards (Overflow safe)
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricPill(
                            label: 'Body Weight',
                            value: '${workout.bodyWeightKg.toStringAsFixed(1)} kg',
                            icon: Icons.monitor_weight_outlined,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMetricPill(
                            label: 'Total Volume',
                            value: workout.totalVolumeKg > 0
                                ? '${workout.totalVolumeKg.toStringAsFixed(0)} kg'
                                : '--',
                            icon: Icons.speed_rounded,
                            showOrangeDot: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricPill(
                            label: 'Total Sets',
                            value: '${workout.totalSets}',
                            icon: Icons.repeat_rounded,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMetricPill(
                            label: 'Total Reps',
                            value: '${workout.totalReps}',
                            icon: Icons.trending_up_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Workout Note if present
                    if (workout.note != null && workout.note!.trim().isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceMuted,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.border, width: 0.8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.format_quote_rounded,
                              color: AppTheme.textSecondary,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                workout.note!,
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                  height: 1.4,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Exercise Breakdown Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Exercise Breakdown',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          '${workout.exercises.length} total',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Detailed exercise cards
                    ...workout.exercises.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final ex = entry.value;
                      return _buildDetailedExerciseCard(idx, ex);
                    }),

                    const SizedBox(height: 14),

                    // Delete workout button inside popup
                    if (onDelete != null)
                      Center(
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            onDelete?.call();
                          },
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 16,
                            color: AppTheme.errorRed,
                          ),
                          label: const Text(
                            'Delete This Workout Log',
                            style: TextStyle(
                              color: AppTheme.errorRed,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricPill({
    required String label,
    required String value,
    required IconData icon,
    bool showOrangeDot = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border, width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border, width: 0.8),
            ),
            child: Icon(icon, size: 15, color: AppTheme.textPrimary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Text(
                        value,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (showOrangeDot) ...[
                        const SizedBox(width: 4),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.accentOrange,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedExerciseCard(int index, Exercise exercise) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with number and name
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlack,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  exercise.name,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Chips row with sets, reps, weight, and volume (Wrap to guarantee no overflow)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildBadge(label: 'Sets', value: '${exercise.sets}'),
              _buildBadge(label: 'Reps', value: '${exercise.reps}'),
              _buildBadge(
                label: 'Weight',
                value:
                    '${exercise.weightKg.toStringAsFixed(exercise.weightKg % 1 == 0 ? 0 : 1)} kg',
                isHighlighted: true,
              ),
              if (exercise.weightKg > 0)
                _buildBadge(
                  label: 'Volume',
                  value: '${exercise.totalVolumeKg.toStringAsFixed(0)} kg',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({
    required String label,
    required String value,
    bool isHighlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isHighlighted ? AppTheme.primaryBlack : AppTheme.surfaceMuted,
        borderRadius: BorderRadius.circular(6),
        border: isHighlighted
            ? null
            : Border.all(color: AppTheme.border, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: isHighlighted ? Colors.white70 : AppTheme.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isHighlighted ? Colors.white : AppTheme.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
