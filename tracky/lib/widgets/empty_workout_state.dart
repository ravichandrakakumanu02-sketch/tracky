import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'app_logo.dart';

/// Displayed when there are no saved workout logs.
class EmptyWorkoutState extends StatelessWidget {
  final VoidCallback onAddWorkout;
  final VoidCallback? onResetSampleData;

  const EmptyWorkoutState({
    super.key,
    required this.onAddWorkout,
    this.onResetSampleData,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Tracky Brand Logo
            const AppLogo(size: 76, borderRadius: 20),
            const SizedBox(height: 20),

            // Title
            const Text(
              'No workouts logged yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),

            // Required Message Subtitle
            const Text(
              'Start tracking your fitness journey!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),

            // Action Button
            ElevatedButton.icon(
              onPressed: onAddWorkout,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Today\'s Workout'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            if (onResetSampleData != null) ...[
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: onResetSampleData,
                icon: const Icon(Icons.refresh_rounded, size: 15, color: AppTheme.textMuted),
                label: const Text(
                  'Restore Demo Data',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
