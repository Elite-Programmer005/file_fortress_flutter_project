import 'package:flutter/material.dart';
import 'package:file_fortress/core/themes/app_theme.dart';

/// Smooth fade-in transition from top with optional scale animation.
class FadeInUp extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final int delayMs;

  const FadeInUp({
    super.key,
    required this.child,
    this.duration = AppTheme.animationDuration,
    this.curve = Curves.easeOut,
    this.delayMs = 0,
  });

  @override
  State<FadeInUp> createState() => _FadeInUpState();
}

class _FadeInUpState extends State<FadeInUp>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = Curves.easeOut.transform(_controller.value);
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Smooth fade-in transition with scale animation.
class FadeInScale extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final int delayMs;

  const FadeInScale({
    super.key,
    required this.child,
    this.duration = AppTheme.animationDuration,
    this.curve = Curves.easeOut,
    this.delayMs = 0,
  });

  @override
  State<FadeInScale> createState() => _FadeInScaleState();
}

class _FadeInScaleState extends State<FadeInScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = Curves.easeOut.transform(_controller.value);
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: 0.8 + (value * 0.2),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Smooth slide transition from left.
class SlideInLeft extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final int delayMs;

  const SlideInLeft({
    super.key,
    required this.child,
    this.duration = AppTheme.animationDuration,
    this.curve = Curves.easeOut,
    this.delayMs = 0,
  });

  @override
  State<SlideInLeft> createState() => _SlideInLeftState();
}

class _SlideInLeftState extends State<SlideInLeft>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = Curves.easeOut.transform(_controller.value);
        return Transform.translate(
          offset: Offset(-50 * (1 - value), 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
