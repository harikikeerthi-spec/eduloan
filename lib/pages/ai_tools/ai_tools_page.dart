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
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
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
      body: MeshBackground(
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI Tools Suite',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                          fontFamily: 'Noto Serif',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 4,
                        width: 60,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6200EA), Color(0xFFD482F6)],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Smart tools to help you plan, qualify, and succeed.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF6B7280),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.9,
                  ),
                  delegate: SliverChildListDelegate([
                    _buildGridCard(
                      context,
                      title: 'Eligibility\nChecker',
                      subtitle: 'Check loan qualification',
                      icon: Icons.assignment_ind_outlined,
                      color: const Color(0xFF6200EA),
                      onTap: () =>
                          Navigator.pushNamed(context, '/ai/eligibility'),
                    ),
                    _buildGridCard(
                      context,
                      title: 'Grade\nConverter',
                      subtitle: 'GPA & marks conversion',
                      icon: Icons.school_outlined,
                      color: const Color(0xFFC51162),
                      onTap: () =>
                          Navigator.pushNamed(context, '/ai/grade-converter'),
                    ),
                    _buildGridCard(
                      context,
                      title: 'University\nCompare',
                      subtitle: 'Head-to-head comparison',
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
                      subtitle: 'Predict admission chance',
                      icon: Icons.analytics_outlined,
                      color: const Color(0xFF2962FF),
                      onTap: () =>
                          Navigator.pushNamed(context, '/ai/admit-predictor'),
                    ),
                    _buildGridCard(
                      context,
                      title: 'SOP\nWriter & Review',
                      subtitle: 'AI-assisted essay writing',
                      icon: Icons.description_outlined,
                      color: const Color(0xFF00BFA5),
                      onTap: () =>
                          Navigator.pushNamed(context, '/ai/sop-writer'),
                    ),
                    _buildGridCard(
                      context,
                      title: 'University\nShortlist',
                      subtitle: 'Find your target programs',
                      icon: Icons.map_outlined,
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
                      icon: Icons.assignment_turned_in_outlined,
                      color: const Color(0xFF3F51B5),
                      onTap: () =>
                          Navigator.pushNamed(context, '/ai/visa-simulator'),
                    ),
                    _buildGridCard(
                      context,
                      title: 'AI Support\nAssistant',
                      subtitle: '24/7 student guidance',
                      icon: Icons.chat_bubble_outline,
                      color: const Color(0xFF009688),
                      onTap: () => Navigator.pushNamed(context, '/ai/bot'),
                    ),
                  ]),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
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
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: const Color(0xFFF3F4F6), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1F2937),
                height: 1.1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
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
