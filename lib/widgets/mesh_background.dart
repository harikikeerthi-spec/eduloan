import 'package:flutter/material.dart';
import 'dart:ui';

class MeshBackground extends StatelessWidget {
  final Widget child;

  const MeshBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base Background Color - Light background from web
        Positioned.fill(child: Container(color: const Color(0xFFF7F5F8))),

        // Deep Purple Glow (Web Primary: #6605c7) - Top Left
        Positioned(
          top: -100,
          left: -100,
          child: Container(
            width: 500,
            height: 500,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF6605C7).withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Gold Glow (Web Accent: #e0c389) - Top Right
        Positioned(
          top: -50,
          right: -100,
          child: Container(
            width: 450,
            height: 450,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFE0C389).withOpacity(0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Light Blue/Cyan Glow (Bottom Right)
        Positioned(
          bottom: -50,
          right: -50,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF8BC0E8).withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Deep Purple Glow (Bottom Left)
        Positioned(
          bottom: -100,
          left: -50,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF6605C7).withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Blur Layer
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
            child: Container(color: Colors.transparent),
          ),
        ),

        // Content
        Positioned.fill(child: child),
      ],
    );
  }
}
