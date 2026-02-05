import 'package:flutter/material.dart';
import 'package:file_fortress/core/themes/app_theme.dart';

/// An animated PIN circle indicator with smooth scale and color transitions.
class AnimatedPinCircle extends StatelessWidget {
  final bool filled;
  final Color filledColor;
  final Color emptyColor;
  final Duration animationDuration;

  const AnimatedPinCircle({
    super.key,
    required this.filled,
    this.filledColor = const Color(0xFF0052D4),
    this.emptyColor = Colors.grey,
    this.animationDuration = AppTheme.microAnimationDuration,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: filled ? 1.0 : 0.9,
      duration: animationDuration,
      child: AnimatedContainer(
        width: 16,
        height: 16,
        margin: const EdgeInsets.all(8),
        duration: animationDuration,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? filledColor : Colors.transparent,
          border: Border.all(
            color: filled ? filledColor : emptyColor,
            width: 2.5,
          ),
        ),
      ),
    );
  }
}
