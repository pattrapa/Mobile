import 'package:flutter/material.dart';

class DecorativeBackground extends StatelessWidget {
  final bool isDarkMode;
  final Widget child;

  const DecorativeBackground({
    super.key,
    required this.isDarkMode,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final primary = isDarkMode
        ? const Color(0xFF38BDF8)
        : const Color(0xFFF97316);

    final secondary = isDarkMode
        ? const Color(0xFF6366F1)
        : const Color(0xFFF59E0B);

    return Stack(
      children: [
        Positioned(
          top: -90,
          left: -70,
          child: _GlowCircle(
            size: 240,
            color: primary.withValues(
              alpha: isDarkMode ? 0.10 : 0.09,
            ),
          ),
        ),
        Positioned(
          top: 130,
          right: -85,
          child: _OutlinedCircle(
            size: 190,
            color: primary.withValues(
              alpha: isDarkMode ? 0.15 : 0.14,
            ),
          ),
        ),
        Positioned(
          bottom: -100,
          right: -45,
          child: _GlowCircle(
            size: 270,
            color: secondary.withValues(
              alpha: isDarkMode ? 0.08 : 0.07,
            ),
          ),
        ),
        Positioned(
          left: 20,
          bottom: 110,
          child: _DotGrid(
            color: primary.withValues(
              alpha: isDarkMode ? 0.16 : 0.17,
            ),
          ),
        ),
        Positioned.fill(
          child: child,
        ),
      ],
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowCircle({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutlinedCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _OutlinedCircle({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color),
        ),
        child: Center(
          child: Container(
            width: size * 0.68,
            height: size * 0.68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: 0.65),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DotGrid extends StatelessWidget {
  final Color color;

  const _DotGrid({
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: 72,
        height: 72,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(
            36,
            (_) => Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}