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
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Power up your journey',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                        fontFamily: 'Noto Serif',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Smart tools to help you plan, qualify, and succeed.',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.count(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85, // Adjust for card height
                  children: [
                    _buildGridCard(
                      context,
                      title: 'Eligibility\nChecker',
                      icon: Icons.assignment_ind_outlined,
                      color: const Color(0xFF6200EA),
                      onTap: () =>
                          Navigator.pushNamed(context, '/ai/eligibility'),
                    ),
                    _buildGridCard(
                      context,
                      title: 'Grade\nConverter',
                      icon: Icons.school_outlined,
                      color: const Color(0xFFC51162),
                      onTap: () =>
                          Navigator.pushNamed(context, '/ai/grade-converter'),
                    ),
                    _buildGridCard(
                      context,
                      title: 'University\nCompare',
                      icon: Icons.balance,
                      color: const Color(0xFFFF9800),
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/ai/university-compare',
                      ),
                    ),
                    _buildGridCard(
                      context,
                      title: 'Admit\nPredictor',
                      icon: Icons.analytics_outlined,
                      color: const Color(0xFF2962FF),
                      onTap: () =>
                          Navigator.pushNamed(context, '/ai/admit-predictor'),
                    ),
                    _buildGridCard(
                      context,
                      title: 'SOP\nWriter',
                      icon: Icons.description_outlined,
                      color: const Color(0xFF00BFA5),
                      onTap: () =>
                          Navigator.pushNamed(context, '/ai/sop-writer'),
                    ),
                    _buildGridCard(
                      context,
                      title: 'AI Support\nAssistant',
                      icon: Icons.chat_bubble_outline,
                      color: const Color(0xFF009688),
                      onTap: () => Navigator.pushNamed(context, '/ai/bot'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
