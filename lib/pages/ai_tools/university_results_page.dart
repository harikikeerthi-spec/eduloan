import 'package:flutter/material.dart';
import '../../services/ai_logic_service.dart';
import '../../widgets/mesh_background.dart';
import 'university_detail_page.dart';

class UniversityResultsPage extends StatefulWidget {
  final List<UniversityRecommendation> recommendations;

  const UniversityResultsPage({super.key, required this.recommendations});

  @override
  State<UniversityResultsPage> createState() => _UniversityResultsPageState();
}

class _UniversityResultsPageState extends State<UniversityResultsPage> {
  String _activeTab = "All programs";
  final TextEditingController _searchController = TextEditingController();
  List<UniversityRecommendation> _allRecommendations = [];
  List<UniversityRecommendation> _filteredRecommendations = [];
  final Set<String> _savedUniversityNames = {};
  final AiLogicService _aiService = AiLogicService();

  List<UniversityRecommendation> _savedRecommendations = [];

  @override
  void initState() {
    super.initState();
    _allRecommendations = List.from(widget.recommendations);

    _filteredRecommendations = _getFilteredList();
    _loadSavedStatus();
  }

  Future<void> _loadSavedStatus() async {
    final saved = await _aiService.getSavedUniversities();
    setState(() {
      _savedRecommendations = saved;
      _savedUniversityNames.clear();
      _savedUniversityNames.addAll(saved.map((u) => u.name));
      _filteredRecommendations = _getFilteredList();
    });
  }

  void _toggleSave(UniversityRecommendation recommendation) async {
    await _aiService.toggleSaveUniversity(recommendation);
    await _loadSavedStatus();
  }

  List<UniversityRecommendation> _getFilteredList() {
    List<UniversityRecommendation> list = [];

    if (_activeTab == "All programs") {
      list = _allRecommendations;
    } else if (_activeTab == "Saved") {
      list = _savedRecommendations;
    }

    final query = _searchController.text.toLowerCase().trim();
    if (query.isNotEmpty) {
      list = list.where((u) {
        final name = u.name.toLowerCase();
        final program = u.programName.toLowerCase();
        final loc = u.location.toLowerCase();
        return name.contains(query) ||
            program.contains(query) ||
            loc.contains(query);
      }).toList();
    }

    return list;
  }

  void _onSearchChanged(String value) {
    setState(() {
      _filteredRecommendations = _getFilteredList();
    });
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                "Sort by",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            _buildSortOption("Default", Icons.sort),
            _buildSortOption("University Rank", Icons.trending_up),
            _buildSortOption("Tuition (Low to High)", Icons.money_off),
            _buildSortOption("Tuition (High to Low)", Icons.attach_money),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String label, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF6A1B9A)),
      title: Text(label),
      onTap: () {
        Navigator.pop(context);
        _applySort(label);
      },
    );
  }

  void _applySort(String option) {
    setState(() {
      if (option == "University Rank") {
        _filteredRecommendations.sort((a, b) {
          final r1 =
              int.tryParse(a.rank.replaceAll(RegExp(r'[^0-9]'), '')) ?? 9999;
          final r2 =
              int.tryParse(b.rank.replaceAll(RegExp(r'[^0-9]'), '')) ?? 9999;
          return r1.compareTo(r2);
        });
      } else if (option == "Tuition (Low to High)") {
        _filteredRecommendations.sort((a, b) {
          final t1 = _parseTuition(a.tuition);
          final t2 = _parseTuition(b.tuition);
          return t1.compareTo(t2);
        });
      } else if (option == "Tuition (High to Low)") {
        _filteredRecommendations.sort((a, b) {
          final t1 = _parseTuition(a.tuition);
          final t2 = _parseTuition(b.tuition);
          return t2.compareTo(t1);
        });
      } else {
        _filteredRecommendations = _getFilteredList();
      }
    });
  }

  double _parseTuition(String tuition) {
    // Basic parser for strings like "₹ 33.0 L" or "$ 45,000"
    String clean = tuition.replaceAll(RegExp(r'[^0-9.]'), '');
    double val = double.tryParse(clean) ?? 0;
    if (tuition.contains('L')) val *= 100000;
    return val;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MeshBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchBar(),
              _buildFilterBar(),
              _filteredRecommendations.isEmpty
                  ? Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "No programs found",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Try adjusting your search or filters",
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                            const SizedBox(height: 24),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _activeTab = "All programs";
                                  _filteredRecommendations = _getFilteredList();
                                });
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text("Reset filters"),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredRecommendations.length,
                        itemBuilder: (context, index) {
                          final recommendation =
                              _filteredRecommendations[index];
                          return _UniversityCard(
                            recommendation: recommendation,
                            isSaved: _savedUniversityNames.contains(
                              recommendation.name,
                            ),
                            onSaveToggle: () => _toggleSave(recommendation),
                          );
                        },
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          ),
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTabButton("All programs"),
                      _buildTabButton("Saved"),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8), // Small buffer
        ],
      ),
    );
  }

  Widget _buildTabButton(String text) {
    bool isSelected = _activeTab == text;

    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTab = text;
          _filteredRecommendations = _getFilteredList();
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6A1B9A)
              : Colors.transparent, // Purple for selected
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            if (isSelected && text == "AI mode") ...[
              const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
              const SizedBox(width: 4),
            ],
            Text(
              text,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: "Search Program",
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged("");
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: _showFilterBottomSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: const [
                  Text(
                    "Filter & sort",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Icon(Icons.keyboard_arrow_down, size: 18),
                ],
              ),
            ),
          ),
          const Spacer(),
          // Could add result count here if needed
        ],
      ),
    );
  }
}

