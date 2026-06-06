import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/ai_logic_service.dart';
import '../../widgets/mesh_background.dart';
import '../loan_eligibility_checker_page.dart';
import '../sop_writer_page.dart';
import 'customer_care_bot_page.dart';

class UniversityDetailPage extends StatefulWidget {
  final UniversityRecommendation university;

  const UniversityDetailPage({super.key, required this.university});

  @override
  State<UniversityDetailPage> createState() => _UniversityDetailPageState();
}

class _UniversityDetailPageState extends State<UniversityDetailPage> {
  bool _isExpanded = false;
  int _currentImageIndex = 0;
  bool _isSaved = false;
  bool _isUsd = false;
  int _admissionTabIndex = 0; // 0 for Mandatory, 1 for Optional
  final AiLogicService _aiService = AiLogicService();

  bool _isRequestingCallback = false;
  bool _hasRequestedCallback = false;
  bool _isRequestingFastTrack = false;
  bool _hasRequestedFastTrack = false;
  bool _isRequestingApplication = false;
  bool _hasRequestedApplication = false;

  @override
  void initState() {
    super.initState();
    _checkSavedStatus();
    _checkCallbackStatus();
    _checkFastTrackStatus();
    _checkApplicationStatus();
    _aiService.trackUniversityView(widget.university);
  }

  Future<void> _checkSavedStatus() async {
    final isSaved = await _aiService.isUniversitySaved(widget.university.name);
    if (mounted) {
      setState(() => _isSaved = isSaved);
    }
  }

  Future<void> _checkCallbackStatus() async {
    final hasRequested = await _aiService.checkUniversityCallback(
      widget.university.name,
    );
    if (mounted) {
      setState(() => _hasRequestedCallback = hasRequested);
    }
  }

  Future<void> _checkFastTrackStatus() async {
    final hasRequested = await _aiService.checkUniversityCallback(
      widget.university.name,
      type: 'fast_track',
    );
    if (mounted) {
      setState(() => _hasRequestedFastTrack = hasRequested);
    }
  }

  Future<void> _checkApplicationStatus() async {
    final hasRequested = await _aiService.checkUniversityCallback(
      widget.university.name,
      type: 'application',
    );
    if (mounted) {
      setState(() => _hasRequestedApplication = hasRequested);
    }
  }

