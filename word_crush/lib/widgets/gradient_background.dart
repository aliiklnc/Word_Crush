import 'package:flutter/material.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;

  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E004B), // Derin gece moru
            Color(0xFF3B007F), // Neon mor
            Color(0xFF0F002A), // Koyu uzay rengi
          ],
        ),
      ),
      child: SafeArea(child: child),
    );
  }
}
