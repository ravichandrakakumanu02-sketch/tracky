import 'package:flutter/material.dart';
import '../models/workout_model.dart';
import '../services/auth_service.dart';
import '../services/workout_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_formatter.dart';
import '../widgets/app_logo.dart';
import '../widgets/empty_workout_state.dart';
import '../widgets/profile_sheet.dart';
import '../widgets/summary_card.dart';
import '../widgets/workout_card.dart';
import '../widgets/workout_calendar.dart';
import '../widgets/workout_detail_popup.dart';
import 'add_workout_screen.dart';
import 'ai_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WorkoutService _workoutService = WorkoutService();

  void _navigateToAddWorkout() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const AddWorkoutScreen()),
    );
    if (result == true) {
      await _workoutService.loadWorkouts();
    }
  }

  void _navigateToAI() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const AIScreen()));
  }

  void _navigateToEditWorkout(Workout workout) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddWorkoutScreen(workoutToEdit: workout),
      ),
    );
    if (result == true) {
      await _workoutService.loadWorkouts();
    }
  }

  void _openWorkoutPopup(Workout workout) {
    WorkoutDetailPopup.show(
      context,
      workout: workout,
      onDelete: () => _deleteWorkout(workout.id),
      onEdit: () => _navigateToEditWorkout(workout),
    );
  }

  Future<void> _deleteWorkout(String workoutId) async {
    final success = await _workoutService.deleteWorkout(workoutId);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Workout removed from history.'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _workoutService.errorMessage ?? 'Failed to delete workout.',
          ),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  void _openProfile() async {
    final user = await AuthService().fetchCurrentUser();
    if (!mounted) return;
    if (user != null) {
      ProfileSheet.show(context, user: user);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to load user profile. Please check your connection.',
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final todayFormatted = DateFormatter.formatFull(DateTime.now());

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _workoutService,
          builder: (_, __) {
            final workouts = _workoutService.workouts;
            final totalDays = _workoutService.totalWorkoutDays;
            final latestWeight = _workoutService.latestBodyWeight;
            final totalSessions = _workoutService.totalWorkoutSessions;
            final isLoading = _workoutService.isLoading;
            final error = _workoutService.errorMessage;

            return RefreshIndicator(
              color: AppTheme.primaryBlack,
              backgroundColor: Colors.white,
              onRefresh: () async {
                await _workoutService.loadWorkouts();
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  // Minimal White & Black Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // App Bar Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: const [
                                  AppLogo(size: 34, borderRadius: 10),
                                  SizedBox(width: 10),
                                  Text(
                                    'Tracky',
                                    style: TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.7,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  // AI Assistant Button
                                  InkWell(
                                    onTap: _navigateToAI,
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppTheme.accentOrangeLight,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppTheme.accentOrangeBorder,
                                          width: 1,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.auto_awesome,
                                        color: AppTheme.accentOrange,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Profile Button
                                  InkWell(
                                    onTap: _openProfile,
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.surface,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppTheme.border,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          CircleAvatar(
                                            radius: 11,
                                            backgroundColor:
                                                AppTheme.primaryBlack,
                                            child: Text(
                                              AuthService()
                                                      .currentUser
                                                      ?.initials ??
                                                  '?',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 9,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 7),
                                          Text(
                                            AuthService().currentUser?.name
                                                    .split(' ')
                                                    .first ??
                                                'Profile',
                                            style: const TextStyle(
                                              color: AppTheme.textPrimary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Welcome Message & Date
                          Text(
                            'Welcome back${AuthService().currentUser != null ? ', ${AuthService().currentUser!.name.split(' ').first}' : ''}! 💪',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            todayFormatted,
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Workout Summary Section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          WorkoutSummarySection(
                            totalDays: totalDays,
                            latestWeightKg: latestWeight,
                            totalSessions: totalSessions,
                          ),
                          const SizedBox(height: 18),

                          // Calendar Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                'Workout Calendar',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              Text(
                                'Tap day to view',
                                style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Minimal, Small Calendar
                          WorkoutCalendar(
                            workouts: workouts,
                            onWorkoutSelected: _openWorkoutPopup,
                          ),
                          const SizedBox(height: 22),

                          // Workout History Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Workout History',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              if (workouts.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceMuted,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppTheme.border,
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    '${workouts.length} ${workouts.length == 1 ? 'log' : 'logs'}',
                                    style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),

                  // Loading State
                  if (isLoading && workouts.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryBlack,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  // Error Banner if present
                  else if (error != null && workouts.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: AppTheme.errorRed,
                                size: 40,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                error,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 14),
                              ElevatedButton(
                                onPressed: () => _workoutService.loadWorkouts(),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  // Empty State if no workouts logged
                  else if (workouts.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyWorkoutState(
                        onAddWorkout: _navigateToAddWorkout,
                        onResetSampleData:
                            () => _workoutService.resetToSampleData(),
                      ),
                    )
                  // Workout History List (Reverse Chronological: newest first)
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 90),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final workout = workouts[index];
                          return WorkoutCard(
                            workout: workout,
                            onDelete: () => _deleteWorkout(workout.id),
                            onEdit: () => _navigateToEditWorkout(workout),
                          );
                        }, childCount: workouts.length),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
      // Prominent Black Floating Action Button: "Add Today's Workout"
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddWorkout,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text(
          'Add Today\'s Workout',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ),
    );
  }
}
