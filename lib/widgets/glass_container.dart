import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/stitch_theme.dart';

/// Dark glassmorphism container with frosted-backdrop blur effect.
///
/// For list-context items (track tiles, cards) keep [blur] low (e.g. 6)
/// to avoid GPU overload during scrolling. Single-instance UI like the
/// player bar or dialogs can afford a heavier blur (e.g. 20).
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double radius;
  final Color? color;
  final EdgeInsetsGeometry? padding;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 10,
    this.radius = 20,
    this.color,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: color ?? WTheme.glassSurface,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: WTheme.glassBorder, width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}
