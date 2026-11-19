import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable Tracky Brand Logo widget displaying the custom fitness analytics logo.
/// Includes graceful fallback if asset image is not loaded.
class AppLogo extends StatelessWidget {
  final double size;
  final double borderRadius;
  final bool showBorder;

  const AppLogo({
    super.key,
    this.size = 36,
    this.borderRadius = 10,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: showBorder ? Border.all(color: AppTheme.border, width: 1) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius - (showBorder ? 1 : 0)),
        child: Image.asset(
          'assets/images/logo.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: AppTheme.primaryBlack,
              child: Icon(
                Icons.fitness_center_rounded,
                size: size * 0.5,
                color: Colors.white,
              ),
            );
          },
        ),
      ),
    );
  }
}
