import 'package:flutter/material.dart';
import '../widgets/mesh_background.dart';
import 'ai_tools/university_shortlisting_page.dart';
import 'ai_tools/visa_interview_page.dart';

class StudyAbroadPage extends StatelessWidget {
  const StudyAbroadPage({super.key});

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
                      const Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 16),
                        child: Text(
                          'BEGIN YOUR JOURNEY',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ),
                      _buildMenuCard(
                        context,
                        title: 'Shortlist Universities',
                        subtitle: 'Fully powered by ',
                        subtitleSuffix: 'AI ✨',
                        icon: Icons.bookmark_add_outlined,
                        gradientText: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const UniversityShortlistingPage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildMenuCard(
                        context,
                        title: 'AI Recommendations',
                        subtitle: 'Smart suggestions by ',
                        subtitleSuffix: 'AI 🚀',
                        icon: Icons.auto_awesome_outlined,
                        gradientText: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const UniversityShortlistingPage(
                                    initialFlow: 'recommendations',
                                  ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildMenuCard(
                        context,
                        title: 'Visa Interview Simulator',
                        subtitle: 'Practice with our ',
                        subtitleSuffix: 'AI Visa Officer 🛂',
                        icon: Icons.assignment_turned_in_outlined,
                        gradientText: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const VisaInterviewPage(),
                            ),
                          );
                        },
                      ),
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
            'Study Abroad',
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

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    String? subtitleSuffix,
    required IconData icon,
    bool gradientText = false,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(
          0xFF6200EE,
        ).withValues(alpha: 0.95), // Vibrant Purple
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF7C4DFF), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6200EE).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: const Color(0xFF6200EE), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                          if (subtitleSuffix != null)
                            gradientText
                                ? ShaderMask(
                                    shaderCallback: (bounds) =>
                                        const LinearGradient(
                                          colors: [
                                            Colors.white,
                                            Color(0xFFEDE9FE),
                                          ],
                                        ).createShader(bounds),
                                    child: Text(
                                      subtitleSuffix,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(
                                    subtitleSuffix,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.black.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.white54,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
