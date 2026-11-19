import 'package:flutter/material.dart';
import '../models/workout_model.dart';
import '../theme/app_theme.dart';
import '../utils/date_formatter.dart';

/// Minimal, compact calendar widget designed with a sleek White & Black aesthetic.
/// Features tiny cells with micro orange indicator dots for workout days,
/// and eliminates all overflow risks.
class WorkoutCalendar extends StatefulWidget {
  final List<Workout> workouts;
  final Function(Workout workout) onWorkoutSelected;

  const WorkoutCalendar({
    super.key,
    required this.workouts,
    required this.onWorkoutSelected,
  });

  @override
  State<WorkoutCalendar> createState() => _WorkoutCalendarState();
}

class _WorkoutCalendarState extends State<WorkoutCalendar> {
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayedMonth = DateTime(now.year, now.month, 1);
  }

  void _previousMonth() {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month - 1,
        1,
      );
    });
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + 1,
        1,
      );
    });
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _displayedMonth = DateTime(now.year, now.month, 1);
    });
  }

  Map<String, List<Workout>> _buildWorkoutDateMap() {
    final map = <String, List<Workout>>{};
    for (final w in widget.workouts) {
      final key =
          '${w.date.year}-${w.date.month.toString().padLeft(2, '0')}-${w.date.day.toString().padLeft(2, '0')}';
      map.putIfAbsent(key, () => []).add(w);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final workoutMap = _buildWorkoutDateMap();
    final now = DateTime.now();
    final monthShort = DateFormatter.formatShort(_displayedMonth).split(' ')[1];
    final year = _displayedMonth.year;

    final firstDayOfMonth = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final daysInMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;
    final startingWeekday = firstDayOfMonth.weekday; // 1 (Mon) .. 7 (Sun)

    // Count workout days in current month
    int monthWorkoutCount = 0;
    for (int d = 1; d <= daysInMonth; d++) {
      final key =
          '${_displayedMonth.year}-${_displayedMonth.month.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
      if (workoutMap.containsKey(key)) {
        monthWorkoutCount++;
      }
    }

    final totalGridCells = (startingWeekday - 1) + daysInMonth;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Compact Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$monthShort $year',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (monthWorkoutCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.accentOrangeLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.accentOrange,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$monthWorkoutCount logged',
                            style: const TextStyle(
                              color: AppTheme.accentOrange,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              // Compact Prev / Today / Next Controls
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 20),
                    color: AppTheme.textSecondary,
                    onPressed: _previousMonth,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                    splashRadius: 14,
                    tooltip: 'Previous Month',
                  ),
                  const SizedBox(width: 2),
                  InkWell(
                    onTap: _goToToday,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceMuted,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Today',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 20),
                    color: AppTheme.textSecondary,
                    onPressed: _nextMonth,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                    splashRadius: 14,
                    tooltip: 'Next Month',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Micro Weekday Headers (M T W T F S S)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _MiniWeekday('M'),
              _MiniWeekday('T'),
              _MiniWeekday('W'),
              _MiniWeekday('T'),
              _MiniWeekday('F'),
              _MiniWeekday('S'),
              _MiniWeekday('S'),
            ],
          ),
          const SizedBox(height: 4),

          // Mini Days Grid (Compact, small cells)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalGridCells,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1.15,
            ),
            itemBuilder: (context, index) {
              if (index < startingWeekday - 1) {
                return const SizedBox.shrink();
              }

              final dayNumber = index - (startingWeekday - 1) + 1;
              final dateKey =
                  '${_displayedMonth.year}-${_displayedMonth.month.toString().padLeft(2, '0')}-${dayNumber.toString().padLeft(2, '0')}';
              final dayWorkouts = workoutMap[dateKey];
              final hasWorkout = dayWorkouts != null && dayWorkouts.isNotEmpty;

              final isToday = now.year == _displayedMonth.year &&
                  now.month == _displayedMonth.month &&
                  now.day == dayNumber;

              return InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  if (hasWorkout) {
                    widget.onWorkoutSelected(dayWorkouts.first);
                  } else {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'No workout logged on $dayNumber $monthShort.',
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
                },
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: hasWorkout
                        ? AppTheme.primaryBlack
                        : isToday
                            ? AppTheme.surfaceMuted
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isToday && !hasWorkout
                        ? Border.all(color: AppTheme.border, width: 1)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$dayNumber',
                        style: TextStyle(
                          color: hasWorkout
                              ? Colors.white
                              : isToday
                                  ? AppTheme.textPrimary
                                  : AppTheme.textSecondary,
                          fontSize: 11,
                          fontWeight: hasWorkout || isToday
                              ? FontWeight.w800
                              : FontWeight.w500,
                        ),
                      ),
                      if (hasWorkout)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 3.5,
                          height: 3.5,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.accentOrange,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MiniWeekday extends StatelessWidget {
  final String text;
  const _MiniWeekday(this.text);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppTheme.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
