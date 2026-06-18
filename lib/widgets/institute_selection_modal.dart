import 'dart:async';
import 'package:flutter/material.dart';
import '../data/institutes_data.dart';
import '../services/ai_logic_service.dart';
import '../services/logo_service.dart';

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
    setState(() {
      _selectedInstitute = institute;
    });

    if (institute.courses.isEmpty) {
      setState(() {
        _isLoadingCourses = true;
      });
      try {
        final courses = await AiLogicService().searchUniversityCourses(institute.name, '');
        if (mounted && _selectedInstitute?.name == institute.name) {
          setState(() {
            // We can't modify the const institute, we must replace it
            _selectedInstitute = Institute(
              name: institute.name,
              state: institute.state,
              type: institute.type,
              courses: courses.map((c) => c['name'] ?? 'Unknown Course').toList(),
            );
            _isLoadingCourses = false;
          });
        }
      } catch (e) {
        if (mounted && _selectedInstitute?.name == institute.name) {
          setState(() {
             // Fallback courses if AI fails
             _selectedInstitute = Institute(
              name: institute.name,
              state: institute.state,
              type: institute.type,
              courses: ['MS Computer Science', 'MBA', 'Data Science', 'Engineering'],
            );
            _isLoadingCourses = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
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
            itemCount: _selectedInstitute!.courses.length,
            itemBuilder: (context, index) {
              final course = _selectedInstitute!.courses[index];
              return InkWell(
                onTap: () {
                  Navigator.pop(context, {
                    'institute': _selectedInstitute,
                    'course': course,
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF311B92).withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF311B92).withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF6366F1),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          course,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.check_circle_outline,
                        color: const Color(0xFF311B92).withValues(alpha: 0.3),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              );
            },
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
                  Text(
                    institute.courses.isEmpty 
                        ? 'Explore AI Courses' 
                        : '${institute.courses.length} Courses Available',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black.withValues(alpha: 0.6),
                    ),
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
}
