import 'package:flutter/material.dart';

/// Animated shimmer placeholder for text/value slots while data loads.
///
/// Usage:
///   ShimmerBox(width: 80, height: 12)           // inline text line
///   ShimmerBox(width: 65, height: 20)           // larger value
///   ShimmerBox(width: double.infinity, height: 16) // full-width bar
class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  /// Tints the shimmer toward this color. Defaults to neutral grey.
  final Color color;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 4,
    this.color = const Color(0xFFD1D5DB),
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              widget.color.withValues(alpha: 0.30),
              widget.color.withValues(alpha: 0.18),
              widget.color.withValues(alpha: 0.08),
              widget.color.withValues(alpha: 0.18),
              widget.color.withValues(alpha: 0.30),
            ],
            stops: _stops(_ctrl.value),
          ),
        ),
      ),
    );
  }

  static List<double> _stops(double t) {
    final c = -0.4 + t * 1.8;
    return [
      0.0,
      (c - 0.25).clamp(0.0, 1.0),
      c.clamp(0.0, 1.0),
      (c + 0.25).clamp(0.0, 1.0),
      1.0,
    ];
  }
}
