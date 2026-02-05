import 'dart:math' as math;

import 'package:file_fortress/core/themes/app_theme.dart';
import 'package:flutter/material.dart';

class PatternPad extends StatefulWidget {
  final Color activeColor;
  final Color inactiveColor;
  final Color errorColor;
  final bool showError;
  final ValueChanged<List<int>>? onChanged;
  final ValueChanged<List<int>>? onCompleted;

  const PatternPad({
    super.key,
    required this.activeColor,
    required this.inactiveColor,
    required this.errorColor,
    this.showError = false,
    this.onChanged,
    this.onCompleted,
  });

  @override
  PatternPadState createState() => PatternPadState();
}

class PatternPadState extends State<PatternPad> {
  final List<int> _pattern = [];
  Offset? _currentPosition;
  bool _isDrawing = false;

  List<int> get pattern => List.unmodifiable(_pattern);

  void clear() {
    setState(() {
      _pattern.clear();
      _currentPosition = null;
      _isDrawing = false;
    });
  }

  int? _hitTestIndex(Offset position, List<Offset> centers, double hitRadius) {
    for (var i = 0; i < centers.length; i++) {
      if ((centers[i] - position).distance <= hitRadius) {
        return i;
      }
    }
    return null;
  }

  int? _intermediateIndex(int fromIndex, int toIndex) {
    final fromRow = fromIndex ~/ 3;
    final fromCol = fromIndex % 3;
    final toRow = toIndex ~/ 3;
    final toCol = toIndex % 3;
    final dr = toRow - fromRow;
    final dc = toCol - fromCol;

    if (dr.abs() == 2 || dc.abs() == 2) {
      if (dr % 2 == 0 && dc % 2 == 0) {
        final midRow = fromRow + dr ~/ 2;
        final midCol = fromCol + dc ~/ 2;
        return midRow * 3 + midCol;
      }
    }
    return null;
  }

  void _addIndex(int index) {
    if (_pattern.contains(index)) return;

    if (_pattern.isNotEmpty) {
      final mid = _intermediateIndex(_pattern.last, index);
      if (mid != null && !_pattern.contains(mid)) {
        _pattern.add(mid);
      }
    }

    _pattern.add(index);
  }

  double _distanceToSegment(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final ap = p - a;
    final abLen2 = ab.dx * ab.dx + ab.dy * ab.dy;
    if (abLen2 == 0) return ap.distance;
    final t = (ap.dx * ab.dx + ap.dy * ab.dy) / abLen2;
    final clamped = t.clamp(0.0, 1.0);
    final projection = Offset(a.dx + ab.dx * clamped, a.dy + ab.dy * clamped);
    return (p - projection).distance;
  }

  bool _handlePosition(
    Offset position,
    List<Offset> centers,
    double hitRadius,
  ) {
    if (!_isDrawing) return false;

    final lastCenter = _pattern.isNotEmpty ? centers[_pattern.last] : null;

    if (lastCenter != null) {
      final candidates = <Map<String, dynamic>>[];
      for (var i = 0; i < centers.length; i++) {
        if (_pattern.contains(i)) continue;
        final dist = _distanceToSegment(centers[i], lastCenter, position);
        if (dist <= hitRadius) {
          final ab = position - lastCenter;
          final ap = centers[i] - lastCenter;
          final abLen2 = ab.dx * ab.dx + ab.dy * ab.dy;
          final t =
              abLen2 == 0 ? 0.0 : (ap.dx * ab.dx + ap.dy * ab.dy) / abLen2;
          if (t >= 0.0 && t <= 1.0) {
            candidates.add({'index': i, 't': t});
          }
        }
      }
      candidates.sort((a, b) => (a['t'] as double).compareTo(b['t'] as double));

      if (candidates.isNotEmpty) {
        for (final candidate in candidates) {
          _addIndex(candidate['index'] as int);
        }
        widget.onChanged?.call(List.unmodifiable(_pattern));
        return true;
      }
    }

    final hitIndex = _hitTestIndex(position, centers, hitRadius);
    if (hitIndex == null) return false;

    _addIndex(hitIndex);
    widget.onChanged?.call(List.unmodifiable(_pattern));
    return true;
  }

  void _finishPattern() {
    setState(() {
      _isDrawing = false;
      _currentPosition = null;
    });
    if (_pattern.isEmpty) return;
    widget.onCompleted?.call(List.unmodifiable(_pattern));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight);
        final cellSize = size / 3;
        final centers = List.generate(
          9,
          (index) {
            final col = index % 3;
            final row = index ~/ 3;
            return Offset(
              (col + 0.5) * cellSize,
              (row + 0.5) * cellSize,
            );
          },
        );
        final hitRadius = cellSize * 0.35;

        return SizedBox(
          width: size,
          height: size,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (details) {
              setState(() {
                _isDrawing = true;
                _currentPosition = details.localPosition;
                _handlePosition(details.localPosition, centers, hitRadius);
              });
            },
            onPanUpdate: (details) {
              setState(() {
                _currentPosition = details.localPosition;
                _handlePosition(details.localPosition, centers, hitRadius);
              });
            },
            onPanEnd: (_) => _finishPattern(),
            onPanCancel: () => _finishPattern(),
            onTapDown: (details) {
              setState(() {
                _isDrawing = true;
                _currentPosition = details.localPosition;
                _handlePosition(details.localPosition, centers, hitRadius);
              });
            },
            onTapUp: (_) => _finishPattern(),
            child: Stack(
              children: [
                CustomPaint(
                  size: Size(size, size),
                  painter: _PatternPainter(
                    centers: centers,
                    pattern: _pattern,
                    color: widget.showError
                        ? widget.errorColor
                        : widget.activeColor,
                    currentPosition: _currentPosition,
                    isDrawing: _isDrawing,
                  ),
                ),
                IgnorePointer(
                  child: GridView.count(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    crossAxisCount: 3,
                    children: List.generate(
                      9,
                      (index) => _PatternDot(
                        isSelected: _pattern.contains(index),
                        activeColor: widget.showError
                            ? widget.errorColor
                            : widget.activeColor,
                        inactiveColor: widget.inactiveColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PatternDot extends StatelessWidget {
  final bool isSelected;
  final Color activeColor;
  final Color inactiveColor;

  const _PatternDot({
    required this.isSelected,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final dotColor = isSelected ? activeColor : inactiveColor;
    return Center(
      child: AnimatedContainer(
        duration: AppTheme.microAnimationDuration,
        width: isSelected ? 18 : 14,
        height: isSelected ? 18 : 14,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? dotColor.withOpacity(0.2) : Colors.transparent,
          border: Border.all(color: dotColor, width: 2.2),
        ),
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  final List<Offset> centers;
  final List<int> pattern;
  final Color color;
  final Offset? currentPosition;
  final bool isDrawing;

  _PatternPainter({
    required this.centers,
    required this.pattern,
    required this.color,
    required this.currentPosition,
    required this.isDrawing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (pattern.length < 2) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < pattern.length - 1; i++) {
      final from = centers[pattern[i]];
      final to = centers[pattern[i + 1]];
      canvas.drawLine(from, to, paint);
    }

    if (isDrawing && pattern.isNotEmpty && currentPosition != null) {
      final from = centers[pattern.last];
      canvas.drawLine(from, currentPosition!, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PatternPainter oldDelegate) {
    return oldDelegate.pattern != pattern ||
        oldDelegate.color != color ||
        oldDelegate.currentPosition != currentPosition ||
        oldDelegate.isDrawing != isDrawing;
  }
}
