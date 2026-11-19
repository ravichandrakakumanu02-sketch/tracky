import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Minimal, overflow-safe metric card with clean White & Black styling and minimal orange.
class StatMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final IconData icon;
  final bool showOrangeDot;

  const StatMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    required this.icon,
    this.showOrangeDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icon and minimal indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceMuted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 15,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (showOrangeDot)
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.accentOrange,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // Value & Unit with FittedBox to prevent any horizontal overflow
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                if (unit != null) ...[
                  const SizedBox(width: 2),
                  Text(
                    unit!,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 2),
          // Label
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// WorkoutSummarySection renders 3 compact, overflow-safe cards.
class WorkoutSummarySection extends StatelessWidget {
  final int totalDays;
  final double? latestWeightKg;
  final int totalSessions;

  const WorkoutSummarySection({
    super.key,
    required this.totalDays,
    required this.latestWeightKg,
    required this.totalSessions,
  });

  @override
  Widget build(BuildContext context) {
    final weightStr = latestWeightKg != null
        ? latestWeightKg!.toStringAsFixed(1)
        : '--';

    return Row(
      children: [
        Expanded(
          child: StatMetricCard(
            label: 'Total Days',
            value: '$totalDays',
            icon: Icons.calendar_today_rounded,
            showOrangeDot: totalDays > 0,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: StatMetricCard(
            label: 'Weight',
            value: weightStr,
            unit: latestWeightKg != null ? 'kg' : null,
            icon: Icons.monitor_weight_outlined,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: StatMetricCard(
            label: 'Sessions',
            value: '$totalSessions',
            icon: Icons.fitness_center_rounded,
          ),
        ),
      ],
    );
  }
}
