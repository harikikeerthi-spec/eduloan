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
        // Base Background Color - White for clean look
        Positioned.fill(child: Container(color: Colors.white)),

        // Top Left: Soft Purple Blob
        Positioned(
          top: -120,
          left: -120,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
            child: Container(
              width: 400,
              height: 400,
              decoration: const BoxDecoration(
                color: Color(0xFFD8B4FE), // Purple-300
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),

        // Top Right: Soft Peach Blob
        Positioned(
          top: -100,
          right: -100,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
            child: Container(
              width: 400,
              height: 400,
              decoration: const BoxDecoration(
                color: Color(0xFFFFCC80), // Orange-200
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),

        // Bottom Left/Middle: Subtle Pink Accent
        Positioned(
          top: 300,
          left: -100,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
            child: Container(
              width: 300,
              height: 300,
              decoration: const BoxDecoration(
                color: Color(0xFFFBCFE8), // Pink-200
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),

        // Content
        Positioned.fill(child: child),
      ],
    );
  }
}