class _UniversityCard extends StatelessWidget {
  final UniversityRecommendation recommendation;
  final bool isSaved;
  final VoidCallback onSaveToggle;

  const _UniversityCard({
    required this.recommendation,
    required this.isSaved,
    required this.onSaveToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                UniversityDetailPage(university: recommendation),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.05 * 255).toInt()),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(recommendation.flag), // Flag Emoji
                            const SizedBox(width: 4),
                            Text(
                              recommendation.country, // Country Code/Name
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (recommendation.type != 'All')
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E5F5), // Light purple
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            "AI RECOMMENDED",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6A1B9A),
                            ),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          recommendation.rank, // QS Rank
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onSaveToggle,
                  icon: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: isSaved ? const Color(0xFF6A1B9A) : Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // University Logo
                Container(
                  width: 48,
                  height: 48,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: recommendation.logoUrl.trim().isNotEmpty
                      ? Image.network(
                          recommendation.logoUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback to Google Favicon service if Clearbit fails
                            final domain = recommendation.logoUrl
                                .split('/')
                                .last
                                .split('?')
                                .first;
                            return Image.network(
                              "https://www.google.com/s2/favicons?sz=64&domain=$domain",
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Text(
                                    recommendation.name.isNotEmpty
                                        ? recommendation.name.substring(0, 1)
                                        : "U",
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        )
                      : Center(
                          child: Text(
                            recommendation.name.isNotEmpty
                                ? recommendation.name.substring(0, 1)
                                : "U",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recommendation.programName.isNotEmpty
                            ? recommendation.programName
                            : "Master's Program",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        recommendation.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            recommendation.location,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildKV(
                    "TUITION",
                    _formatUSD(recommendation.tuition),
                  ),
                ),
                Expanded(
                  child: _buildKV(
                    "AVG. SALARY",
                    _formatUSD(recommendation.avgSalary),
                  ),
                ),
                Expanded(child: _buildKV("DEADLINE", recommendation.deadline)),
                Expanded(
                  child: _buildConfigurableKV(
                    "ADMIT CHANCES",
                    recommendation.chance,
                    _getChanceColor(recommendation.type),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatUSD(String rawValue) {
    if (rawValue.isEmpty || rawValue == '-') return 'N/A';

    // Check if it already has a symbol
    if (rawValue.contains('\$') ||
        rawValue.contains('£') ||
        rawValue.contains('€') ||
        rawValue.contains('₹')) {
      return rawValue;
    }

    // Extract digits and try to format as USD
    String digitsOnly = rawValue.replaceAll(RegExp(r'[^0-9.]'), '');
    double? val = double.tryParse(digitsOnly);
    if (val != null) {
      String valStr = val.toStringAsFixed(0);
      String formatted = valStr.replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
      return '\$$formatted';
    }

    return rawValue;
  }

  Widget _buildKV(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildConfigurableKV(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getChanceColor(String type) {
    switch (type) {
      case 'Safe':
        return Colors.green;
      case 'Target':
        return Colors.orange;
      case 'Ambitious':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}
