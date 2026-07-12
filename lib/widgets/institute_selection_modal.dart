import 'dart:async';
import 'package:flutter/material.dart';
import '../data/institutes_data.dart';
import '../services/ai_logic_service.dart';
import '../services/logo_service.dart';
import '../pages/apply_loan_page.dart';
import 'mesh_background.dart';
import '../services/loan_service.dart';

class InstituteSelectionModal extends StatefulWidget {
  final String? selectedCountry;
  const InstituteSelectionModal({super.key, this.selectedCountry});

  @override
  State<InstituteSelectionModal> createState() =>
      _InstituteSelectionModalState();
}

class _InstituteSelectionModalState extends State<InstituteSelectionModal> {
  String _searchQuery = '';
  Institute? _selectedInstitute;
  final TextEditingController _searchController = TextEditingController();

  Timer? _debounce;
  bool _isSearchingAI = false;
  List<Institute> _aiInstitutes = [];
  bool _isLoadingCourses = false;
  final Map<String, List<String>> _fetchedCoursesCache = {};
  String? _selectedCourse;
  final Set<String> _expandedCategories = {'Masters'};

  List<Institute> get _combinedInstitutes {
    List<Institute> combined = [];
    if (_searchQuery.isEmpty) {
      if (widget.selectedCountry != null && widget.selectedCountry != 'Other') {
        return InstitutesData.allInstitutes
            .where((i) => i.state.toLowerCase() == widget.selectedCountry!.toLowerCase())
            .toList();
      }
      return InstitutesData.allInstitutes;
    }
    
    final localMatches = InstitutesData.allInstitutes.where((institute) {
      bool matchesSearch = institute.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          institute.type.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          institute.state.toLowerCase().contains(_searchQuery.toLowerCase());
          
      if (widget.selectedCountry != null && widget.selectedCountry != 'Other') {
        return matchesSearch && institute.state.toLowerCase() == widget.selectedCountry!.toLowerCase();
      }
      return matchesSearch;
    }).toList();
    
    combined.addAll(localMatches);
    
    // Add AI institutes that aren't already in local matches
    for (var aiInst in _aiInstitutes) {
      if (!combined.any((local) => local.name.toLowerCase() == aiInst.name.toLowerCase())) {
        combined.add(aiInst);
      }
    }
    
    return combined;
  }

  bool _hasAppliedForLoan = false;

  @override
  void initState() {
    super.initState();
    _checkLoanStatus();
  }

