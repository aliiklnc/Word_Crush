import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;
  final bool hasBorder;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.blur = 10.0,
    this.opacity = 0.15,
    this.borderRadius,
    this.hasBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(24.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            borderRadius: borderRadius ?? BorderRadius.circular(24.0),
            border: hasBorder
                ? Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1.5,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: -2,
              )
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
