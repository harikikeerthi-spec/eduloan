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
    final bool canPop = Navigator.of(context).canPop();
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: canPop
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Color(0xFF1F2937),
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'Explore AI Tools',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: MeshBackground(
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI Tools Suite',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 3,
                        width: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6200EA), Color(0xFFD482F6)],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Smart tools to help you plan, qualify, and succeed.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.05,
                  ),
                  delegate: SliverChildListDelegate([
                    _buildGridCard(
                      context,
                      title: 'EMI\nCalculator',
                      subtitle: 'Calculate loan EMIs',
                      imagePath: 'assets/icons/3d/emi_calculator.png',
                      color: const Color(0xFF10B981),
                      onTap: () =>
                          Navigator.pushNamed(context, '/emi-calculator'),
                    ),
                    _buildGridCard(
                      context,
                      title: 'Eligibility\nChecker',
                      subtitle: 'Check loan qualification',
                      imagePath: 'assets/icons/3d/loan_eligibility.png',
                      color: const Color(0xFF6200EA),
                      onTap: () =>
                          Navigator.pushNamed(context, '/ai/eligibility'),
                    ),
                    _buildGridCard(
                      context,
                      title: 'Grade\nConverter',
                      subtitle: 'GPA & marks conversion',
                      imagePath: 'assets/icons/3d/grade_converter.png',
                      color: const Color(0xFFC51162),
                      onTap: () =>
                          Navigator.pushNamed(context, '/ai/grade-converter'),
                    ),
                    _buildGridCard(
                      context,
                      title: 'University\nCompare',
                      subtitle: 'Head-to-head comparison',
                      imagePath: 'assets/icons/3d/university_compare.png',
                      color: const Color(0xFFFF9800),
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/ai/university-compare',
                      ),
                    ),
                    _buildGridCard(
                      context,
                      title: 'Admit\nPredictor',
                      subtitle: 'Predict admission chance',
                      imagePath: 'assets/icons/3d/admit_predictor.png',
                      color: const Color(0xFF2962FF),
                      onTap: () =>
                          Navigator.pushNamed(context, '/ai/admit-predictor'),
                    ),
                    _buildGridCard(
                      context,
                      title: 'SOP\nWriter & Review',
                      subtitle: 'AI-assisted essay writing',
                      imagePath: 'assets/icons/3d/sop_writer.png',
                      color: const Color(0xFF00BFA5),
                      onTap: () =>
                          Navigator.pushNamed(context, '/ai/sop-writer'),
                    ),
                    _buildGridCard(
                      context,
                      title: 'University\nShortlist',
                      subtitle: 'Find target programs',
                      imagePath: 'assets/icons/3d_community/universities.png',
                      color: const Color(0xFF673AB7),
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/ai/university-shortlist',
                      ),
                    ),
                    _buildGridCard(
                      context,
                      title: 'Visa Interview\nSimulator',
                      subtitle: 'Practice with AI Officer',
                      imagePath: 'assets/icons/3d_community/visa.png',
                      color: const Color(0xFF3F51B5),
                      onTap: () =>
                          Navigator.pushNamed(context, '/ai/visa-simulator'),
                    ),
                    _buildGridCard(
                      context,
                      title: 'AI Support\nAssistant',
                      subtitle: '24/7 student guidance',
                      imagePath: 'assets/icons/3d/ai_tools_hub.png',
                      color: const Color(0xFF009688),
                      onTap: () => Navigator.pushNamed(context, '/ai/bot'),
                    ),
                  ]),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String imagePath,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(color: const Color(0xFFF3F4F6), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset(
                imagePath,
                width: 30,
                height: 30,
                fit: BoxFit.contain,
              ),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
                height: 1.15,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                color: Color(0xFF9CA3AF),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