  Future<void> _checkLoanStatus() async {
    try {
      final loans = await LoanService().getUserLoans();
      if (mounted) {
        setState(() {
          _hasAppliedForLoan = loans.isNotEmpty;
        });
      }
    } catch (e) {
      // Ignore
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    if (value.trim().length < 3) {
      setState(() {
        _aiInstitutes = [];
        _isSearchingAI = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() {
        _isSearchingAI = true;
      });

      try {
        final results = await AiLogicService().searchGlobalUniversities(
          value,
          country: widget.selectedCountry,
        );
        if (mounted) {
          setState(() {
            _aiInstitutes = results.map((res) {
              return Institute(
                name: res['name'] ?? 'Unknown University',
                state: res['country'] ?? 'Global',
                type: 'Global University',
                courses: [], // Will fetch when selected
              );
            }).toList();
            _isSearchingAI = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isSearchingAI = false;
          });
        }
      }
    });
  }

  void _selectInstitute(Institute institute) async {
    // 1. If already cached, just use cached courses
    if (_fetchedCoursesCache.containsKey(institute.name)) {
      setState(() {
        _selectedInstitute = Institute(
          name: institute.name,
          state: institute.state,
          type: institute.type,
          courses: _fetchedCoursesCache[institute.name]!,
        );
        _selectedCourse = null;
      });
      return;
    }

    // 2. Otherwise, select the institute first (shows loading spinner)
    setState(() {
      _selectedInstitute = institute;
      _isLoadingCourses = true;
      _selectedCourse = null;
    });

    try {
      final courses = await AiLogicService().searchUniversityCourses(institute.name, '');
      final List<String> mappedCourses = courses
          .map((c) => c['name'] ?? 'Unknown Course')
          .where((name) => name != 'Unknown Course')
          .toList();

      final List<String> finalCourses = mappedCourses.isNotEmpty 
          ? mappedCourses 
          : (institute.courses.isNotEmpty ? institute.courses : ['MS Computer Science', 'MBA', 'Data Science', 'Engineering']);

      if (mounted && _selectedInstitute?.name == institute.name) {
        setState(() {
          _fetchedCoursesCache[institute.name] = finalCourses;
          _selectedInstitute = Institute(
            name: institute.name,
            state: institute.state,
            type: institute.type,
            courses: finalCourses,
          );
          _isLoadingCourses = false;
        });
      }
    } catch (e) {
      if (mounted && _selectedInstitute?.name == institute.name) {
        final List<String> fallbackCourses = institute.courses.isNotEmpty 
            ? institute.courses 
            : ['MS Computer Science', 'MBA', 'Data Science', 'Engineering'];
        setState(() {
          _fetchedCoursesCache[institute.name] = fallbackCourses;
          _selectedInstitute = Institute(
            name: institute.name,
            state: institute.state,
            type: institute.type,
            courses: fallbackCourses,
          );
          _isLoadingCourses = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(32),
        topRight: Radius.circular(32),
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: MeshBackground(
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF311B92).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Content
              Expanded(
                child: _selectedInstitute == null
                    ? _buildSelectionView()
                    : _buildDetailsView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Institute',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Search and select your institute to view courses',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 24),
              // Search Bar
              TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  hintText: 'Search institutes...',
                  hintStyle: TextStyle(
                    color: Colors.black.withValues(alpha: 0.4),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: const Color(0xFF311B92).withValues(alpha: 0.6),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF311B92).withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onChanged: _onSearchChanged,
              ),
              if (_isSearchingAI)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'AI is searching global universities...',
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF311B92).withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _combinedInstitutes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 64,
                        color: const Color(0xFF311B92).withValues(alpha: 0.2),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No institutes found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try searching with a different name',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _combinedInstitutes.length,
                  itemBuilder: (context, index) {
                    final institute = _combinedInstitutes[index];
                    return _buildInstituteCard(institute);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDetailsView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    _selectedInstitute = null;
                    _selectedCourse = null;
                  });
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.arrow_back,
                      color: const Color(0xFF311B92).withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Back to Selection',
                      style: TextStyle(
                        color: const Color(0xFF311B92).withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _selectedInstitute!.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _selectedInstitute!.type,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: Colors.black.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _selectedInstitute!.state,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Text(
                'Courses Offered',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        if (_isLoadingCourses)
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF311B92)),
            ),
          )
        else if (_selectedInstitute!.courses.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                'No courses found for this university.',
                style: TextStyle(
                  color: Colors.black.withValues(alpha: 0.5),
                ),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _renderableCourseItems.length,
              itemBuilder: (context, index) {
                final item = _renderableCourseItems[index];
                if (item.isHeader) {
                  return _buildCategoryHeader(item.category!, item.count);
                } else {
                  return _buildSubCourseCard(item.course!, item.category);
                }
              },
            ),
          ),
          if (_selectedCourse != null && !_hasAppliedForLoan)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    final navigator = Navigator.of(context);
                    navigator.pop();
                    navigator.push(
                      MaterialPageRoute(
                        builder: (context) => ApplyLoanPage(
                          initialUniversity: _selectedInstitute!.name,
                          initialCourse: _selectedCourse!,
                          initialCountry: _selectedInstitute!.state,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF311B92),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Apply Loan',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
      ],
    );
  }

  Widget _buildFallbackIcon() {
    return Container(
      width: 48,
      height: 48,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.school,
        color: Color(0xFF6366F1),
        size: 24,
      ),
    );
  }

  Widget _buildInstituteCard(Institute institute) {
    return InkWell(
      onTap: () => _selectInstitute(institute),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF311B92).withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF311B92).withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            FutureBuilder<String?>(
              future: LogoService.getLogoByName(institute.name),
              builder: (context, snapshot) {
                final logoUrl = snapshot.data;
                if (logoUrl != null && logoUrl.isNotEmpty) {
                  return Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF311B92).withValues(alpha: 0.1),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Image.network(
                          logoUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildFallbackIcon(),
                        ),
                      ),
                    ),
                  );
                }
                return _buildFallbackIcon();
              },
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    institute.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Builder(
                    builder: (context) {
                      final cachedCourses = _fetchedCoursesCache[institute.name];
                      final coursesCount = cachedCourses?.length ?? institute.courses.length;
                      final subtitleText = coursesCount == 0 
                          ? 'Explore AI Courses' 
                          : '$coursesCount Courses Available';
                      return Text(
                        subtitleText,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black.withValues(alpha: 0.6),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: const Color(0xFF311B92).withValues(alpha: 0.4),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  String _getCourseCategory(String courseName) {
    final lower = courseName.toLowerCase();
    if (lower.contains('master') ||
        lower.startsWith('ms ') ||
        lower.startsWith('msc') ||
        lower.startsWith('mba') ||
        lower.startsWith('llm') ||
        lower.startsWith('mphil') ||
        lower.startsWith('m.eng') ||
        lower.startsWith('ma ') ||
        lower.startsWith('m.tech') ||
        lower.startsWith('m.s.')) {
      return 'Masters';
    }
    if (lower.contains('bachelor') ||
        lower.startsWith('bs ') ||
        lower.startsWith('bsc') ||
        lower.startsWith('ba ') ||
        lower.startsWith('b.eng') ||
        lower.startsWith('bse') ||
        lower.startsWith('b.tech') ||
        lower.startsWith('b.a.') ||
        lower.startsWith('b.s.')) {
      return 'Bachelors';
    }
    if (lower.contains('phd') ||
        lower.contains('jd') ||
        lower.contains('doctor') ||
        lower.contains('ph.d.')) {
      return 'Doctorate';
    }
    return 'Other';
  }

  List<_CourseRenderItem> get _renderableCourseItems {
    if (_selectedInstitute == null) return [];

    Map<String, List<String>> groups = {
      'Bachelors': [],
      'Masters': [],
      'Doctorate': [],
      'Other': [],
    };

    for (var course in _selectedInstitute!.courses) {
      final cat = _getCourseCategory(course);
      groups[cat]!.add(course);
    }

    List<_CourseRenderItem> items = [];

    if (groups['Bachelors']!.isNotEmpty) {
      items.add(_CourseRenderItem(category: 'Bachelors', count: groups['Bachelors']!.length, isHeader: true));
      if (_expandedCategories.contains('Bachelors')) {
        for (var course in groups['Bachelors']!) {
          items.add(_CourseRenderItem(category: 'Bachelors', course: course, isHeader: false));
        }
      }
    }

    if (groups['Masters']!.isNotEmpty) {
      items.add(_CourseRenderItem(category: 'Masters', count: groups['Masters']!.length, isHeader: true));
      if (_expandedCategories.contains('Masters')) {
        for (var course in groups['Masters']!) {
          items.add(_CourseRenderItem(category: 'Masters', course: course, isHeader: false));
        }
      }
    }

    if (groups['Doctorate']!.isNotEmpty) {
      items.add(_CourseRenderItem(category: 'Doctorate', count: groups['Doctorate']!.length, isHeader: true));
      if (_expandedCategories.contains('Doctorate')) {
        for (var course in groups['Doctorate']!) {
          items.add(_CourseRenderItem(category: 'Doctorate', course: course, isHeader: false));
        }
      }
    }

    if (groups['Other']!.isNotEmpty) {
      for (var course in groups['Other']!) {
        items.add(_CourseRenderItem(course: course, isHeader: false));
      }
    }

    return items;
  }

  Widget _buildCategoryHeader(String category, int count) {
    final isExpanded = _expandedCategories.contains(category);
    return InkWell(
      onTap: () {
        setState(() {
          if (isExpanded) {
            _expandedCategories.remove(category);
          } else {
            _expandedCategories.add(category);
          }
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF311B92).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF311B92).withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Icon(
              category == 'Masters' 
                  ? Icons.workspace_premium 
                  : (category == 'Bachelors' ? Icons.school : Icons.psychology),
              color: const Color(0xFF311B92),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count programs available',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: const Color(0xFF311B92).withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubCourseCard(String course, String? category) {
    final isSelected = course == _selectedCourse;
    return Padding(
      padding: EdgeInsets.only(left: category != null ? 24.0 : 0.0),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedCourse = course;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected 
                ? const Color(0xFF311B92).withValues(alpha: 0.08)
                : const Color(0xFF311B92).withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected 
                  ? const Color(0xFF311B92)
                  : const Color(0xFF311B92).withValues(alpha: 0.08),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF311B92) : const Color(0xFF6366F1),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  course,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                isSelected ? Icons.check_circle : Icons.check_circle_outline,
                color: isSelected 
                    ? const Color(0xFF311B92)
                    : const Color(0xFF311B92).withValues(alpha: 0.3),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseRenderItem {
  final String? category;
  final String? course;
  final int count;
  final bool isHeader;

  _CourseRenderItem({
    this.category,
    this.course,
    this.count = 0,
    required this.isHeader,
  });
}