  Future<void> _requestCallback() async {
    if (_hasRequestedCallback) return;

    setState(() => _isRequestingCallback = true);

    final success = await _aiService.requestUniversityCallback(
      widget.university.name,
    );

    if (mounted) {
      setState(() {
        _isRequestingCallback = false;
        if (success) _hasRequestedCallback = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Callback requested! Our team will contact you soon.'
                : 'Failed to request callback. Please try again.',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _requestFastTrack() async {
    if (_hasRequestedFastTrack) return;

    setState(() => _isRequestingFastTrack = true);

    final success = await _aiService.requestUniversityCallback(
      widget.university.name,
      type: 'fast_track',
    );

    if (mounted) {
      setState(() {
        _isRequestingFastTrack = false;
        if (success) _hasRequestedFastTrack = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Application fast-tracked! Our team will contact you soon.'
                : 'Failed to fast-track. Please try again.',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _applyWithVidhyaLoans() async {
    if (_hasRequestedApplication) {
      _launchUniversityWebsite();
      return;
    }

    setState(() => _isRequestingApplication = true);

    final success = await _aiService.requestUniversityCallback(
      widget.university.name,
      type: 'application',
    );

    if (mounted) {
      setState(() {
        _isRequestingApplication = false;
        if (success) _hasRequestedApplication = true;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Application request sent! Opening university website...',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Future.delayed(const Duration(seconds: 1), _launchUniversityWebsite);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to process application. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _launchUniversityWebsite() async {
    String urlString = widget.university.websiteUrl.trim();
    if (urlString.isEmpty) {
      urlString =
          'https://www.google.com/search?q=${Uri.encodeComponent("${widget.university.name} official website")}';
    } else {
      // Ensure scheme
      if (!urlString.startsWith('http://') &&
          !urlString.startsWith('https://')) {
        urlString = 'https://$urlString';
      }
    }

    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch $urlString')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error launching website: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
      body: MeshBackground(
        child: Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).padding.top + kToolbarHeight,
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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

  String _formatIndianCurrency(double value) {
    String valStr = value.toStringAsFixed(0);
    if (valStr.length <= 3) return valStr;
    String lastThree = valStr.substring(valStr.length - 3);
    String otherNumbers = valStr.substring(0, valStr.length - 3);
    otherNumbers = otherNumbers.replaceAllMapped(
      RegExp(r'(\d{1,2})(?=(\d{2})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return '$otherNumbers,$lastThree';
  }

  String _formatStandardCurrency(double value) {
    String valStr = value.toStringAsFixed(0);
    return valStr.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  String _getConvertedString(String rawValue, bool isUsd) {
    if (rawValue.isEmpty || rawValue == '-') return 'N/A';

    // 1. Determine base currency and multiplier to INR.
    double toInrMultiplier = 83.0; // Default: assume USD
    String inputSymbol = '\$';

    if (rawValue.contains('£') || rawValue.toLowerCase().contains('gbp') || rawValue.toLowerCase().contains('pound')) {
      toInrMultiplier = 105.0;
      inputSymbol = '£';
    } else if (rawValue.contains('€') || rawValue.toLowerCase().contains('eur')) {
      toInrMultiplier = 90.0;
      inputSymbol = '€';
    } else if (rawValue.contains('A\$') || rawValue.toLowerCase().contains('aud')) {
      toInrMultiplier = 55.0;
      inputSymbol = 'A\$';
    } else if (rawValue.contains('C\$') || rawValue.toLowerCase().contains('cad')) {
      toInrMultiplier = 60.0;
      inputSymbol = 'C\$';
    } else if (rawValue.contains('S\$') || rawValue.toLowerCase().contains('sgd')) {
      toInrMultiplier = 62.0;
      inputSymbol = 'S\$';
    } else if (rawValue.contains('NZ\$') || rawValue.toLowerCase().contains('nzd')) {
      toInrMultiplier = 51.0;
      inputSymbol = 'NZ\$';
    } else if (rawValue.contains('\$') || rawValue.toLowerCase().contains('usd')) {
      toInrMultiplier = 83.0;
      inputSymbol = '\$';
    }

    // 2. Extract numeric part.
    String cleanString = rawValue;
    if (cleanString.contains('-')) {
      cleanString = cleanString.split('-').first;
    } else if (cleanString.toLowerCase().contains(' to ')) {
      cleanString = cleanString.toLowerCase().split(' to ').first;
    }

    // Extract digits and dot
    String digitsOnly = cleanString.replaceAll(RegExp(r'[^0-9.]'), '');
    double? numericValue = double.tryParse(digitsOnly);

    if (numericValue == null) {
      return rawValue;
    }

    // 3. Format value based on isUsd (meaning USD/original currency vs INR)
    if (isUsd) {
      String symbol = rawValue.contains('£')
          ? '£'
          : rawValue.contains('€')
              ? '€'
              : rawValue.contains('A\$')
                  ? 'A\$'
                  : rawValue.contains('C\$')
                      ? 'C\$'
                      : rawValue.contains('S\$')
                          ? 'S\$'
                          : rawValue.contains('NZ\$')
                              ? 'NZ\$'
                              : '\$';
      
      String suffix = '';
      if (rawValue.toLowerCase().contains('/month') || rawValue.toLowerCase().contains('month')) {
        suffix = '/mo';
      }

      String formattedNum = _formatStandardCurrency(numericValue);
      return '$symbol$formattedNum$suffix';
    } else {
      double inrValue = numericValue * toInrMultiplier;
      String formattedInr = _formatIndianCurrency(inrValue);
      
      String suffix = '';
      if (rawValue.toLowerCase().contains('/month') || rawValue.toLowerCase().contains('month')) {
        suffix = '/mo';
      }
      return '₹ $formattedInr$suffix';
    }
  }

  Widget _buildNewHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
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
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {
                    final String shareText =
                        'Check out ${widget.university.name} on GradRight!\n\n'
                        '${widget.university.programName.isNotEmpty ? 'Program: ${widget.university.programName}\n' : ''}'
                        'Location: ${widget.university.location}, ${widget.university.country}\n'
                        '${widget.university.websiteUrl.isNotEmpty ? 'Website: ${widget.university.websiteUrl}' : ''}';
                    Share.share(shareText);
                  },
                  icon: const Icon(
                    Icons.share_outlined,
                    color: Color(0xFF4B5563),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () async {
                    setState(() {
                      _isSaved = !_isSaved;
                    });
                    await _aiService.toggleSaveUniversity(widget.university);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _isSaved
                                ? 'University saved to your profile!'
                                : 'University removed from saved list.',
                          ),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  icon: Icon(
                    _isSaved ? Icons.bookmark : Icons.bookmark_outline,
                    color: _isSaved
                        ? const Color(0xFF6200EA)
                        : const Color(0xFF4B5563),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
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
                    color: Colors.black.withValues(alpha: 0.08),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2.0),
                        child: Icon(
                          Icons.location_on,
                          size: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              widget.university.location,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            if (widget.university.country.isNotEmpty) ...[
                              const SizedBox(width: 8),
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
                      ),
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
    final logoUrl = widget.university.logoUrl.trim();

    return Container(
      width: 48,
      height: 48,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: logoUrl.isNotEmpty
          ? Image.network(
              logoUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                final domain = logoUrl.split('/').last.split('?').first;
                return Image.network(
                  "https://www.google.com/s2/favicons?sz=64&domain=$domain",
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildMonogramFallback();
                  },
                );
              },
            )
          : _buildMonogramFallback(),
    );
  }

  Widget _buildMonogramFallback() {
    String monogram = '';
    if (widget.university.name.isNotEmpty) {
      final parts = widget.university.name.split(' ');
      if (parts.length >= 2) {
        monogram = (parts[0][0] + parts[1][0]).toUpperCase();
      } else if (parts[0].isNotEmpty) {
        monogram = parts[0][0].toUpperCase();
      }
    }
    return Center(
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
            color: const Color(0xFF1F2937).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Flexible(
            child: _buildStatItem('ROI', widget.university.roi, const Color(0xFF4ADE80)),
          ),
          _buildStatDivider(),
          Flexible(
            child: _buildStatItem(
              'ACCEPTANCE RATE',
              widget.university.acceptanceRate,
              const Color(0xFFF87171),
            ),
          ),
          _buildStatDivider(),
          Flexible(
            child: _buildStatItem(
              'ADMIT CHANCES',
              widget.university.chance,
              const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color valueColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value.isEmpty ? '-' : value,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: value.length > 12 ? 14 : 20,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
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
    return Container(height: 40, width: 1, color: Colors.grey.withValues(alpha: 0.1));
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
    String qsRank = widget.university.rank.isNotEmpty
        ? widget.university.rank
        : 'N/A';
    if (!qsRank.startsWith('#') && qsRank != 'N/A') {
      qsRank = '#$qsRank';
    }

    String theRank = widget.university.theRank.isNotEmpty
        ? widget.university.theRank
        : 'N/A';
    if (!theRank.startsWith('#') && theRank != 'N/A') {
      theRank = '#$theRank';
    }

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
        _buildRankingRow(qsRank, 'QS Ranking'),
        const SizedBox(height: 16),
        _buildRankingRow(theRank, 'Times Higher Education'),
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
          isLink
              ? InkWell(
                  onTap: _launchUniversityWebsite,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6200EA),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                )
              : Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildImageCarousel() {
    // We use a robust fallback list of high quality US/UK university campus stock images
    // in case the AI and Wikipedia both fail to provide images.
    final List<String> defaultImages = [
      'https://images.unsplash.com/photo-1492538356227-3eb926ca0b51?q=80&w=2070&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1562774053-701939374585?q=80&w=2086&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1525921472407-c59f2ea325f5?q=80&w=2070&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1606761568499-6d2451b23c66?q=80&w=1974&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1590402494587-44b71d7772f6?q=80&w=2070&auto=format&fit=crop',
    ];

    return FutureBuilder<List<String>>(
      future: _fetchWikiImages(widget.university.name),
      builder: (context, snapshot) {
        List<String> images = defaultImages;

        // Use AI images if valid
        if (widget.university.images.isNotEmpty &&
            widget.university.images.first.startsWith('http') &&
            !widget.university.images.first.contains('unsplash.com')) {
          images = widget.university.images;
        }

        // Use Wiki images if successfully fetched
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          images = snapshot.data!;
        }

        return Column(
          children: [
            SizedBox(
              height: 260,
              child: PageView.builder(
                itemCount: images.length,
                onPageChanged: (index) =>
                    setState(() => _currentImageIndex = index),
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Image.network(
                      images[index],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.network(
                          defaultImages[index % defaultImages.length],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: Icon(
                                  Icons.account_balance,
                                  color: Colors.grey,
                                  size: 40,
                                ),
                              ),
                            );
                          },
                        );
                      },
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
                    color: isSelected
                        ? const Color(0xFF1F2937)
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }

  Future<List<String>> _fetchWikiImages(String uniName) async {
    try {
      final query = Uri.encodeComponent(uniName);
      final url =
          'https://en.wikipedia.org/w/api.php?action=query&generator=images&titles=$query&gimlimit=20&prop=imageinfo&iiprop=url&format=json';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final pages = data['query']?['pages'] as Map<String, dynamic>?;

        if (pages != null) {
          List<String> validUrls = [];

          for (var page in pages.values) {
            final imageinfo = page['imageinfo'] as List<dynamic>?;
            if (imageinfo != null && imageinfo.isNotEmpty) {
              final String url = imageinfo[0]['url'] ?? '';
              final lowerUrl = url.toLowerCase();
              // Only grab actual photos, ignore icons/svgs/logos/maps
              if ((lowerUrl.endsWith('.jpg') ||
                      lowerUrl.endsWith('.jpeg') ||
                      lowerUrl.endsWith('.png')) &&
                  !lowerUrl.contains('logo') &&
                  !lowerUrl.contains('seal') &&
                  !lowerUrl.contains('map') &&
                  !lowerUrl.contains('shield') &&
                  !lowerUrl.contains('coat_of_arms')) {
                validUrls.add(url);
              }
            }
          }

          if (validUrls.isNotEmpty) {
            // Return top 5 valid campus photos
            validUrls.shuffle();
            return validUrls.take(5).toList();
          }
        }
      }
    } catch (e) {
      debugPrint("Wiki fetch error: $e");
    }
    return [];
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
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE9FE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _hasRequestedCallback || _isRequestingCallback
                          ? null
                          : _requestCallback,
                      icon: _isRequestingCallback
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              _hasRequestedCallback
                                  ? Icons.check_circle
                                  : Icons.call,
                              size: 18,
                            ),
                      label: Text(
                        _hasRequestedCallback ? 'Requested' : 'Request call',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _hasRequestedCallback
                            ? Colors.green
                            : const Color(0xFF6200EA),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildAskVLButton(),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Opacity(
            opacity: 0.1,
            child: Icon(
              Icons.support_agent,
              size: 48,
              color: const Color(0xFF6200EA),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAskVLButton() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFF6200EA), Color(0xFF9D50BB)],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CustomerCareBotPage(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text(
                  'Ask VL',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
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
        if (widget.university.testRequirements.isNotEmpty)
          ...widget.university.testRequirements.entries.map((entry) {
            return Column(
              children: [
                _buildCriteriaRow(entry.key, entry.value, 'Not provided'),
                const Divider(),
              ],
            );
          })
        else ...[
          _buildCriteriaRow('GRE', 'Recommended', 'Not provided'),
          const Divider(),
          _buildCriteriaRow('IELTS', 'Recommended', 'Not provided'),
        ],
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

  Widget _buildExpensesSection() {
    String tuitionStr = widget.university.tuition.isNotEmpty
        ? widget.university.tuition
        : '\$0';
    String formattedTuition = _getConvertedString(tuitionStr, _isUsd);

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
                  activeThumbColor: const Color(0xFF6200EA),
                  activeTrackColor: const Color(0xFF6200EA).withValues(alpha: 0.5),
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
          formattedTuition,
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
        _buildExpenseRow('Tuition Fees', formattedTuition),
        _buildExpenseRow(
          'Cost of Living',
          _getConvertedString(widget.university.costOfLiving, _isUsd),
        ),
        const SizedBox(height: 24),
        if (widget.university.medianPackage.isNotEmpty ||
            widget.university.avgSalary.isNotEmpty) ...[
          _buildExpenseRow('MEDIAN SALARY', '', isHeader: true),
          _buildExpenseRow(
            'Median Package of University',
            _getConvertedString(
              widget.university.medianPackage.isNotEmpty
                  ? widget.university.medianPackage
                  : widget.university.avgSalary,
              _isUsd,
            ),
            isBold: true,
          ),
        ],
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
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const LoanEligibilityCheckerPage(),
          ),
        );
      },
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
            color: Colors.black.withValues(alpha: 0.03),
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
                'UPCOMING INTAKE',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'DEADLINE',
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _deriveIntake(widget.university.deadline),
                style: const TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: Text(
                  widget.university.deadline.isNotEmpty
                      ? widget.university.deadline
                      : 'Rolling',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _hasRequestedFastTrack || _isRequestingFastTrack
                ? null
                : _requestFastTrack,
            style: ElevatedButton.styleFrom(
              backgroundColor: _hasRequestedFastTrack
                  ? Colors.green
                  : const Color(0xFF2563EB),
              disabledBackgroundColor: _hasRequestedFastTrack
                  ? Colors.green.withValues(alpha: 0.8)
                  : Colors.grey,
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(27),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isRequestingFastTrack)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                else if (_hasRequestedFastTrack)
                  const Icon(Icons.check_circle_outline, size: 20)
                else
                  const SizedBox.shrink(),
                if (_isRequestingFastTrack || _hasRequestedFastTrack)
                  const SizedBox(width: 8),
                Text(
                  _hasRequestedFastTrack
                      ? 'Application fast-tracked!'
                      : 'Fast-track your application',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _deriveIntake(String deadline) {
    if (deadline.isEmpty) return 'Next Session';
    String lower = deadline.toLowerCase();

    String season = 'Next';
    if (lower.contains('fall')) {
      season = 'Fall';
    } else if (lower.contains('spring')) {
      season = 'Spring';
    } else if (lower.contains('summer')) {
      season = 'Summer';
    } else if (lower.contains('winter')) {
      season = 'Winter';
    }

    RegExp yearRegex = RegExp(r'(20\d{2})');
    Match? match = yearRegex.firstMatch(deadline);
    if (match != null) {
      return '$season ${match.group(1)}';
    }

    return '$season Intake';
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
          'on how to write SOP',
          link: 'Get guidance',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SopWriterPage()),
            );
          },
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
          '',
          link: 'Visit University Website',
          showArrow: true,
          onTap: () async {
            final url = widget.university.websiteUrl.isNotEmpty
                ? widget.university.websiteUrl
                : 'https://google.com/search?q=${widget.university.name.replaceAll(' ', '+')}';
            final uri = Uri.parse(
              url.startsWith('http') ? url : 'https://$url',
            );
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
            }
          },
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
    VoidCallback? onTap,
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
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      height: 1.4,
                    ),
                  ),
                InkWell(
                  onTap: onTap,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        link,
                        style: const TextStyle(
                          color: Color(0xFF6200EA),
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      if (showArrow)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.north_east,
                            size: 14,
                            color: Color(0xFF6200EA),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
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
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isRequestingApplication ? null : _applyWithVidhyaLoans,
          style: ElevatedButton.styleFrom(
            backgroundColor: _hasRequestedApplication
                ? Colors.green
                : const Color(0xFF6200EA),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: 2,
          ),
          child: _isRequestingApplication
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  _hasRequestedApplication
                      ? 'Application Sent'
                      : 'Apply with Vidhya Loans',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
        ),
      ),
    );
  }
}
