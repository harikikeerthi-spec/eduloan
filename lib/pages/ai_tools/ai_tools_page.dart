import 'package:flutter/material.dart';
import '../../widgets/mesh_background.dart';

// Will import specific pages later
// import 'eligibility_checker_page.dart';
// import 'grade_converter_page.dart';
// import 'customer_care_bot_page.dart';

class AiToolsPage extends StatelessWidget {
  const AiToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1F2937)),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'AI Tools Suite',
            style: TextStyle(
              color: Color(0xFF1F2937),
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Power up your journey',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                  fontFamily: 'Noto Serif',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Smart tools to help you plan, qualify, and succeed.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 32),

              _buildToolCard(
                context,
                title: 'Loan Eligibility Checker',
                description:
                    'Get an instant eligibility estimate based on your profile.',
                icon: Icons.assignment_ind_outlined,
                color: const Color(0xFF6200EA),
                onTap: () {
                  Navigator.pushNamed(context, '/ai/eligibility');
                },
              ),
              const SizedBox(height: 16),
              _buildToolCard(
                context,
                title: 'Grade Converter & Analyzer',
                description:
                    'Convert grades to international standards and get analysis.',
                icon: Icons.school_outlined,
                color: const Color(0xFFC51162),
                onTap: () {
                  Navigator.pushNamed(context, '/ai/grade-converter');
                },
              ),
              const SizedBox(height: 16),
              _buildToolCard(
                context,
                title: 'AI Support Assistant',
                description:
                    '24/7 answers to your loan and application queries.',
                icon: Icons.chat_bubble_outline,
                color: const Color(0xFF009688),
                onTap: () {
                  Navigator.pushNamed(context, '/ai/bot');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black.withValues(alpha: 0.5),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.black.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}
