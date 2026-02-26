import 'package:flutter/material.dart';
import '../../services/ai_logic_service.dart';
import '../../widgets/mesh_background.dart';

class UniversityDetailPage extends StatefulWidget {
  final UniversityRecommendation university;

  const UniversityDetailPage({super.key, required this.university});

  @override
  State<UniversityDetailPage> createState() => _UniversityDetailPageState();
}

class _UniversityDetailPageState extends State<UniversityDetailPage> {
  bool _isExpanded = false;
  int _currentImageIndex = 0;
  bool _isUsd = false;
  int _admissionTabIndex = 0; // 0 for Mandatory, 1 for Optional

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
      body: MeshBackground(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildNewHeader(),
                    const SizedBox(height: 24),
                    _buildStatsBar(),
                    const SizedBox(height: 24),
                    _buildInfoGrid(),
                    const SizedBox(height: 32),
                    _buildRankings(),
                    const SizedBox(height: 32),
                    _buildAdmissionCriteria(),
                    const SizedBox(height: 32),
                    _buildExpensesSection(),
                    const SizedBox(height: 32),
                    _buildIntakeBanner(),
                    const SizedBox(height: 32),
                    _buildAdmissionProcess(),
                    const SizedBox(height: 32),
                    _buildAboutSection(),
                    const SizedBox(height: 32),
                    _buildImageCarousel(),
                    const SizedBox(height: 32),
                    _buildDemographics(),
                    const SizedBox(height: 32),
                    _buildSafetyFocus(),
                    const SizedBox(height: 32),
                    _buildGuidanceCard(),
                    const SizedBox(height: 120), // Space for bottom bar
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xFF6200EA), Color(0xFF9D50BB)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6200EA).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(24),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Ask VL',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.university.name,
            style: const TextStyle(
              color: Color(0xFF1F2937),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            widget.university.programName.isNotEmpty
                ? widget.university.programName
                : 'Program Details',
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.university.programName.isNotEmpty
              ? widget.university.programName
              : 'Program Name',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: widget.university.logoUrl.isNotEmpty
                    ? Image.network(
                        widget.university.logoUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildLogoIcon(),
                      )
                    : _buildLogoIcon(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.university.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.university.location,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (widget.university.country.isNotEmpty) ...[
                        Text(
                          widget.university.flag,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.university.country.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6B7280),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLogoIcon() {
    String monogram = '';
    if (widget.university.name.isNotEmpty) {
      final parts = widget.university.name.split(' ');
      if (parts.length >= 2) {
        monogram = (parts[0][0] + parts[1][0]).toUpperCase();
      } else if (parts[0].isNotEmpty) {
        monogram = parts[0][0].toUpperCase();
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF6200EA).withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: monogram.isNotEmpty
          ? Text(
              monogram,
              style: const TextStyle(
                color: Color(0xFF6200EA),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            )
          : const Icon(
              Icons.account_balance,
              color: Color(0xFF6200EA),
              size: 24,
            ),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1F2937).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('ROI', widget.university.roi, const Color(0xFF4ADE80)),
          _buildStatDivider(),
          _buildStatItem(
            'ACCEPTANCE RATE',
            widget.university.acceptanceRate,
            const Color(0xFFF87171),
          ),
          _buildStatDivider(),
          _buildStatItem(
            'ADMIT CHANCES',
            widget.university.chance,
            const Color(0xFF94A3B8),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          value.isEmpty ? '-' : value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Color(0xFF64748B),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(height: 40, width: 1, color: Colors.grey.withOpacity(0.1));
  }

  Widget _buildInfoGrid() {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              _buildGridItem('Duration', widget.university.duration),
              const SizedBox(height: 24),
              _buildGridItem('Category', widget.university.category),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              _buildGridItem(
                'Application Deadline',
                widget.university.deadline,
              ),
              const SizedBox(height: 24),
              _buildGridItem(
                'Indian Community',
                widget.university.indianCommunity,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGridItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 4),
        Text(
          value.isEmpty ? '-' : value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  Widget _buildRankings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ranking',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 20),
        _buildRankingRow('#46', 'QS Ranking 2026'),
        const SizedBox(height: 16),
        _buildRankingRow(
          '#${widget.university.theRank.isNotEmpty ? widget.university.theRank : '18'}',
          'Times Higher Education 2026',
        ),
      ],
    );
  }

  Widget _buildRankingRow(String rank, String title) {
    return Row(
      children: [
        Text(
          rank,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          title,
          style: const TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    final text = widget.university.description.isNotEmpty
        ? widget.university.description
        : widget.university.reason;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'About University',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          text,
          maxLines: _isExpanded ? null : 3,
          overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: const TextStyle(color: Color(0xFF4B5563), height: 1.5),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Text(
            _isExpanded ? 'read less' : 'read more',
            style: const TextStyle(
              color: Color(0xFF6200EA),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildAboutLinkRow('VISIT WEBSITE', 'Link', true),
        const Divider(),
        _buildAboutLinkRow(
          'UNIVERSITY TYPE',
          widget.university.universityType.isNotEmpty
              ? widget.university.universityType
              : 'Private',
          false,
        ),
        const SizedBox(height: 16),
        _buildUniversityGallery(),
      ],
    );
  }

  Widget _buildUniversityGallery() {
    final images = widget.university.images.length >= 5
        ? widget.university.images
        : [
            'https://brand.ucla.edu/sites/default/files/styles/image_width_1000/public/2022-03/ucla_campus_roycehall-1_0.jpg',
            'https://admission.ucla.edu/sites/default/files/styles/image_width_1000/public/2021-08/ucla-campus-1.jpg',
            'https://s3.amazonaws.com/cms.ipressroom.com/173/files/20198/5d72bd742cfac20966233ba4_UCLA_RoyceHall_Night/UCLA_RoyceHall_Night_mid.jpg',
            'https://www.ucla.edu/img/campus-life/ucla-campus-royce-hall.jpg',
            'https://grad.ucla.edu/wp-content/uploads/2014/08/UCLA_Powell_Library.jpg',
            'https://admission.ucla.edu/sites/default/files/styles/image_width_1000/public/2021-08/ucla-campus-2.jpg',
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'University Gallery',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            itemBuilder: (context, index) {
              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: NetworkImage(images[index]),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAboutLinkRow(String label, String value, bool isLink) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6B7280),
              letterSpacing: 0.5,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isLink ? const Color(0xFF6200EA) : const Color(0xFF1F2937),
              decoration: isLink ? TextDecoration.underline : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCarousel() {
    final images = widget.university.images.isNotEmpty
        ? widget.university.images
        : [
            'https://brand.ucla.edu/sites/default/files/styles/image_width_1000/public/2022-03/ucla_campus_roycehall-1_0.jpg',
            'https://admission.ucla.edu/sites/default/files/styles/image_width_1000/public/2021-08/ucla-campus-1.jpg',
          ];

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PageView.builder(
            itemCount: images.length,
            onPageChanged: (index) =>
                setState(() => _currentImageIndex = index),
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: NetworkImage(images[index]),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(images.length, (index) {
            bool isSelected = _currentImageIndex == index;
            return Container(
              width: isSelected ? 24 : 8,
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF1F2937) : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildDemographics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Demographics & Diversity',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 24),
        _buildDemoRow(
          Icons.people_outline,
          widget.university.genderRatio.isNotEmpty
              ? widget.university.genderRatio
              : '45% Male  55% Female',
        ),
        _buildDemoRow(
          Icons.flag_outlined,
          widget.university.indianCommunity.isNotEmpty
              ? '${widget.university.indianCommunity} Indian Community'
              : 'Moderate Indian Community (6%)',
        ),
        _buildDemoRow(
          Icons.school_outlined,
          widget.university.studentTeacherRatio.isNotEmpty
              ? '${widget.university.studentTeacherRatio} Student-Teacher Ratio'
              : '9:1 Student-Teacher Ratio',
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.public, size: 20, color: Color(0xFF6B7280)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.university.raceRatio.isNotEmpty
                    ? 'Race Ratio (${widget.university.raceRatio})'
                    : 'Race Ratio (32% White, 30% Asian, 23% Hispanic Or Latino, 4% Black Or African American)',
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF4B5563),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDemoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF6B7280)),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(fontSize: 15, color: Color(0xFF1F2937)),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyFocus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Safety & Academic Focus',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 24),
        _buildSafetyIconRow(
          Icons.verified_user_outlined,
          widget.university.safetyStatus.isNotEmpty
              ? widget.university.safetyStatus
              : 'Moderately Safe',
        ),
        _buildSafetyIconRow(
          Icons.menu_book_outlined,
          widget.university.academicFocus.isNotEmpty
              ? widget.university.academicFocus
              : 'Primarily Teaching-Focused',
        ),
      ],
    );
  }

  Widget _buildSafetyIconRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF6B7280)),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(fontSize: 15, color: Color(0xFF1F2937)),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF), // Soft purple/indigo
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE9FE)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Need further guidance for this program?',
                  style: TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Talk to our advisor for free.',
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.call, size: 18),
                  label: const Text('Request a call back'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6200EA),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            Icons.support_agent,
            size: 64,
            color: const Color(0xFF6200EA).withOpacity(0.2),
          ),
        ],
      ),
    );
  }

  Widget _buildAdmissionCriteria() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Admission Criteria',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            _buildTab('MANDATORY', 0),
            const SizedBox(width: 12),
            _buildTab('OPTIONAL', 1),
          ],
        ),
        const SizedBox(height: 24),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'TEST',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
              Expanded(
                child: Text(
                  'MIN. SCORE',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
              Expanded(
                child: Text(
                  'YOUR SCORE',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Divider(),
        ),
        if (_admissionTabIndex == 0) ...[
          _buildCriteriaRow('GRE', '300', '0'),
          const Divider(),
          _buildCriteriaRow('GMAT', '500', '0'),
        ] else ...[
          _buildCriteriaRow('IELTS', '7.0', '0'),
          const Divider(),
          _buildCriteriaRow('TOEFL', '100', '0'),
        ],
        const SizedBox(height: 32),
        _buildSaveProgramCard(),
      ],
    );
  }

  Widget _buildTab(String label, int index) {
    bool isSelected = _admissionTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _admissionTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1F2937) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? Colors.transparent : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  Widget _buildCriteriaRow(String test, String min, String your) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              test,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          Expanded(
            child: Text(
              min,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          Expanded(
            child: Text(
              your,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveProgramCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF4C1D95), // Deep purple as per image
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text(
                      'Love what you\'re seeing? ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('❤️', style: TextStyle(fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Save this program to review and compare later.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.bookmark_outline, size: 18),
                  label: const Text('Save this program'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE5D5FA),
                    foregroundColor: const Color(0xFF4C1D95),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.face, size: 48, color: Colors.white30),
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Expenses',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            Row(
              children: [
                const Text(
                  'INR',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Switch(
                  value: _isUsd,
                  onChanged: (val) => setState(() => _isUsd = val),
                  activeColor: const Color(0xFF6200EA),
                ),
                const Text(
                  'USD',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _isUsd ? '\$68,234' : '₹5,705,427',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const Text(
          'per year',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.eco_outlined, color: Color(0xFF166534), size: 16),
              SizedBox(width: 8),
              Text(
                'Loan eligibility for your profile looks strong',
                style: TextStyle(
                  color: Color(0xFF166534),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _buildExpenseRow('BREAKDOWN', '', isHeader: true),
        _buildExpenseRow('Tuition Fees', _isUsd ? '\$39,520' : '₹3,303,027'),
        _buildExpenseRow('Cost of Living', _isUsd ? '\$28,745' : '₹2,402,400'),
        const SizedBox(height: 24),
        _buildExpenseRow('MEDIAN SALARY', '', isHeader: true),
        _buildExpenseRow(
          'Median Package of University',
          _isUsd ? '\$89,450' : '₹7,472,733',
          isBold: true,
        ),
        const SizedBox(height: 32),
        _buildLoanCtaCard(),
      ],
    );
  }

  Widget _buildExpenseRow(
    String label,
    String value, {
    bool isHeader = false,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isHeader ? 11 : 15,
              fontWeight: isHeader || isBold
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: isHeader ? Colors.grey : const Color(0xFF1F2937),
              letterSpacing: isHeader ? 0.5 : 0,
            ),
          ),
          if (value.isNotEmpty)
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: const Color(0xFF1F2937),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoanCtaCard() {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6200EA),
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Check your eligibility',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(width: 8),
          Icon(Icons.arrow_forward, size: 20),
        ],
      ),
    );
  }

  Widget _buildIntakeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'UPCOMING INTAKES',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'DEADLINES',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Fall 2027',
                style: TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '15 Dec \'26',
                style: TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Fast-track your application',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdmissionProcess() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Admission process',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 24),
        _buildProcessStep(
          '1',
          'Prepare all your documents',
          'Review the list of documents for the admission process.',
          link: 'list of documents',
        ),
        _buildProcessStep(
          '2',
          'Write your Statement of Purpose',
          'Get guidance on how to write SOP',
          link: 'Get guidance',
        ),
        _buildProcessStep(
          '3',
          'Request Letters of Recommendation',
          'Secure academic or professional references',
        ),
        _buildProcessStep(
          '4',
          'Update your resume/CV',
          'Highlight academic and professional achievements',
        ),
        _buildProcessStep(
          '5',
          'Apply to the University Website',
          'Visit University Website',
          link: 'Visit University Website',
          showArrow: true,
        ),
      ],
    );
  }

  Widget _buildProcessStep(
    String number,
    String title,
    String subtitle, {
    String? link,
    bool showArrow = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number. $title',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          if (link != null)
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, color: Colors.grey),
                children: [
                  TextSpan(
                    text: subtitle.replaceFirst(link, ''),
                    style: const TextStyle(height: 1.4),
                  ),
                  TextSpan(
                    text: link,
                    style: const TextStyle(
                      color: Color(0xFF6200EA),
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (showArrow)
                    const WidgetSpan(
                      child: Icon(
                        Icons.north_east,
                        size: 14,
                        color: Color(0xFF6200EA),
                      ),
                      alignment: PlaceholderAlignment.middle,
                    ),
                ],
              ),
            )
          else
            Text(
              subtitle,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.share_outlined, color: Color(0xFF4B5563)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF3F4F6),
                foregroundColor: const Color(0xFF1F2937),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
              ),
              child: const Text(
                'Apply to university',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6200EA),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
            child: const Row(
              children: [
                Icon(Icons.bookmark_outline, size: 20),
                SizedBox(width: 8),
                Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
