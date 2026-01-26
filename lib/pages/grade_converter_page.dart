import 'package:flutter/material.dart';
import '../widgets/mesh_background.dart';

class GradeConverterPage extends StatelessWidget {
  const GradeConverterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MeshBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Grade Converter',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF311B92),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Convert your local GPA/grades to international standards (4.0 scale, ECTS, etc.).',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black.withValues(alpha: 0.6),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildFeaturePlaceholder(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            padding: EdgeInsets.zero,
          ),
          const Spacer(),
          const Text(
            'Edu Loan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 40), // Balanced with back button
        ],
      ),
    );
  }

  Widget _buildFeaturePlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF311B92).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.grade, size: 64, color: Color(0xFF311B92)),
          const SizedBox(height: 24),
          const Text(
            'Feature under development',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Global grading systems are complex. We are making them simple for you.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }
}
