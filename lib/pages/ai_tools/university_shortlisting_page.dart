import 'package:flutter/material.dart';
import '../../widgets/mesh_background.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../services/ai_logic_service.dart';
import 'university_results_page.dart';
import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../apply_loan_page.dart';

class UniversityShortlistingPage extends StatefulWidget {
  final String? initialFlow;
  const UniversityShortlistingPage({super.key, this.initialFlow});

  @override
  State<UniversityShortlistingPage> createState() =>
      _UniversityShortlistingPageState();
}

class _UniversityShortlistingPageState
    extends State<UniversityShortlistingPage> {
  final List<ShortlistMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  String _flow = 'initial';
  String? _selectedUniversity;
  String? _bachelorCourse;
  String? _selectedCountry;
  String? _selectedField;
  String? _admitStatus;
  String? _cgpa;
  String? _pincode;
  String? _cosignerRelation;
  String? _cosignerType;
  double? _cosignerIncome;
  String? _cosignerPhone;
  bool? _claimCollateral;
  String? _collateralType;
  double? _collateralValue;
  double? _loanAmount;
  String? _backlogs;
  String? _backlogCount;
  String? _testStatus;
  Map<String, String>? _testScores;
  String? _workExperience;
  bool _hasLoanBids = false;
  bool _isGeneratingResults = false;
  String? _activeFlow;
  LoanRecommendationResult? _loanRecommendation;
  final List<Map<String, String>> _selectedUniversities = [];
  String? _tempUniversity;
  String? _tempCourse;

  @override
  void initState() {
    super.initState();
    if (widget.initialFlow == 'recommendations') {
      Future.delayed(const Duration(milliseconds: 500), () {
        _startRecommendationsFlow();
      });
    } else {
      Future.delayed(const Duration(milliseconds: 500), () {
        _addAiMessage(
          'Looking for answers to your studies abroad questions?',
          isHeader: true,
        );
        Future.delayed(const Duration(milliseconds: 800), () {
          _addAiMessage('How can we support you today?');
          setState(() {
            _flow = 'recommendations_type';
          });
        });
      });
    }
  }

  void _startRecommendationsFlow() async {
    _addAiMessage('AI Recommendations ✨', isHeader: true);
    final prefs = await SharedPreferences.getInstance();
    final String? userId = prefs.getString('userId');

    if (userId != null) {
      _addAiMessage("Checking for previous recommendations securely...");
      try {
        final chatData = await AiLogicService().getLatestShortlistChat(userId);
        if (chatData != null && mounted) {
          final recommendationsJson = chatData['recommendations'];
          final messagesJson = chatData['messages'];

          if (recommendationsJson != null &&
              (recommendationsJson as List).isNotEmpty) {
            final recs = (recommendationsJson)
                .map((json) => UniversityRecommendation.fromJson(json))
                .toList();

            _addAiMessage("Loading your last recommendations...");

            if (messagesJson != null) {
              setState(() {
                _messages.clear();
                _messages.addAll(
                  (messagesJson as List)
                      .map((m) => ShortlistMessage.fromJson(m))
                      .toList(),
                );
                _flow = 'completed';
              });
            }

            Future.delayed(const Duration(milliseconds: 1500), () {
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        UniversityResultsPage(recommendations: recs),
                  ),
                );
              }
            });
            return; // Exit early if loaded from DB
          }
        }
      } catch (e) {
        debugPrint('Failed to load DB recommendations: $e');
      }
    }

    // Check for Master's recommendations first (Primary flow)
    final mastersCached = prefs.getString('latest_masters_recommendations');
    if (mastersCached != null && mastersCached != "[]") {
      try {
        final List<dynamic> data = jsonDecode(mastersCached);
        final recs = data
            .map((json) => UniversityRecommendation.fromJson(json))
            .toList();

        if (recs.isNotEmpty) {
          _addAiMessage("Loading your Master's recommendations...");
          final String? chatCached = prefs.getString('latest_masters_chat');
          if (chatCached != null) {
            final List<dynamic> chatData = jsonDecode(chatCached);
            setState(() {
              _messages.clear();
              _messages.addAll(
                chatData.map((m) => ShortlistMessage.fromJson(m)).toList(),
              );
              _flow = 'completed';
            });
          }

          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      UniversityResultsPage(recommendations: recs),
                ),
              );
            }
          });
          return;
        }
      } catch (e) {
        debugPrint('Failed to load Master\'s recommendations from cache: $e');
      }
    }

    // Check for Evaluation recommendations
    final evaluateCached = prefs.getString('latest_evaluate_recommendations');
    if (evaluateCached != null && evaluateCached != "[]") {
      try {
        final List<dynamic> data = jsonDecode(evaluateCached);
        final recs = data
            .map((json) => UniversityRecommendation.fromJson(json))
            .toList();

        if (recs.isNotEmpty) {
          _addAiMessage("Loading your last evaluations...");
          final String? chatCached = prefs.getString('latest_evaluate_chat');
          if (chatCached != null) {
            final List<dynamic> chatData = jsonDecode(chatCached);
            setState(() {
              _messages.clear();
              _messages.addAll(
                chatData.map((m) => ShortlistMessage.fromJson(m)).toList(),
              );
              _flow = 'completed';
            });
          }

          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      UniversityResultsPage(recommendations: recs),
                ),
              );
            }
          });
          return;
        }
      } catch (e) {
        debugPrint('Failed to load Evaluation recommendations from cache: $e');
      }
    }

    // No history found, start fresh
    Future.delayed(const Duration(milliseconds: 800), () {
      _addAiMessage(
        "Welcome! It looks like we haven't created a plan yet. Let's start fresh!",
      );
      setState(() {
        _flow = 'recommendations_menu';
      });
    });
  }

  void _handleOptionSelected(String option) {
    setState(() {
      _messages.add(
        ShortlistMessage(text: option, isUser: true, flowState: 'initial'),
      );
      _flow = 'processing';
    });
    _scrollToBottom();

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        if (option == "Help me on my Master's plan") {
          _activeFlow = 'masters';
          _addAiMessage("Alright! Which country do you want to study in?");
          _flow = 'masters_country';
        } else if (option == "Help me on my Bachelor's plan") {
          _activeFlow = 'bachelors';
          _addAiMessage(
            "Great! Which country are you targeting for your Bachelor's?",
          );
          _flow = 'masters_country'; // Reuse the country selection flow
        } else if (option == "Need help with an education loan") {
          _activeFlow = 'loan';
          _addAiMessage(
            "I'd be happy to help. First, let me understand your current admission status.",
          );
          _flow = 'loan_admit_status';
        } else if (option == "Evaluate my shortlisted universities") {
          _activeFlow = 'evaluate';
          _addAiMessage(
            "Sure! Let's evaluate your shortlist. Which university would you like to add first?",
          );
          _flow = 'evaluate_uni_search';
        }
      }
    });
  }

  void _addAiMessage(String text, {bool isHeader = false}) {
    if (!mounted) return;
    setState(() {
      _messages.add(
        ShortlistMessage(text: text, isUser: false, isHeader: isHeader),
      );
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _addSelectedUniversity() {
    if (_tempUniversity != null && _tempCourse != null) {
      setState(() {
        _selectedUniversities.add({
          'name': _tempUniversity!,
          'course': _tempCourse!,
        });
        _tempUniversity = null;
        _tempCourse = null;
      });
    }
  }

  void _handleEdit(ShortlistMessage message) {
    if (message.flowState == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Response?"),
        content: const Text(
          "Going back will reset your subsequent answers. Do you want to continue?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performEdit(message);
            },
            child: const Text("Edit", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _performEdit(ShortlistMessage message) {
    setState(() {
      int index = _messages.indexOf(message);
      if (index != -1) {
        _messages.removeRange(index, _messages.length);
        _flow = message.flowState!;
      }
    });
  }

  Future<void> _generateShortlist() async {
    setState(() => _isGeneratingResults = true);

    if (_activeFlow == null) {
      if (_flow.startsWith('loan_')) {
        _activeFlow = 'loan';
      } else if (_flow == 'test_scores' ||
          _flow == 'test_status' ||
          _flow == 'completed') {
        _activeFlow = 'masters';
      }
    }

    try {
      if (_activeFlow == 'loan') {
        final profile = {
          'degree': 'Bachelor\'s',
          'country': 'India',
          'major': _bachelorCourse ?? 'Engineering',
          'gpa': _cgpa ?? '8.0',
          'backlogs': _backlogs ?? 'No',
          'backlogCount': _backlogCount ?? '0',
          'testStatus': _testStatus ?? 'Not taken',
          'testScores': _testScores,
          'admitStatus': _admitStatus,
          'pincode': _pincode,
          'cosignerRelation': _cosignerRelation,
          'cosignerType': _cosignerType,
          'cosignerIncome': _cosignerIncome,
          'claimCollateral': _claimCollateral == true ? 'Yes' : 'No',
          'collateralType': _collateralType,
          'collateralValue': _collateralValue,
          'experience': _workExperience,
          'loanAmount': _loanAmount ?? 1500000.0,
        };

        final result = await AiLogicService().getLoanRecommendations(profile);

        if (mounted) {
          setState(() {
            _isGeneratingResults = false;
            _loanRecommendation = result;
            _hasLoanBids = _admitStatus != 'Yet to Apply';
            _flow = 'completed';
          });
        }
        return;
      }

      final profile = {
        'degree': _activeFlow == 'masters' ? 'Master\'s' : 'Bachelor\'s',
        'country': _selectedCountry ?? 'USA',
        'major': _selectedField ?? 'Computer Science',
        'bachelorCourse': _bachelorCourse,
        'gpa': _cgpa ?? '8.0',
        'backlogs': _backlogs ?? 'No',
        'backlogCount': _backlogCount ?? '0',
        'tests': _testScores != null && _testScores!.isNotEmpty
            ? _testScores!.entries.map((e) => '${e.key}: ${e.value}').join(', ')
            : _testStatus ?? 'Not taken',
        'pincode': _pincode,
        'cosignerRelation': _cosignerRelation,
        'cosignerType': _cosignerType,
        'cosignerIncome': _cosignerIncome,
        'cosignerPhone': _cosignerPhone,
        'claimCollateral': _claimCollateral,
        'collateralType': _collateralType,
        'collateralValue': _collateralValue,
        'admitStatus': _admitStatus,
        'experience': _workExperience,
        'selectedUniversities': _activeFlow == 'evaluate'
            ? _selectedUniversities
            : null,
      };

      final prefs = await SharedPreferences.getInstance();
      final String? userId = prefs.getString('userId');
      final List<Map<String, String>> chatMessages = _messages
          .map((m) => m.toApiJson())
          .toList();

      ShortlistResult result;
      if (_activeFlow == 'evaluate') {
        result = await AiLogicService().evaluateShortlist(
          profile,
          userId: userId,
          messages: chatMessages,
        );
      } else {
        result = await AiLogicService().shortlistUniversities(
          profile,
          userId: userId,
          messages: chatMessages,
        );
      }

      if (mounted) {
        // Cache the recommendations for the Home Tab
        try {
          final prefs = await SharedPreferences.getInstance();
          final String recommendationsJson = jsonEncode(
            result.recommendations.map((uni) => uni.toJson()).toList(),
          );

          // Store both in general and specific slot
          await prefs.setString(
            'latest_ai_recommendations',
            recommendationsJson,
          );

          final String chatJson = jsonEncode(
            _messages.map((m) => m.toJson()).toList(),
          );

          if (_activeFlow == 'evaluate') {
            await prefs.setString(
              'latest_evaluate_recommendations',
              recommendationsJson,
            );
            await prefs.setString('latest_evaluate_chat', chatJson);
          } else if (_activeFlow == 'masters') {
            await prefs.setString(
              'latest_masters_recommendations',
              recommendationsJson,
            );
            await prefs.setString('latest_masters_chat', chatJson);
          }
        } catch (e) {
          debugPrint('Failed to cache recommendations: $e');
        }

        // AI Summary Message
        setState(() {
          _messages.add(
            ShortlistMessage(
              text:
                  "Based on your background in ${_selectedField ?? 'your field'} and a CGPA of ${_cgpa ?? 'your score'}, I've analyzed several universities in ${_selectedCountry ?? 'your target country'}.",
              isUser: false,
            ),
          );
        });

        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          setState(() {
            _messages.add(
              ShortlistMessage(
                text:
                    "I've shortlisted the top matching universities for your profile. Let's take a look!",
                isUser: false,
              ),
            );
            _isGeneratingResults = false;
            // Set flow to completed BEFORE navigating to ensure the state is stable
            _flow = 'completed';
          });

          await Future.delayed(const Duration(seconds: 1));

          if (mounted) {
            // Navigate to results page
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UniversityResultsPage(
                  recommendations: result.recommendations,
                ),
              ),
            ).then((_) {
              // Ensure we are in a clean state if they come back
              if (mounted) setState(() {});
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGeneratingResults = false;
          _flow = 'error';
          _addAiMessage(
            "I encountered an unexpected issue while generating your results. Would you like to try again?",
          );
        });
      }
    }
  }

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
          "VL Advisor",
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: MeshBackground(
        child: Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).padding.top + kToolbarHeight,
            ),
            Expanded(
              child: _messages.isEmpty
                  ? const SizedBox.shrink()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(
                        left: 20,
                        right: 20,
                        top: 16,
                        bottom: 24,
                      ),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return _buildMessage(message);
                      },
                    ),
            ),
            _buildInteractionArea(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(ShortlistMessage message) {
    if (message.isHeader) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Text(
          message.text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      );
    }

    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: () {
          if (message.isUser && message.flowState != null) {
            _handleEdit(message);
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(16),
          constraints: const BoxConstraints(maxWidth: 300),
          decoration: BoxDecoration(
            color: message.isUser ? const Color(0xFFE5D5FA) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: message.isUser && message.flowState != null
                ? Border.all(
                    color: Colors.purple.withAlpha((0.3 * 255).toInt()),
                  )
                : null,
            boxShadow: message.isUser
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withAlpha((0.05 * 255).toInt()),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              message.isUser || message.isDoneAnimating
                  ? Text(
                      message.text,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    )
                  : _TypewriterText(
                      text: message.text,
                      onFinished: () {
                        setState(() {
                          message.isDoneAnimating = true;
                        });
                      },
                    ),
              if (message.isUser && message.flowState != null)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Icon(Icons.edit, size: 12, color: Colors.purple),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInteractionArea() {
    if (_flow == 'recommendations_menu') {
      return Row(
        children: [
          Expanded(
            child: _OptionCard(
              icon: Icons.school_outlined,
              text: "Master's plan universities",
              color: Colors.purple,
              isSmall: true,
              onTap: () async {
                _activeFlow = 'masters';
                setState(() {
                  _messages.add(
                    ShortlistMessage(
                      text: "Master's plan universities",
                      isUser: true,
                      flowState: 'recommendations_menu',
                    ),
                  );
                  _flow = 'processing';
                });

                final prefs = await SharedPreferences.getInstance();
                final cached = prefs.getString(
                  'latest_masters_recommendations',
                );

                if (cached != null) {
                  Future.delayed(const Duration(milliseconds: 1000), () {
                    if (!mounted) return;
                    try {
                      _addAiMessage(
                        "Loading your last Master's recommendations...",
                      );
                      final List<dynamic> data = jsonDecode(cached);
                      final recs = data
                          .map(
                            (json) => UniversityRecommendation.fromJson(json),
                          )
                          .toList();

                      // Also restore chat messages if available
                      final String? chatCached = prefs.getString(
                        'latest_masters_chat',
                      );
                      if (chatCached != null) {
                        final List<dynamic> chatData = jsonDecode(chatCached);
                        setState(() {
                          _messages.clear();
                          _messages.addAll(
                            chatData
                                .map((m) => ShortlistMessage.fromJson(m))
                                .toList(),
                          );
                          _flow = 'completed';
                        });
                      } else {
                        setState(() {
                          _flow = 'completed';
                        });
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              UniversityResultsPage(recommendations: recs),
                        ),
                      );
                    } catch (e) {
                      debugPrint(
                        'Failed to load Master\'s recommendations from cache: $e',
                      );
                      _addAiMessage(
                        "Failed to load cached recommendations. Let's start fresh!",
                      );
                      Future.delayed(const Duration(milliseconds: 800), () {
                        _addAiMessage("Which country do you want to study in?");
                        setState(() => _flow = 'masters_country');
                      });
                    }
                  });
                } else {
                  Future.delayed(const Duration(milliseconds: 1000), () {
                    _addAiMessage(
                      "I don't have any previous data for your Master's plan. Let's start fresh!",
                    );
                    Future.delayed(const Duration(milliseconds: 800), () {
                      _addAiMessage("Which country do you want to study in?");
                      setState(() => _flow = 'masters_country');
                    });
                  });
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _OptionCard(
              icon: Icons.analytics_outlined,
              text: "Evaluate universities",
              color: Colors.orange,
              isSmall: true,
              onTap: () async {
                _activeFlow = 'evaluate';
                setState(() {
                  _messages.add(
                    ShortlistMessage(
                      text: "Evaluate universities",
                      isUser: true,
                      flowState: 'recommendations_menu',
                    ),
                  );
                  _flow = 'processing';
                });

                final prefs = await SharedPreferences.getInstance();
                final cached = prefs.getString(
                  'latest_evaluate_recommendations',
                );

                if (cached != null) {
                  Future.delayed(const Duration(milliseconds: 1000), () {
                    if (!mounted) return;
                    try {
                      _addAiMessage("Loading your last evaluations...");
                      final List<dynamic> data = jsonDecode(cached);
                      final recs = data
                          .map(
                            (json) => UniversityRecommendation.fromJson(json),
                          )
                          .toList();

                      // Also restore chat messages if available
                      final String? chatCached = prefs.getString(
                        'latest_evaluate_chat',
                      );
                      if (chatCached != null) {
                        final List<dynamic> chatData = jsonDecode(chatCached);
                        setState(() {
                          _messages.clear();
                          _messages.addAll(
                            chatData
                                .map((m) => ShortlistMessage.fromJson(m))
                                .toList(),
                          );
                          _flow = 'completed';
                        });
                      } else {
                        setState(() {
                          _flow = 'completed';
                        });
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              UniversityResultsPage(recommendations: recs),
                        ),
                      );
                    } catch (e) {
                      debugPrint(
                        'Failed to load Evaluation recommendations from cache: $e',
                      );
                      _addAiMessage(
                        "Failed to load cached evaluations. Let's start a new evaluation!",
                      );
                      Future.delayed(const Duration(milliseconds: 800), () {
                        _addAiMessage(
                          "Which university would you like to evaluate first?",
                        );
                        setState(() => _flow = 'evaluate_uni_search');
                      });
                    }
                  });
                } else {
                  Future.delayed(const Duration(milliseconds: 1000), () {
                    _addAiMessage(
                      "No previous evaluations found. Let's start a new evaluation!",
                    );
                    Future.delayed(const Duration(milliseconds: 800), () {
                      _addAiMessage(
                        "Which university would you like to evaluate first?",
                      );
                      setState(() => _flow = 'evaluate_uni_search');
                    });
                  });
                }
              },
            ),
          ),
        ],
      );
    } else if (_flow == 'recommendations_type') {
      return Column(
        children: [
          const SizedBox(height: 20),
          // VL Avatar Placeholder could go here
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    _OptionCard(
                      icon: Icons.help_outline_rounded,
                      text: "Help me on my Master's plan",
                      color: Colors.purple,
                      isSmall: true,
                      onTap: () =>
                          _handleOptionSelected("Help me on my Master's plan"),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    _OptionCard(
                      icon: Icons.attach_money_rounded,
                      text: "Need help with an education loan",
                      color: Colors.green,
                      isSmall: true,
                      onTap: () => _handleOptionSelected(
                        "Need help with an education loan",
                      ),
                    ),
                    const SizedBox(height: 12),
                    _OptionCard(
                      icon: Icons.book_outlined,
                      text: "Evaluate my shortlisted universities",
                      color: Colors.orange,
                      isSmall: true,
                      onTap: () => _handleOptionSelected(
                        "Evaluate my shortlisted universities",
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    } else if (_flow == 'masters_country') {
      return _DynamicCountrySelector(
        onSelect: (country) {
          setState(() {
            _selectedCountry = country;
            _messages.add(
              ShortlistMessage(
                text: country,
                isUser: true,
                flowState: 'masters_country',
              ),
            );
            _flow = 'processing';
          });

          Future.delayed(const Duration(milliseconds: 1000), () {
            _addAiMessage(
              "Great choice. Now, which field interests you the most?",
            );
            setState(() => _flow = 'field_of_interest');
          });
        },
      );
    } else if (_flow == 'field_of_interest') {
      return _SearchableList(
        hintText: "Search your field (e.g. Computer Science)...",
        initialSearch: true,
        onSearch: (query) async {
          return await AiLogicService().searchFields(query);
        },
        onSelect: (field) {
          setState(() {
            _selectedField = field;
            _messages.add(
              ShortlistMessage(
                text: field,
                isUser: true,
                flowState: 'field_of_interest',
              ),
            );
            _flow = 'processing';
          });

          Future.delayed(const Duration(milliseconds: 1000), () {
            _addAiMessage(
              "Nice! When do you plan to start your ${_activeFlow == 'bachelors' ? "Bachelor's" : "Master's"}?",
            );
            setState(() => _flow = 'masters_start_date');
          });
        },
      );
    } else if (_flow == 'masters_start_date') {
      return _StartDateSelector(
        onSelect: (date) {
          setState(() {
            _messages.add(
              ShortlistMessage(
                text: date,
                isUser: true,
                flowState: 'masters_start_date',
              ),
            );
            _flow = 'processing';
          });

          Future.delayed(const Duration(milliseconds: 1200), () {
            if (_activeFlow == 'bachelors') {
              _addAiMessage(
                "Almost there! To find the perfect programs, I need a bit more about your academic background. Which high school or 12th board school did you study in?",
              );
              setState(() => _flow = 'bachelors_university');
            } else {
              _addAiMessage(
                "Perfect! To give you a detailed roadmap, I'll need a bit more info.\n\nFirst, how much work experience do you have (in months)?",
              );
              setState(() => _flow = 'work_experience');
            }
          });
        },
      );
    } else if (_flow == 'loan_start_date') {
      return _StartDateSelector(
        isIndividualMonths: true,
        onSelect: (date) {
          setState(() {
            _messages.add(
              ShortlistMessage(
                text: date,
                isUser: true,
                flowState: 'loan_start_date',
              ),
            );
            _flow = 'processing';
          });

          Future.delayed(const Duration(milliseconds: 1000), () {
            if (_admitStatus == 'Yet to Apply') {
              _addAiMessage("Next up. Which country do you want to study in?");
              setState(() => _flow = 'loan_country');
            } else {
              _addAiMessage(
                "Understood. Please select your ${_activeFlow == 'bachelors' ? "bachelor's" : "master's"} university.",
              );
              setState(() => _flow = 'loan_university');
            }
          });
        },
      );
    } else if (_flow == 'loan_country') {
      return _DynamicCountrySelector(
        onSelect: (country) {
          setState(() {
            _selectedCountry = country;
            _messages.add(
              ShortlistMessage(
                text: country,
                isUser: true,
                flowState: 'loan_country',
              ),
            );
            _flow = 'processing';
          });

          Future.delayed(const Duration(milliseconds: 1000), () {
            _addAiMessage("Perfect. What's your intended area of study?");
            setState(() => _flow = 'loan_field');
          });
        },
      );
    } else if (_flow == 'loan_field') {
      return _SearchableList(
        hintText: "Search area of study",
        onSearch: (query) => AiLogicService().searchFields(query),
        onSelect: (field) {
          setState(() {
            _selectedField = field;
            _messages.add(
              ShortlistMessage(
                text: field,
                isUser: true,
                flowState: 'loan_field',
              ),
            );
            _flow = 'processing';
          });

          Future.delayed(const Duration(milliseconds: 1000), () {
            _addAiMessage("Great choice. Now, select your dream university.");
            setState(() => _flow = 'loan_dream_university');
          });
        },
      );
    } else if (_flow == 'loan_dream_university') {
      return _SearchableList(
        hintText: "Search your university",
        onSearch: (query) => AiLogicService().searchGlobalUniversities(
          query,
          degree: 'Master\'s',
          country: _selectedCountry,
        ),
        onSelect: (uni) {
          setState(() {
            _selectedUniversity = uni;
            _messages.add(
              ShortlistMessage(
                text: uni,
                isUser: true,
                flowState: 'loan_dream_university',
              ),
            );
            _messages.add(
              ShortlistMessage(
                text:
                    "A very popular course. Now tell us how much is the loan amount that you require?",
                isUser: false,
              ),
            );
            _flow = 'loan_amount';
          });
        },
      );
    } else if (_flow == 'loan_university') {
      return _SearchableList(
        hintText: "Search your university",
        onSearch: (query) => AiLogicService().searchGlobalUniversities(
          query,
          degree: _activeFlow == 'bachelors' ? 'Bachelor\'s' : 'Master\'s',
        ),
        onSelect: (uni) {
          setState(() {
            _selectedUniversity = uni;
            _messages.add(
              ShortlistMessage(
                text: uni,
                isUser: true,
                flowState: 'loan_university',
              ),
            );
            _messages.add(
              ShortlistMessage(
                text: "Which course are you going to pursue?",
                isUser: false,
              ),
            );
            _flow = 'loan_course';
          });
        },
      );
    } else if (_flow == 'loan_course') {
      return _SearchableList(
        hintText: "Search your course",
        onSearch: (query) => AiLogicService().searchUniversityCourses(
          _selectedUniversity!,
          query,
          degree: _activeFlow == 'bachelors' ? 'Bachelor\'s' : 'Master\'s',
        ),
        onSelect: (course) {
          setState(() {
            _messages.add(
              ShortlistMessage(
                text: course,
                isUser: true,
                flowState: 'loan_course',
              ),
            );
            _messages.add(
              ShortlistMessage(
                text:
                    "A very popular course. how much loan amount do you need?",
                isUser: false,
              ),
            );
            _flow = 'loan_amount';
          });
        },
      );
    } else if (_flow == 'loan_amount') {
      return _LoanAmountSelector(
        onConfirm: (amount) {
          setState(() {
            _loanAmount = amount;
            final formatted = NumberFormat.currency(
              locale: 'en_IN',
              symbol: '₹',
              decimalDigits: 0,
            ).format(amount);
            _messages.add(
              ShortlistMessage(
                text: formatted,
                isUser: true,
                flowState: 'loan_amount',
              ),
            );
            _messages.add(
              ShortlistMessage(
                text: "Enter your work experience (in months)",
                isUser: false,
              ),
            );
            _flow = 'loan_work_experience';
          });
        },
      );
    } else if (_flow == 'loan_work_experience') {
      return _WorkExperienceInput(
        onSubmit: (exp) {
          setState(() {
            _workExperience = exp;
            _messages.add(
              ShortlistMessage(
                text: exp.toString(),
                isUser: true,
                flowState: 'loan_work_experience',
              ),
            );
            _flow = 'processing';
          });

          Future.delayed(const Duration(milliseconds: 1000), () {
            _addAiMessage(
              "Got it. To check your loan feasibility, I'll need your current location's pincode.",
            );
            setState(() => _flow = 'loan_pincode');
          });
        },
      );
    } else if (_flow == 'loan_pincode') {
      return _PincodeInput(
        onSubmit: (pincode) {
          setState(() {
            _pincode = pincode;
            _messages.add(
              ShortlistMessage(
                text: pincode,
                isUser: true,
                flowState: 'loan_pincode',
              ),
            );
            _flow = 'processing';
          });

          Future.delayed(const Duration(milliseconds: 1200), () {
            _addAiMessage("Thank you. Now, who will be your Co-signer?");
            setState(() => _flow = 'loan_cosigner');
          });
        },
      );
    } else if (_flow == 'loan_cosigner') {
      return _CoSignerSelector(
        onSelect: (relation) {
          setState(() {
            _cosignerRelation = relation;
            _messages.add(
              ShortlistMessage(
                text: relation,
                isUser: true,
                flowState: 'loan_cosigner',
              ),
            );
            _flow = 'processing';
          });

          Future.delayed(const Duration(milliseconds: 1000), () {
            _addAiMessage("Noted. What is your co-signer's income type?");
            setState(() => _flow = 'loan_cosigner_type');
          });
        },
      );
    } else if (_flow == 'loan_cosigner_type') {
      return _CoSignerTypeSelector(
        onSelect: (type) {
          setState(() {
            _cosignerType = type;
            _messages.add(
              ShortlistMessage(
                text: type,
                isUser: true,
                flowState: 'loan_cosigner_type',
              ),
            );
            _flow = 'processing';
          });

          Future.delayed(const Duration(milliseconds: 1000), () {
            _addAiMessage("And what is their monthly income?");
            setState(() => _flow = 'loan_cosigner_income');
          });
        },
      );
    } else if (_flow == 'loan_cosigner_income') {
      return _IncomeInput(
        hintText: "Enter monthly income",
        onSubmit: (incomeStr) {
          final income = double.tryParse(incomeStr) ?? 0;
          setState(() {
            _cosignerIncome = income;
            _messages.add(
              ShortlistMessage(
                text: NumberFormat.currency(
                  locale: 'en_IN',
                  symbol: '₹',
                  decimalDigits: 0,
                ).format(income),
                isUser: true,
                flowState: 'loan_cosigner_income',
              ),
            );
            _flow = 'processing';
          });

          Future.delayed(const Duration(milliseconds: 1000), () {
            _addAiMessage(
              "Almost done with the co-signer details. What is their phone number?",
            );
            setState(() => _flow = 'loan_cosigner_phone');
          });
        },
      );
    } else if (_flow == 'loan_cosigner_phone') {
      return _PhoneInput(
        onSubmit: (phone) {
          setState(() {
            _cosignerPhone = phone;
            _messages.add(
              ShortlistMessage(
                text: phone,
                isUser: true,
                flowState: 'loan_cosigner_phone',
              ),
            );
            _flow = 'processing';
          });

          Future.delayed(const Duration(milliseconds: 1200), () {
            _addAiMessage(
              "Thanks! Having collateral can significantly improve your loan chances. Do you want to add any collaterals?",
            );
            setState(() => _flow = 'loan_collateral_claim');
          });
        },
      );
    } else if (_flow == 'loan_collateral_claim') {
      return _CollateralClaimSelector(
        onSelect: (claim) {
          setState(() {
            _claimCollateral = claim == 'Yes';
            _messages.add(
              ShortlistMessage(
                text: claim,
                isUser: true,
                flowState: 'loan_collateral_claim',
              ),
            );
            _flow = 'processing';
          });

          Future.delayed(const Duration(milliseconds: 1000), () {
            if (_claimCollateral!) {
              _addAiMessage(
                "Smart move. What type of collateral are we looking at?",
              );
              setState(() => _flow = 'loan_collateral_type');
            } else {
              _addAiMessage(
                "No problem. Next, let's talk about your test scores. Have you given any tests?",
              );
              setState(() => _flow = 'loan_test_status');
            }
          });
        },
      );
    } else if (_flow == 'loan_collateral_type') {
      return _CollateralTypeSelector(
        onSelect: (type) {
          setState(() {
            _collateralType = type;
            _messages.add(
              ShortlistMessage(
                text: type,
                isUser: true,
                flowState: 'loan_collateral_type',
              ),
            );
            _flow = 'processing';
          });

          Future.delayed(const Duration(milliseconds: 1000), () {
            _addAiMessage(
              "Got it. And what's the approximate value of this collateral?",
            );
            setState(() => _flow = 'loan_collateral_value');
          });
        },
      );
    } else if (_flow == 'loan_collateral_value') {
      return _CollateralAmountSelector(
        onConfirm: (value) {
          setState(() {
            _collateralValue = value;
            _messages.add(
              ShortlistMessage(
                text: NumberFormat.currency(
                  locale: 'en_IN',
                  symbol: '₹',
                  decimalDigits: 0,
                ).format(value),
                isUser: true,
                flowState: 'loan_collateral_value',
              ),
            );
            _flow = 'processing';
          });

          Future.delayed(const Duration(milliseconds: 1200), () {
            _addAiMessage(
              "Great! Now, let's talk about your academic tests. Have you given any?",
            );
            setState(() => _flow = 'loan_test_status');
          });
        },
      );
    } else if (_flow == 'loan_test_status') {
      return _TestStatusSelector(
        onSelect: (status) {
          setState(() {
            _testStatus = status;
            _messages.add(
              ShortlistMessage(
                text: status,
                isUser: true,
                flowState: 'loan_test_status',
              ),
            );
            _flow = 'processing';
          });

          Future.delayed(const Duration(milliseconds: 1000), () {
            if (status == "Yes, I've taken them") {
              _addAiMessage(
                "That’s a great start. Please enter your test scores. If you have multiple, you can separate them.",
              );
              _activeFlow = 'loan';
              setState(() => _flow = 'test_scores');
            } else {
              if (_activeFlow == 'loan' && _admitStatus == 'Yet to Apply') {
                _addAiMessage(
                  "No problem! I've got enough information to get started on your roadmap.",
                );
                setState(() => _flow = 'completed');
                _generateShortlist();
              } else if (_admitStatus != 'Yet to Apply') {
                _addAiMessage(
                  "Understood. Tell us about your bachelor's university?",
                );
                setState(() => _flow = 'loan_bachelors_university');
              } else {
                _addAiMessage(
                  "Thank you! I've received your details. Let me process this for you...",
                );
                setState(() => _flow = 'completed');
                _generateShortlist();
              }
            }
          });
        },
      );
    } else if (_flow == 'work_experience') {
      return _WorkExperienceInput(
        onSubmit: (experience) {
          setState(() {
            _workExperience = experience;
            _messages.add(
              ShortlistMessage(
                text: "Work Experience: $experience months",
                isUser: true,
                flowState: 'work_experience',
              ),
            );
            _flow = 'processing';
          });

          Future.delayed(const Duration(milliseconds: 1000), () {
            if (_activeFlow == 'bachelors') {
              _addAiMessage(
                "Almost there! To find the perfect programs, I need a bit more about your academic background. Which school/college did you study in for 12th/High School?",
              );
            } else {
              _addAiMessage(
                "Almost there! To find the perfect programs, I need a bit more about your academic background. Which university did you graduate from?",
              );
            }
            setState(() => _flow = 'bachelors_university');
          });
        },
      );
    } else if (_flow == 'bachelors_university') {
      return _SearchableList(
        hintText: "Search for your university..",
        onSearch: (query) async {
          return await AiLogicService().searchGlobalUniversities(
            query,
            degree: 'Bachelor\'s',
            country: 'India',
          );
        },
        onSelect: (university) {
          setState(() {
            _selectedUniversity = university;
            _messages.add(
              ShortlistMessage(
                text: university,
                isUser: true,
                flowState: 'bachelors_university',
              ),
            );
            _flow = 'processing';
          });

          Future.delayed(const Duration(milliseconds: 1000), () {
            if (_activeFlow == 'bachelors') {
              _addAiMessage("Noted. What was your stream/major in 12th class? (e.g. Science, Commerce, Arts)");
            } else {
              _addAiMessage("Noted. And what was your bachelor's course?");
            }
            setState(() => _flow = 'bachelors_course');
          });
        },
      );
    } else if (_flow == 'bachelors_course') {
      return _SearchableList(
        hintText: "Search here..",
        onSearch: (query) async {
          if (_selectedUniversity != null) {
            return await AiLogicService().searchUniversityCourses(
              _selectedUniversity!,
              query,
              degree: 'Bachelor\'s',
            );
          }
          return [];
        },
        onSelect: (course) {
          setState(() {
            _bachelorCourse = course;
            _messages.add(
              ShortlistMessage(
                text: course,
                isUser: true,
                flowState: 'bachelors_course',
              ),
            );
            _flow = 'processing';
          });

          Future.delayed(const Duration(milliseconds: 1000), () {
            if (_activeFlow == 'bachelors') {
              _addAiMessage(
                "Got it. What was your 12th board percentage/GPA?",
              );
            } else {
              _addAiMessage(
                "Got it. What was your graduation CGPA? (on a scale of 10)",
              );
            }
            setState(() => _flow = 'cgpa');
          });
        },
      );
    } else if (_flow == 'cgpa') {
      return _CgpaInput(
        onSubmit: (cgpa) {
          setState(() {
            _cgpa = cgpa;
            _messages.add(
              ShortlistMessage(text: cgpa, isUser: true, flowState: 'cgpa'),
            );
            _flow = 'processing';
          });

          Future.delayed(const Duration(milliseconds: 1000), () {
            if (_activeFlow == 'bachelors') {
              _addAiMessage(
                "Final check: Have you taken any entrance/language exams like SAT, ACT, IELTS, or TOEFL?",
              );
            } else {
              _addAiMessage(
                "Final check: Have you taken any entrance exams like GRE, GMAT, IELTS, or TOEFL?",
              );
            }
            setState(() => _flow = 'test_status');
          });
        },
      );
    } else if (_flow == 'test_status') {
      return _TestStatusSelector(
        onSelect: (status) {
          setState(() {
            _testStatus = status;
            _messages.add(
              ShortlistMessage(
                text: status,
                isUser: true,
                flowState: 'test_status',
              ),
            );
            _flow = 'processing';
          });

          Future.delayed(const Duration(milliseconds: 1000), () {
            if (status == "Yes, I've taken them") {
              if (_activeFlow == 'bachelors') {
                _addAiMessage(
                  "Great! Please share your test scores (SAT, ACT, IELTS, or TOEFL).",
                );
              } else {
                _addAiMessage(
                  "Great! Please share your test scores (GRE, GMAT, IELTS, or TOEFL).",
                );
              }
              setState(() => _flow = 'test_scores');
            } else {
              _addAiMessage(
                "No problem! I have everything I need. Based on your profile, I'll find the best programs for you.",
              );
              setState(() => _flow = 'evaluate_get_results');
            }
          });
        },
      );
    } else if (_flow == 'test_scores') {
      return _TestScoresInput(
        onSubmit: (scores) {
          setState(() {
            _testScores = scores;
            _messages.add(
              ShortlistMessage(
                text: "Scores submitted",
                isUser: true,
                flowState: 'test_scores',
              ),
            );
            _flow = 'processing';
          });

          Future.delayed(const Duration(milliseconds: 1500), () {
            if (_activeFlow == 'loan' && _admitStatus != 'Yet to Apply') {
              _addAiMessage(
                "Got it. Now, tell us about your bachelor's university?",
              );
              setState(() => _flow = 'loan_bachelors_university');
            } else if (_activeFlow == 'loan' &&
                _admitStatus == 'Yet to Apply') {
              _addAiMessage(
                "Thank you! Generating your loan options and roadmap...",
              );
              setState(() => _flow = 'completed');
              _generateShortlist();
            } else {
              if (_activeFlow == 'bachelors') {
                _addAiMessage(
                  "Thank you! Based on your 12th grades and test scores, I've found relevant Bachelor's programs that best meet your needs.",
                );
              } else {
                _addAiMessage(
                  "Thank you! Based on your merits, I've found relevant programs that best meet your needs.",
                );
              }
              setState(() => _flow = 'evaluate_get_results');
            }
          });
        },
      );
    } else if (_flow == 'loan_bachelors_university') {
      return _SearchableList(
        hintText: "Search your university",
        onSearch: (query) => AiLogicService().searchGlobalUniversities(
          query,
          degree: 'Bachelor\'s',
          country: 'India',
        ),
        onSelect: (uni) {
          setState(() {
            _selectedUniversity = uni;
            _messages.add(
              ShortlistMessage(
                text: uni,
                isUser: true,
                flowState: 'loan_bachelors_university',
              ),
            );
            _flow = 'processing';
          });

          Future.delayed(const Duration(milliseconds: 1000), () {
            _addAiMessage("Noted. And what was your bachelor's course?");
            setState(() => _flow = 'loan_bachelors_course');
          });
        },
      );
    } else if (_flow == 'loan_bachelors_course') {
      return _SearchableList(
        hintText: "Search here..",
        onSearch: (query) async {
          if (_selectedUniversity != null) {
            return await AiLogicService().searchUniversityCourses(
              _selectedUniversity!,
              query,
              degree: 'Bachelor\'s',
            );
          }
          return [];
        },
        onSelect: (course) {
          setState(() {
            _bachelorCourse = course;
            _messages.add(
              ShortlistMessage(
                text: course,
                isUser: true,
                flowState: 'loan_bachelors_course',
              ),
            );
            _flow = 'processing';
          });

          Future.delayed(const Duration(milliseconds: 1000), () {
            _addAiMessage(
              "Got it. Do you have any backlogs in your bachelor's?",
            );
            setState(() => _flow = 'loan_backlogs');
          });
        },
      );
    } else if (_flow == 'loan_backlogs') {
      return _BacklogsSelector(
        onSelect: (status) {
          setState(() {
            _backlogs = status;
            _messages.add(
              ShortlistMessage(
                text: status,
                isUser: true,
                flowState: 'loan_backlogs',
              ),
            );
            _flow = 'processing';
          });

          Future.delayed(const Duration(milliseconds: 1000), () {
            if (status == 'Yes') {
              _addAiMessage("I see. How many backlogs do you have?");
              setState(() => _flow = 'loan_backlog_count');
            } else {
              _addAiMessage(
                "That's great. What was your graduation CGPA? (on a scale of 10)",
              );
              setState(() => _flow = 'loan_cgpa');
            }
          });
        },
      );
    } else if (_flow == 'loan_backlog_count') {
      return _BacklogCountInput(
        onSubmit: (count) {
          setState(() {
            _backlogCount = count;
            _messages.add(
              ShortlistMessage(
                text: count,
                isUser: true,
                flowState: 'loan_backlog_count',
              ),
            );
            _flow = 'processing';
          });

          Future.delayed(const Duration(milliseconds: 1000), () {
            _addAiMessage(
              "Got it. Finally, what was your bachelor's CGPA? (on a scale of 10)",
            );
            setState(() => _flow = 'loan_cgpa');
          });
        },
      );
    } else if (_flow == 'loan_cgpa') {
      return _CgpaInput(
        onSubmit: (cgpa) {
          setState(() {
            _cgpa = cgpa;
            _messages.add(
              ShortlistMessage(
                text: cgpa,
                isUser: true,
                flowState: 'loan_cgpa',
              ),
            );
            _flow = 'processing';
          });

          Future.delayed(const Duration(milliseconds: 1500), () {
            _addAiMessage(
              "Perfect! I've got all the details. Generating your loan roadmap and options now...",
            );
            setState(() => _flow = 'completed');
            _generateShortlist();
          });
        },
      );
    } else if (_flow == 'completed') {
      if (_activeFlow == 'loan') {
        if (_isGeneratingResults) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        return _LoanResults(
          hasBids: _hasLoanBids,
          admitStatus: _admitStatus,
          testStatus: _testStatus,
          recommendation: _loanRecommendation,
          onAction: (bank) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ApplyLoanPage(
                  initialUniversity: _selectedUniversity ?? (_selectedUniversities.isNotEmpty ? _selectedUniversities.first['name'] : null),
                  initialCourse: _bachelorCourse ?? _tempCourse,
                  initialCountry: _selectedCountry,
                  initialBank: bank,
                ),
              ),
            );
          },
        );
      }
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Center(child: CircularProgressIndicator()),
      );
    } else if (_isGeneratingResults || _flow == 'processing') {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6A1B9A)),
            ),
            const SizedBox(height: 16),
            Text(
              "AI is thinking...",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      );
    } else if (_flow == 'loan_admit_status') {
      return _AdmitStatusGrid(
        onSelect: (status) {
          setState(() {
            _admitStatus = status;
            _messages.add(
              ShortlistMessage(
                text: status,
                isUser: true,
                flowState: 'loan_admit_status',
              ),
            );
            _flow = 'processing';
          });

          Future.delayed(const Duration(milliseconds: 1200), () {
            String degree = _activeFlow == 'bachelors'
                ? "bachelor's"
                : "master's";
            String reply =
                "Alright! Please select your enrolling month for your $degree?";
            if (status == 'Yet to Apply') {
              reply =
                  "Got it. When are you planning to enroll for your $degree?";
            }
            _addAiMessage(reply);
            setState(() => _flow = 'loan_start_date');
          });
        },
      );
    } else if (_flow == 'evaluate_uni_search') {
      return _SearchableList(
        hintText: "Search your university",
        onSearch: (query) => AiLogicService().searchGlobalUniversities(
          query,
          degree: _activeFlow == 'bachelors' ? 'Bachelor\'s' : 'Master\'s',
          country: _selectedCountry,
        ),
        onSelect: (uni) {
          setState(() {
            _tempUniversity = uni;
            _messages.add(
              ShortlistMessage(
                text: uni,
                isUser: true,
                flowState: 'evaluate_uni_search',
              ),
            );
            _flow = 'processing';
          });

          Future.delayed(const Duration(milliseconds: 1000), () {
            _addAiMessage("Great choice! Now, which course are you targeting?");
            setState(() => _flow = 'evaluate_course_search');
          });
        },
      );
    } else if (_flow == 'evaluate_course_search') {
      return _SearchableList(
        hintText: "Search your course",
        onSearch: (query) => AiLogicService().searchUniversityCourses(
          _tempUniversity!,
          query,
          degree: _activeFlow == 'bachelors' ? 'Bachelor\'s' : 'Master\'s',
        ),
        onSelect: (course) {
          setState(() {
            _tempCourse = course;
            _messages.add(
              ShortlistMessage(
                text: course,
                isUser: true,
                flowState: 'evaluate_course_search',
              ),
            );
            _addSelectedUniversity();
            _flow = 'processing';
          });

          Future.delayed(const Duration(milliseconds: 1000), () {
            if (_selectedUniversities.length >= 5) {
              _addAiMessage(
                "That's a great start. You can add up-to 5 universities that you have in mind.",
              );
            } else {
              _addAiMessage(
                "Got it! I've added that to your list. Would you like to evaluate more universities or should we proceed?",
              );
            }
            setState(() => _flow = 'evaluate_list_and_add');
          });
        },
      );
    } else if (_flow == 'evaluate_list_and_add') {
      return Column(
        children: [
          _EvaluationList(
            universities: _selectedUniversities,
            onRemove: (index) {
              setState(() {
                _selectedUniversities.removeAt(index);
              });
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (_selectedUniversities.length < 5)
                Expanded(
                  child: _AddUniversityButton(
                    onTap: () {
                      _addAiMessage(
                        "Which other university would you like to add?",
                      );
                      setState(() => _flow = 'evaluate_uni_search');
                    },
                  ),
                ),
              if (_selectedUniversities.length < 5) const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _addAiMessage(
                      "Great! Your preferences are saved. Share your bachelor's details and test scores, and our AI will find your best-fit programs.",
                    );
                    Future.delayed(const Duration(milliseconds: 1200), () {
                      _addAiMessage("Enter your work experience (in months)");
                      setState(() => _flow = 'evaluate_work_experience');
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    "Confirm & proceed",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    } else if (_flow == 'evaluate_work_experience') {
      return _WorkExperienceInput(
        onSubmit: (val) {
          setState(() {
            _workExperience = val;
            _messages.add(
              ShortlistMessage(
                text: val,
                isUser: true,
                flowState: 'evaluate_work_experience',
              ),
            );
            _flow = 'processing';
          });

          Future.delayed(const Duration(milliseconds: 1200), () {
            _addAiMessage("Almost there! Just 4 questions left.");
            Future.delayed(const Duration(milliseconds: 800), () {
              _addAiMessage("Select your bachelors university");
              setState(() => _flow = 'evaluate_bachelors_uni');
            });
          });
        },
      );
    } else if (_flow == 'evaluate_bachelors_uni') {
      return _SearchableList(
        hintText: "Search here..",
        onSearch: (query) => AiLogicService().searchGlobalUniversities(
          query,
          degree: 'Bachelor\'s',
          country: 'India',
        ),
        onSelect: (uni) {
          setState(() {
            _selectedUniversity = uni;
            _messages.add(
              ShortlistMessage(
                text: uni,
                isUser: true,
                flowState: 'evaluate_bachelors_uni',
              ),
            );
            _flow = 'processing';
          });

          Future.delayed(const Duration(milliseconds: 1000), () {
            _addAiMessage("Select your bachelor course");
            setState(() => _flow = 'evaluate_bachelors_course');
          });
        },
      );
    } else if (_flow == 'evaluate_bachelors_course') {
      return _SearchableList(
        hintText: "Search here..",
        onSearch: (query) => AiLogicService().searchUniversityCourses(
          _selectedUniversity!,
          query,
          degree: 'Bachelor\'s',
        ),
        onSelect: (course) {
          setState(() {
            _bachelorCourse = course;
            _messages.add(
              ShortlistMessage(
                text: course,
                isUser: true,
                flowState: 'evaluate_bachelors_course',
              ),
            );
            _flow = 'processing';
          });

          Future.delayed(const Duration(milliseconds: 1000), () {
            _addAiMessage("Enter Your CGPA");
            setState(() => _flow = 'evaluate_cgpa');
          });
        },
      );
    } else if (_flow == 'evaluate_cgpa') {
      return _CgpaInput(
        onSubmit: (cgpa) {
          setState(() {
            _cgpa = cgpa;
            _messages.add(
              ShortlistMessage(
                text: cgpa,
                isUser: true,
                flowState: 'evaluate_cgpa',
              ),
            );
            _flow = 'processing';
          });

          Future.delayed(const Duration(milliseconds: 1000), () {
            _addAiMessage(
              "Last question and we are all set!\nHave you taken any of these exams yet? (GRE, GMAT, IELTS, TOEFL...)",
            );
            setState(() => _flow = 'evaluate_test_status');
          });
        },
      );
    } else if (_flow == 'evaluate_test_status') {
      return _TestStatusSelector(
        onSelect: (status) {
          setState(() {
            _testStatus = status;
            _messages.add(
              ShortlistMessage(
                text: status,
                isUser: true,
                flowState: 'evaluate_test_status',
              ),
            );
            _flow = 'processing';
          });

          Future.delayed(const Duration(milliseconds: 1000), () {
            if (status == "Yes, I've taken them") {
              _addAiMessage(
                "Please share your test scores (GRE, GMAT, IELTS, or TOEFL).",
              );
              setState(() => _flow = 'evaluate_test_scores');
            } else {
              _addAiMessage(
                "Based on your merits, we've found relevant programs that best meets your needs.",
              );
              setState(() => _flow = 'evaluate_get_results');
            }
          });
        },
      );
    } else if (_flow == 'evaluate_test_scores') {
      return _TestScoresInput(
        onSubmit: (scores) {
          setState(() {
            _testScores = scores;
            _messages.add(
              ShortlistMessage(
                text: scores.entries
                    .map((e) => "${e.key}: ${e.value}")
                    .join(", "),
                isUser: true,
                flowState: 'evaluate_test_scores',
              ),
            );
            _flow = 'processing';
          });

          Future.delayed(const Duration(milliseconds: 1000), () {
            _addAiMessage(
              "Based on your merits, we've found relevant programs that best meets your needs.",
            );
            setState(() => _flow = 'evaluate_get_results');
          });
        },
      );
    } else if (_flow == 'evaluate_get_results') {
      return Center(
        child: ElevatedButton(
          onPressed: () {
            setState(() => _isGeneratingResults = true);
            _generateShortlist();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6A1B9A),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            elevation: 0,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                "Generate AI recommendations",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(width: 8),
              Icon(Icons.auto_awesome, size: 18, color: Colors.white),
            ],
          ),
        ),
      );
    } else if (_flow == 'error') {
      return Center(
        child: ElevatedButton.icon(
          onPressed: () {
            if (_activeFlow == 'loan') {
              setState(() {
                _flow = 'completed';
                _isGeneratingResults = true;
              });
              _generateShortlist();
            } else {
              setState(() {
                _flow = (_activeFlow == 'evaluate' ||
                        _activeFlow == 'masters' ||
                        _activeFlow == 'bachelors')
                    ? 'evaluate_get_results'
                    : 'test_status';
              });
            }
          },
          icon: const Icon(Icons.refresh),
          label: const Text("Try Again"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
          ),
        ),
      );
    } else if (_flow == 'completed') {
      if (_activeFlow == 'loan') {
        return _LoanResults(
          hasBids: _hasLoanBids,
          admitStatus: _admitStatus,
          testStatus: _testStatus,
          recommendation: _loanRecommendation,
          onAction: (bank) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ApplyLoanPage(
                  initialUniversity: _selectedUniversity ?? (_selectedUniversities.isNotEmpty ? _selectedUniversities.first['name'] : null),
                  initialCourse: _bachelorCourse ?? _tempCourse,
                  initialCountry: _selectedCountry,
                  initialBank: bank,
                ),
              ),
            );
          },
        );
      }
      return Center(
        child: ActionChip(
          label: const Text("View Results Again"),
          onPressed: _generateShortlist,
          avatar: const Icon(Icons.auto_awesome, size: 16),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class ShortlistMessage {
  final String text;
  final bool isUser;
  final bool isHeader;
  final String? flowState;
  bool isDoneAnimating;

  ShortlistMessage({
    required this.text,
    required this.isUser,
    this.isHeader = false,
    this.flowState,
    this.isDoneAnimating = false,
  }) {
    // User messages and headers are always done animating immediately
    if (isUser || isHeader) {
      isDoneAnimating = true;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'isHeader': isHeader,
      'flowState': flowState,
      'isDoneAnimating': isDoneAnimating,
    };
  }

  factory ShortlistMessage.fromJson(Map<String, dynamic> json) {
    return ShortlistMessage(
      text: json['text'] ?? '',
      isUser: json['isUser'] ?? false,
      isHeader: json['isHeader'] ?? false,
      flowState: json['flowState'],
      isDoneAnimating: json['isDoneAnimating'] ?? true,
    );
  }

  Map<String, String> toApiJson() {
    return {'role': isUser ? 'user' : 'bot', 'content': text};
  }
}

class _TypewriterText extends StatefulWidget {
  final String text;
  final VoidCallback onFinished;

  const _TypewriterText({required this.text, required this.onFinished});

  @override
  State<_TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<_TypewriterText> {
  String _displayedText = "";
  int _currentIndex = 0;
  Timer? _timer;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    if (widget.text.isNotEmpty) {
      _startTyping();
    } else {
      widget.onFinished();
    }
  }

  void _startTyping() {
    _typeNextCharacter();
  }

  void _typeNextCharacter() {
    if (_currentIndex < widget.text.length) {
      _timer = Timer(Duration(milliseconds: 30 + _random.nextInt(40)), () {
        if (mounted) {
          setState(() {
            _displayedText += widget.text[_currentIndex];
            _currentIndex++;
          });
          _typeNextCharacter();
        }
      });
    } else {
      widget.onFinished();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayedText,
      style: const TextStyle(fontSize: 16, color: Colors.black87),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final bool isSmall;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.text,
    required this.color,
    this.isSmall = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: isSmall ? 140 : 292,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.05 * 255).toInt()),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: color),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DynamicCountrySelector extends StatefulWidget {
  final Function(String) onSelect;

  const _DynamicCountrySelector({required this.onSelect});

  @override
  State<_DynamicCountrySelector> createState() =>
      _DynamicCountrySelectorState();
}

class _DynamicCountrySelectorState extends State<_DynamicCountrySelector> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> _countries = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchCountries(''); // Initial fetch for popular countries
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _fetchCountries(_controller.text);
    });
  }

  Future<void> _fetchCountries(String query) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final results = await AiLogicService().searchCountries(query);
      if (mounted) {
        setState(() {
          // Filter out India for destination selection if flow is masters/bachelors/evaluate
          _countries = results
              .where((c) => c['name'] != 'India')
              .cast<Map<String, String>>()
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search Bar
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: "Search Country...",
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.withAlpha((0.3 * 255).toInt()),
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
          ),
        ),
        const SizedBox(height: 16),
        // Grid
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          )
        else
          Container(
            constraints: const BoxConstraints(
              maxHeight: 300,
            ), // Dynamic height up to 300
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _countries.map((country) {
                  final countryName = country['name'] ?? 'Unknown';
                  final countryFlag = country['flag'] ?? '🌐';
                  return GestureDetector(
                    onTap: () => widget.onSelect(countryName),
                    child: Container(
                      width:
                          (MediaQuery.of(context).size.width - 64) /
                          3, // 3 columns, adjusted padding
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Text(
                            countryFlag,
                            style: const TextStyle(fontSize: 32),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            countryName,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }
}

class _AdmitStatusGrid extends StatelessWidget {
  final Function(String) onSelect;

  const _AdmitStatusGrid({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final options = [
      'Received Admit',
      'Awaiting Decision',
      'Waitlisted',
      'Yet to Apply',
      'Already On Campus',
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatusOption(
                text: options[0],
                isLarge: true,
                onTap: () => onSelect(options[0]),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: [
                  _StatusOption(
                    text: options[1],
                    onTap: () => onSelect(options[1]),
                  ),
                  const SizedBox(height: 12),
                  _StatusOption(
                    text: options[2],
                    onTap: () => onSelect(options[2]),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatusOption(
                text: options[3],
                onTap: () => onSelect(options[3]),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatusOption(
                text: options[4],
                onTap: () => onSelect(options[4]),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusOption extends StatelessWidget {
  final String text;
  final bool isLarge;
  final VoidCallback onTap;

  const _StatusOption({
    required this.text,
    this.isLarge = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: isLarge
            ? 120
            : 54, // Adjusted heights based on visual hierarchy
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade800,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _AddUniversityButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddUniversityButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3E5F5), // Light purple background
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: Colors.purple.shade700),
            const SizedBox(width: 8),
            Text(
              "Add university",
              style: TextStyle(
                color: Colors.purple.shade700,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StartDateSelector extends StatelessWidget {
  final Function(String) onSelect;
  final bool isIndividualMonths;

  const _StartDateSelector({
    required this.onSelect,
    this.isIndividualMonths = false,
  });

  List<String> _getActiveItems(int year) {
    final now = DateTime.now();
    if (year > now.year) {
      return isIndividualMonths
          ? [
              'Jan',
              'Feb',
              'Mar',
              'Apr',
              'May',
              'Jun',
              'Jul',
              'Aug',
              'Sep',
              'Oct',
              'Nov',
              'Dec',
            ]
          : ['Jan to Mar', 'Apr to Jun', 'Jul to Sep', 'Oct to Dec'];
    }

    if (isIndividualMonths) {
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      if (now.month <= months.length) {
        return months.sublist(now.month - 1);
      }
      return [];
    } else {
      final quarters = <String>[];
      final currentMonth = now.month;
      if (currentMonth <= 3) quarters.add('Jan to Mar');
      if (currentMonth <= 6) quarters.add('Apr to Jun');
      if (currentMonth <= 9) quarters.add('Jul to Sep');
      if (currentMonth <= 12) quarters.add('Oct to Dec');
      return quarters;
    }
  }

  String _getYearTitle(int year) {
    final currentYear = DateTime.now().year;
    if (year == currentYear) {
      return isIndividualMonths ? 'THIS YEAR-$year' : 'IN $year';
    } else if (year == currentYear + 1) {
      return isIndividualMonths ? 'NEXT YEAR-$year' : 'IN $year';
    } else {
      return 'IN $year';
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    int startYear = now.year;

    // Shift start year to next year if no active intakes are left in the current year
    if (_getActiveItems(startYear).isEmpty) {
      startYear += 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildYearSection(
          _getYearTitle(startYear),
          startYear,
          _getActiveItems(startYear),
        ),
        const SizedBox(height: 16),
        _buildYearSection(
          _getYearTitle(startYear + 1),
          startYear + 1,
          _getActiveItems(startYear + 1),
        ),
      ],
    );
  }

  Widget _buildYearSection(String title, int year, List<String> items) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            return ActionChip(
              label: Text(item),
              onPressed: () => onSelect("$item $year"),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              labelStyle: TextStyle(color: Colors.grey.shade800, fontSize: 13),
              padding: EdgeInsets.symmetric(
                horizontal: isIndividualMonths ? 12 : 4,
                vertical: isIndividualMonths ? 8 : 2,
              ),
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _BacklogCountInput extends StatefulWidget {
  final Function(String) onSubmit;

  const _BacklogCountInput({required this.onSubmit});

  @override
  State<_BacklogCountInput> createState() => _BacklogCountInputState();
}

class _BacklogCountInputState extends State<_BacklogCountInput> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: "Number of backlogs",
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
                hintStyle: TextStyle(color: Colors.grey),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  final count = int.tryParse(value);
                  if (count != null && count >= 0 && count <= 50) {
                    widget.onSubmit(value);
                  } else {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text("Invalid Count"),
                        content: const Text(
                          "Please enter a valid backlog count between 0 and 50.",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text("OK"),
                          ),
                        ],
                      ),
                    );
                  }
                }
              },
            ),
          ),
          IconButton(
            onPressed: () {
              final value = _controller.text;
              if (value.isNotEmpty) {
                final count = int.tryParse(value);
                if (count != null && count >= 0 && count <= 50) {
                  widget.onSubmit(value);
                } else {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Invalid Count"),
                      content: const Text(
                        "Please enter a valid backlog count between 0 and 50.",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text("OK"),
                        ),
                      ],
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.send_outlined, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _WorkExperienceInput extends StatefulWidget {
  final Function(String) onSubmit;

  const _WorkExperienceInput({required this.onSubmit});

  @override
  State<_WorkExperienceInput> createState() => _WorkExperienceInputState();
}

class _WorkExperienceInputState extends State<_WorkExperienceInput> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: "Enter your work experience",
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
                hintStyle: TextStyle(color: Colors.grey),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  final exp = int.tryParse(value);
                  if (exp != null && exp >= 0 && exp <= 300) {
                    widget.onSubmit(value);
                  } else {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Work experience must be between 0 and 300 months',
                        ),
                        backgroundColor: Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text("Invalid Experience"),
                        content: const Text(
                          "Please enter work experience between 0 and 300 months.",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text("OK"),
                          ),
                        ],
                      ),
                    );
                  }
                }
              },
            ),
          ),
          IconButton(
            onPressed: () {
              final value = _controller.text;
              if (value.isNotEmpty) {
                final exp = int.tryParse(value);
                if (exp != null && exp >= 0 && exp <= 300) {
                  widget.onSubmit(value);
                } else {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Work experience must be between 0 and 300 months',
                      ),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Invalid Experience"),
                      content: const Text(
                        "Please enter work experience between 0 and 300 months.",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text("OK"),
                        ),
                      ],
                    ),
                  );
                }
              }
            },
            icon: const Icon(
              Icons.send_rounded,
              color: Color(0xFFD482F6),
            ), // Light purple
          ),
        ],
      ),
    );
  }
}

class _SearchableList extends StatefulWidget {
  final Function(String) onSelect;
  final Future<List<dynamic>> Function(String) onSearch;
  final String hintText;
  final bool initialSearch;

  const _SearchableList({
    required this.onSelect,
    required this.onSearch,
    required this.hintText,
    this.initialSearch = false,
  });

  @override
  State<_SearchableList> createState() => _SearchableListState();
}

class _CgpaInput extends StatefulWidget {
  final Function(String) onSubmit;

  const _CgpaInput({required this.onSubmit});

  @override
  State<_CgpaInput> createState() => _CgpaInputState();
}

class _CgpaInputState extends State<_CgpaInput> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                hintText: "Enter your CGPA",
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
                hintStyle: TextStyle(color: Colors.grey),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  final cgpa = double.tryParse(value);
                  if (cgpa != null && cgpa >= 0 && cgpa <= 10) {
                    widget.onSubmit(value);
                  } else {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text("Invalid CGPA"),
                        content: const Text(
                          "Please enter a valid CGPA between 0 and 10.",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text("OK"),
                          ),
                        ],
                      ),
                    );
                  }
                }
              },
            ),
          ),
          IconButton(
            onPressed: () {
              final value = _controller.text;
              if (value.isNotEmpty) {
                final cgpa = double.tryParse(value);
                if (cgpa != null && cgpa >= 0 && cgpa <= 10) {
                  widget.onSubmit(value);
                } else {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Invalid CGPA"),
                      content: const Text(
                        "Please enter a valid CGPA between 0 and 10.",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text("OK"),
                        ),
                      ],
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.send_rounded, color: Color(0xFFD482F6)),
          ),
        ],
      ),
    );
  }
}

class _TestStatusSelector extends StatelessWidget {
  final Function(String) onSelect;

  const _TestStatusSelector({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildChip("Yes, I've taken them", context),
        const SizedBox(width: 8),
        _buildChip("Not yet", context),
      ],
    );
  }

  Widget _buildChip(String label, BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: () => onSelect(label),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      labelStyle: TextStyle(color: Colors.grey.shade800, fontSize: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }
}

class _TestScoresInput extends StatefulWidget {
  final Function(Map<String, String>) onSubmit;

  const _TestScoresInput({required this.onSubmit});

  @override
  State<_TestScoresInput> createState() => _TestScoresInputState();
}

class _TestScoresInputState extends State<_TestScoresInput> {
  final Map<String, TextEditingController> _controllers = {
    'IELTS': TextEditingController(),
    'TOEFL': TextEditingController(),
    'Duolingo': TextEditingController(),
    'GMAT': TextEditingController(),
    'GRE': TextEditingController(),
  };
  final Map<String, String?> _errors = {};

  final Map<String, double> _minValues = {
    'IELTS': 0.0,
    'TOEFL': 0.0,
    'Duolingo': 10.0,
    'GMAT': 205.0,
    'GRE': 260.0,
  };

  final Map<String, double> _maxValues = {
    'IELTS': 9.0,
    'TOEFL': 120.0,
    'Duolingo': 160.0,
    'GMAT': 805.0,
    'GRE': 340.0,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          "Tell us your exam score results that you’ve attempted so far",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        _buildScoreInput('IELTS', '/ 9'),
        _buildScoreInput('TOEFL', '/ 120'),
        _buildScoreInput('Duolingo English Test', '/ 160', key: 'Duolingo'),
        _buildScoreInput('GMAT', '/ 805'),
        _buildScoreInput('GRE', '/ 340'),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: const Text(
            "Complete",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreInput(String label, String suffix, {String? key}) {
    final controllerKey = key ?? label;
    final isDecimal = controllerKey == 'IELTS';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
              border: _errors[controllerKey] != null
                  ? Border.all(color: Colors.red.withValues(alpha: 0.5))
                  : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controllers[controllerKey],
                    keyboardType: isDecimal
                        ? const TextInputType.numberWithOptions(decimal: true)
                        : TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: "Enter Score",
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                    onChanged: (value) {
                      if (_errors.containsKey(controllerKey)) {
                        setState(() {
                          _validateField(controllerKey, value);
                        });
                      }
                    },
                  ),
                ),
                Text(
                  suffix,
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          ),
          if (_errors[controllerKey] != null)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 4),
              child: Text(
                _errors[controllerKey]!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  void _validateField(String key, String value) {
    if (value.isEmpty) {
      _errors[key] = null;
      return;
    }

    final score = double.tryParse(value);
    if (score == null) {
      _errors[key] = "Please enter a valid number";
      return;
    }

    if (key != 'IELTS') {
      if (int.tryParse(value) == null) {
        _errors[key] = "Please enter a valid integer";
        return;
      }
    }

    final min = _minValues[key];
    final max = _maxValues[key];

    if (min != null && score < min) {
      _errors[key] = "Value must be at least ${key == 'IELTS' ? min : min.toInt()}";
    } else if (max != null && score > max) {
      _errors[key] = "Value must not exceed ${key == 'IELTS' ? max : max.toInt()}";
    } else {
      _errors[key] = null;
    }
  }

  void _submit() {
    bool hasError = false;
    final scores = <String, String>{};

    setState(() {
      _controllers.forEach((key, controller) {
        _validateField(key, controller.text);
        if (_errors[key] != null) {
          hasError = true;
        }
        if (controller.text.isNotEmpty && _errors[key] == null) {
          scores[key] = controller.text;
        }
      });
    });

    if (!hasError && scores.isNotEmpty) {
      widget.onSubmit(scores);
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}

class _SearchableListState extends State<_SearchableList> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic> _items = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    if (widget.initialSearch) {
      _performSearch('');
    }
  }

  void _onTextChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(_controller.text);
    });
  }

  Future<void> _performSearch(String query) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final results = await widget.onSearch(query);
      if (mounted) {
        setState(() {
          _items = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: widget.hintText,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(10.0),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: _isLoading
                ? const SizedBox.shrink()
                : _items.isEmpty && _controller.text.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      "No results found for \"${_controller.text}\"",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      String title = "";
                      String? subtitle;

                      if (item is Map) {
                        title = item['name'] ?? "";
                        final location = item['location'];
                        final city = item['city'];
                        final country = item['country'];
                        if (location != null ||
                            city != null ||
                            country != null) {
                          subtitle = [
                            location ?? city,
                            country,
                          ].where((e) => e != null).join(", ");
                        }
                      } else {
                        title = item.toString();
                      }

                      return ListTile(
                        title: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: subtitle != null
                            ? Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              )
                            : null,
                        onTap: () => widget.onSelect(title),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _LoanAmountSelector extends StatefulWidget {
  final Function(double) onConfirm;

  const _LoanAmountSelector({required this.onConfirm});

  @override
  State<_LoanAmountSelector> createState() => _LoanAmountSelectorState();
}

class _LoanAmountSelectorState extends State<_LoanAmountSelector> {
  double _amount = 1400000;

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹ ',
      decimalDigits: 0,
    ).format(amount);
  }

  String _formatSpelledOut(double amount) {
    if (amount >= 10000000) {
      double cr = amount / 10000000;
      String crStr = cr.toStringAsFixed(2);
      if (crStr.endsWith('.00')) {
        crStr = crStr.substring(0, crStr.length - 3);
      } else if (crStr.endsWith('0')) {
        crStr = crStr.substring(0, crStr.length - 1);
      }
      return "$crStr CRORE".toUpperCase();
    } else if (amount >= 100000) {
      double lakh = amount / 100000;
      String lakhStr = lakh.toStringAsFixed(2);
      if (lakhStr.endsWith('.00')) {
        lakhStr = lakhStr.substring(0, lakhStr.length - 3);
      } else if (lakhStr.endsWith('0')) {
        lakhStr = lakhStr.substring(0, lakhStr.length - 1);
      }
      return "$lakhStr LAKH".toUpperCase();
    }
    return "";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Set your loan amount",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            "LOAN AMOUNT",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.purple.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatCurrency(_amount),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _formatSpelledOut(_amount),
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF00385D),
              inactiveTrackColor: Colors.grey.shade300,
              thumbColor: const Color(0xFF00385D),
              trackHeight: 4,
            ),
            child: Slider(
              value: _amount,
              min: 1200000,
              max: 20000000,
              onChanged: (value) {
                // Round to the nearest 50,000 for clean selection
                final rounded = (value / 50000).round() * 50000.0;
                setState(() => _amount = rounded);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "12L",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
                Text(
                  "2Cr",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => widget.onConfirm(_amount),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A1B9A),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              "Confirm",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _PincodeInput extends StatefulWidget {
  final Function(String) onSubmit;

  const _PincodeInput({required this.onSubmit});

  @override
  State<_PincodeInput> createState() => _PincodeInputState();
}

class _PincodeInputState extends State<_PincodeInput> {
  final TextEditingController _controller = TextEditingController();
  bool _isComplete = false;
  String? _address;
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final text = _controller.text;
    setState(() {
      _isComplete = text.length == 6;
      if (!_isComplete) _address = null;
    });

    if (_isComplete) {
      _performLookup(text);
    }
  }

  Future<void> _performLookup(String pincode) async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _isLoading = true);
      try {
        final address = await AiLogicService().lookupPincode(pincode);
        if (mounted) {
          setState(() {
            _address = address;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
            border: _isComplete
                ? Border.all(color: Colors.purple.shade200, width: 2)
                : Border.all(color: Colors.transparent, width: 2),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    hintText: "Enter 6-digit Pincode",
                    border: InputBorder.none,
                    counterText: "",
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  onSubmitted: (value) {
                    if (_isComplete) widget.onSubmit(value);
                  },
                ),
              ),
              if (_controller.text.isNotEmpty)
                IconButton(
                  onPressed: () => _controller.clear(),
                  icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                ),
              if (_isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  onPressed: () {
                    if (_isComplete) widget.onSubmit(_controller.text);
                  },
                  icon: Icon(
                    Icons.send_rounded,
                    color: _isComplete ? Colors.purple : Colors.grey,
                  ),
                ),
            ],
          ),
        ),
        if (_address != null)
          GestureDetector(
            onTap: () => widget.onSubmit(_controller.text),
            child: Padding(
              padding: const EdgeInsets.only(top: 12, left: 4),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                  children: [
                    TextSpan(
                      text: _controller.text,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: ", $_address",
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CoSignerSelector extends StatelessWidget {
  final Function(String) onSelect;

  const _CoSignerSelector({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final List<String> relations = [
      'Mother',
      'Father',
      'Brother',
      'Sister',
      'Cousin Brother',
      'Cousin Sister',
      'Spouse',
      'Maternal Aunt',
      'Maternal Uncle',
      'Paternal Aunt',
      'Paternal Uncle',
      'Brother-in-law',
      'Father-in-law',
      'Grandfather',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: relations.map((rel) {
        return ActionChip(
          label: Text(rel),
          onPressed: () => onSelect(rel),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          labelStyle: TextStyle(color: Colors.grey.shade800, fontSize: 14),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        );
      }).toList(),
    );
  }
}

class _CoSignerTypeSelector extends StatelessWidget {
  final Function(String) onSelect;

  const _CoSignerTypeSelector({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final List<String> types = [
      'Self-employed',
      'Salaried',
      'Farmer',
      'Pensioner',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((type) {
        return ActionChip(
          label: Text(type),
          onPressed: () => onSelect(type),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          labelStyle: TextStyle(color: Colors.grey.shade800, fontSize: 14),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        );
      }).toList(),
    );
  }
}

class _IncomeInput extends StatefulWidget {
  final String hintText;
  final Function(String) onSubmit;

  const _IncomeInput({required this.hintText, required this.onSubmit});

  @override
  State<_IncomeInput> createState() => _IncomeInputState();
}

class _IncomeInputState extends State<_IncomeInput> {
  final TextEditingController _controller = TextEditingController();
  String _spelledOut = "";

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final amount = double.tryParse(_controller.text.replaceAll(',', '')) ?? 0;
    setState(() {
      _spelledOut = _formatSpelledOut(amount);
    });
  }

  String _formatSpelledOut(double amount) {
    if (amount <= 0) return "";
    if (amount >= 10000000) {
      double cr = amount / 10000000;
      String crStr = cr.toStringAsFixed(2);
      if (crStr.endsWith('.00')) {
        crStr = crStr.substring(0, crStr.length - 3);
      } else if (crStr.endsWith('0')) {
        crStr = crStr.substring(0, crStr.length - 1);
      }
      return "$crStr CRORE ONLY".toUpperCase();
    } else if (amount >= 100000) {
      double lakh = amount / 100000;
      String lakhStr = lakh.toStringAsFixed(2);
      if (lakhStr.endsWith('.00')) {
        lakhStr = lakhStr.substring(0, lakhStr.length - 3);
      } else if (lakhStr.endsWith('0')) {
        lakhStr = lakhStr.substring(0, lakhStr.length - 1);
      }
      return "$lakhStr LAKH ONLY".toUpperCase();
    } else if (amount >= 1000) {
      double thousand = amount / 1000;
      String thousandStr = thousand.toStringAsFixed(2);
      if (thousandStr.endsWith('.00')) {
        thousandStr = thousandStr.substring(0, thousandStr.length - 3);
      } else if (thousandStr.endsWith('0')) {
        thousandStr = thousandStr.substring(0, thousandStr.length - 1);
      }
      return "$thousandStr THOUSAND ONLY".toUpperCase();
    }
    return "${amount.toStringAsFixed(0)} ONLY".toUpperCase();
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    hintStyle: const TextStyle(color: Colors.grey),
                  ),
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      widget.onSubmit(value);
                    }
                  },
                ),
              ),
              IconButton(
                onPressed: () {
                  if (_controller.text.isNotEmpty) {
                    widget.onSubmit(_controller.text);
                  }
                },
                icon: const Icon(Icons.send_rounded, color: Color(0xFFD482F6)),
              ),
            ],
          ),
        ),
        if (_spelledOut.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 4),
            child: Text(
              _spelledOut,
              style: TextStyle(
                fontSize: 10,
                color: Colors.purple.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}

class _PhoneInput extends StatefulWidget {
  final Function(String) onSubmit;

  const _PhoneInput({required this.onSubmit});

  @override
  State<_PhoneInput> createState() => _PhoneInputState();
}

class _PhoneInputState extends State<_PhoneInput> {
  final TextEditingController _controller = TextEditingController();
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {
      _isValid =
          _controller.text.length == 10 &&
          RegExp(r'^[6-9]').hasMatch(_controller.text) &&
          _controller.text.split('').toSet().length > 2;
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                hintText: "XXXXXXXXXX",
                border: InputBorder.none,
                counterText: "",
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
                hintStyle: TextStyle(color: Colors.grey),
                prefixText: '+91 ',
                prefixStyle: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onSubmitted: (value) {
                if (_isValid) widget.onSubmit(value);
              },
            ),
          ),
          IconButton(
            onPressed: () {
              if (_isValid) widget.onSubmit(_controller.text);
            },
            icon: Icon(
              Icons.send_rounded,
              color: _isValid ? const Color(0xFFD482F6) : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class _CollateralClaimSelector extends StatelessWidget {
  final Function(String) onSelect;

  const _CollateralClaimSelector({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildChip("Yes", context),
        const SizedBox(width: 8),
        _buildChip("No", context),
      ],
    );
  }

  Widget _buildChip(String label, BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: () => onSelect(label),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      labelStyle: TextStyle(color: Colors.grey.shade800, fontSize: 13),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}

class _CollateralTypeSelector extends StatelessWidget {
  final Function(String) onSelect;

  const _CollateralTypeSelector({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final List<String> types = ['Apartment', 'Home', 'Plot', 'Fixed Deposit'];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((type) {
        return ActionChip(
          label: Text(type),
          onPressed: () => onSelect(type),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          labelStyle: TextStyle(color: Colors.grey.shade800, fontSize: 13),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        );
      }).toList(),
    );
  }
}

class _BacklogsSelector extends StatelessWidget {
  final Function(String) onSelect;

  const _BacklogsSelector({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildChip("Yes", context),
        const SizedBox(width: 8),
        _buildChip("No", context),
      ],
    );
  }

  Widget _buildChip(String label, BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: () => onSelect(label),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      labelStyle: TextStyle(color: Colors.grey.shade800, fontSize: 13),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}

class _CollateralAmountSelector extends StatefulWidget {
  final Function(double) onConfirm;

  const _CollateralAmountSelector({required this.onConfirm});

  @override
  State<_CollateralAmountSelector> createState() =>
      _CollateralAmountSelectorState();
}

class _CollateralAmountSelectorState extends State<_CollateralAmountSelector> {
  double _amount = 100000;

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹ ',
      decimalDigits: 0,
    ).format(amount);
  }

  String _formatSpelledOut(double amount) {
    if (amount >= 10000000) {
      double cr = amount / 10000000;
      String crStr = cr.toStringAsFixed(2);
      if (crStr.endsWith('.00')) {
        crStr = crStr.substring(0, crStr.length - 3);
      } else if (crStr.endsWith('0')) {
        crStr = crStr.substring(0, crStr.length - 1);
      }
      return "$crStr CRORE".toUpperCase();
    } else if (amount >= 100000) {
      double lakh = amount / 100000;
      String lakhStr = lakh.toStringAsFixed(2);
      if (lakhStr.endsWith('.00')) {
        lakhStr = lakhStr.substring(0, lakhStr.length - 3);
      } else if (lakhStr.endsWith('0')) {
        lakhStr = lakhStr.substring(0, lakhStr.length - 1);
      }
      return "$lakhStr LAKH".toUpperCase();
    } else if (amount >= 1000) {
      double thousand = amount / 1000;
      String thousandStr = thousand.toStringAsFixed(2);
      if (thousandStr.endsWith('.00')) {
        thousandStr = thousandStr.substring(0, thousandStr.length - 3);
      } else if (thousandStr.endsWith('0')) {
        thousandStr = thousandStr.substring(0, thousandStr.length - 1);
      }
      return "$thousandStr THOUSAND".toUpperCase();
    }
    return "";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Set your Collateral amount",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            "COLLATERAL AMOUNT",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.purple.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatCurrency(_amount),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _formatSpelledOut(_amount),
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF00385D),
              inactiveTrackColor: Colors.grey.shade300,
              thumbColor: const Color(0xFF00385D),
              trackHeight: 4,
            ),
            child: Slider(
              value: _amount,
              min: 10000,
              max: 40000000,
              onChanged: (value) {
                // Snap slider selections to clean increments: nearest 50,000 if value >= 100,000, otherwise nearest 10,000.
                final rounded = value >= 100000
                    ? (value / 50000).round() * 50000.0
                    : (value / 10000).round() * 10000.0;
                setState(() => _amount = rounded);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "0.1L",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
                Text(
                  "4Cr",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => widget.onConfirm(_amount),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A1B9A),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              "Confirm",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoanResults extends StatefulWidget {
  final bool hasBids;
  final String? admitStatus;
  final String? testStatus;
  final LoanRecommendationResult? recommendation;
  final Function(String? bank) onAction;

  const _LoanResults({
    required this.hasBids,
    required this.admitStatus,
    required this.testStatus,
    this.recommendation,
    required this.onAction,
  });

  @override
  State<_LoanResults> createState() => _LoanResultsState();
}

class _LoanResultsState extends State<_LoanResults> {
  bool _showOffers = false;

  @override
  Widget build(BuildContext context) {
    bool isLocked = false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_showOffers) ...[
          const Text(
            "With your credentials, you're eligible for multiple loan offers.",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: widget.recommendation != null
                ? ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      GestureDetector(
                        onTap: () => widget.onAction(widget.recommendation!.primary.bank),
                        child: _LenderCard(
                          color: const Color(0xFFE3F2FD),
                          offer: widget.recommendation!.primary,
                          isLocked: isLocked,
                        ),
                      ),
                      ...widget.recommendation!.alternatives.map(
                        (offer) => GestureDetector(
                          onTap: () => widget.onAction(offer.bank),
                          child: _LenderCard(
                            color:
                                widget.recommendation!.alternatives.indexOf(offer) %
                                        2 ==
                                        0
                                    ? const Color(0xFFF5F5F5)
                                    : const Color(0xFFFFFDE7),
                            offer: offer,
                            isLocked: isLocked,
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      GestureDetector(
                        onTap: () => widget.onAction("State Bank of India"),
                        child: _LenderCard(
                          color: const Color(0xFFBBDEFB),
                          offer: LoanOffer(
                            id: '1',
                            bank: 'State Bank of India',
                            name: 'SBI GLOBAL ED-VANTAGE',
                            amount: "Up to ₹50 Lakhs",
                            rate: "8.50% - 9.25%",
                            processingTime: "3-5 working days",
                            savings: "Zero processing fee",
                            requiresCoApplicant: true,
                            requiresCollateral: false,
                            bestFor: 'Low interest',
                          ),
                          isLocked: isLocked,
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => widget.onAction("HDFC Credila"),
                        child: _LenderCard(
                          color: const Color(0xFFE0E0E0),
                          offer: LoanOffer(
                            id: '2',
                            bank: 'HDFC Credila',
                            name: 'UNSECURED EDUCATION LOAN',
                            amount: "Up to ₹60 Lakhs",
                            rate: "10.00% - 11.00%",
                            processingTime: "2-3 weeks",
                            savings: "0 Lakhs",
                            requiresCoApplicant: true,
                            requiresCollateral: false,
                            bestFor: 'Fast approval',
                        ),
                          isLocked: isLocked,
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => widget.onAction("Avanse"),
                        child: _LenderCard(
                          color: const Color(0xFFFFF9C4),
                          offer: LoanOffer(
                            id: '3',
                            bank: 'Avanse',
                            name: 'EDUCATION LOAN',
                            amount: "Up to ₹40 Lakhs",
                            rate: "11.25% - 12.25%",
                            processingTime: "4 days",
                            savings: "0.4 Lakhs",
                            requiresCoApplicant: true,
                            requiresCollateral: false,
                            bestFor: 'Lowest rate',
                          ),
                          isLocked: isLocked,
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
        ] else ...[
          RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              children: [
                const TextSpan(
                  text:
                      "We've partnered with leading banks to get you the best rates. ",
                ),
                const TextSpan(
                  text: "Compare offers and choose what works best for you.",
                  style: TextStyle(color: Color(0xFF6A1B9A)),
                ),
              ],
            ),
          ),
          if (!isLocked) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _showOffers = true;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A1B9A),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Check your offers",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _LenderCard extends StatelessWidget {
  final Color color;
  final LoanOffer offer;
  final bool isLocked;

  const _LenderCard({
    required this.color,
    required this.offer,
    this.isLocked = false,
  });

  String _getDomainForBank(String bankName) {
    final name = bankName.toLowerCase();
    if (name.contains('hdfc') || name.contains('credila')) return 'credila.com';
    if (name.contains('sbi') || name.contains('state bank')) return 'sbi.co.in';
    if (name.contains('icici')) return 'icicibank.com';
    if (name.contains('axis')) return 'axisbank.com';
    if (name.contains('avanse')) return 'avanse.com';
    if (name.contains('incred')) return 'incred.com';
    if (name.contains('auxilo')) return 'auxilo.com';
    if (name.contains('idfc')) return 'idfcfirstbank.com';
    if (name.contains('bob') || name.contains('baroda')) return 'bankofbaroda.in';
    if (name.contains('pnb') || name.contains('punjab')) return 'pnbindia.in';
    return 'google.com';
  }

  Widget _getBankLogo(String bankName) {
    String? localAssetPath;
    String? networkLogoUrl;

    final name = bankName.toLowerCase();

    if (name.contains('hdfc') || name.contains('credila')) {
      localAssetPath = 'assets/images/credila_logo_final.png';
    } else if (name.contains('avanse')) {
      localAssetPath = 'assets/images/avanse_logo_final.png';
    } else if (name.contains('auxilo')) {
      localAssetPath = 'assets/images/auxilo_logo_final.png';
    } else if (name.contains('idfc')) {
      localAssetPath = 'assets/images/idfc_logo.png';
    } else if (name.contains('sbi') || name.contains('state bank')) {
      networkLogoUrl = 'https://upload.wikimedia.org/wikipedia/en/thumb/5/58/State_Bank_of_India_logo.svg/1280px-State_Bank_of_India_logo.svg.png';
    } else if (name.contains('icici')) {
      networkLogoUrl = 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/12/ICICI_Bank_Logo.svg/1280px-ICICI_Bank_Logo.svg.png';
    } else if (name.contains('axis')) {
      networkLogoUrl = 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/Axis_Bank_logo.svg/1280px-Axis_Bank_logo.svg.png';
    } else if (name.contains('incred')) {
      networkLogoUrl = 'https://incred.com/images/logo.png';
    } else if (name.contains('bob') || name.contains('baroda')) {
      networkLogoUrl = 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/be/Bank_of_Baroda_Logo.svg/1280px-Bank_of_Baroda_Logo.svg.png';
    } else if (name.contains('pnb') || name.contains('punjab')) {
      networkLogoUrl = 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/9f/Punjab_National_Bank.svg/500px-Punjab_National_Bank.svg.png';
    }

    Widget logoImage;
    if (localAssetPath != null) {
      logoImage = Image.asset(
        localAssetPath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          final domain = _getDomainForBank(bankName);
          return Image.network(
            'https://www.google.com/s2/favicons?domain=$domain&sz=128',
            fit: BoxFit.contain,
            errorBuilder: (context, error2, stackTrace2) => const Icon(
              Icons.account_balance,
              size: 14,
              color: Colors.grey,
            ),
          );
        },
      );
    } else if (networkLogoUrl != null) {
      logoImage = Image.network(
        networkLogoUrl,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          final domain = _getDomainForBank(bankName);
          return Image.network(
            'https://www.google.com/s2/favicons?domain=$domain&sz=128',
            fit: BoxFit.contain,
            errorBuilder: (context, error2, stackTrace2) => const Icon(
              Icons.account_balance,
              size: 14,
              color: Colors.grey,
            ),
          );
        },
      );
    } else {
      final domain = _getDomainForBank(bankName);
      logoImage = Image.network(
        'https://www.google.com/s2/favicons?domain=$domain&sz=128',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.account_balance,
          size: 14,
          color: Colors.grey,
        ),
      );
    }

    return Container(
      width: 28,
      height: 28,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).toInt()),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipOval(
        child: logoImage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double cardWidth = MediaQuery.of(context).size.width - 56;
    return Container(
      width: cardWidth,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    _getBankLogo(offer.bank),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        offer.bank,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isLocked)
                Row(
                  children: [
                    const Icon(Icons.lock, size: 14, color: Color(0xFF6A1B9A)),
                    const SizedBox(width: 4),
                    const Text(
                      "Locked",
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6A1B9A),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              else
                const Icon(Icons.arrow_forward_ios, size: 14),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            offer.name.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            offer.amount,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildMetric("INTEREST\nRATE", offer.rate)),
              const SizedBox(width: 8),
              Expanded(child: _buildMetric("PROCESSING\nTIME", offer.processingTime)),
              const SizedBox(width: 8),
              Expanded(child: _buildMetric("SAVINGS", offer.savings)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 7,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _EvaluationList extends StatelessWidget {
  final List<Map<String, String>> universities;
  final Function(int) onRemove;

  const _EvaluationList({required this.universities, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(universities.length, (index) {
        final uni = universities[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.purple.withAlpha((0.3 * 255).toInt()),
            ),
          ),
          child: Row(
            children: [
              Text(
                "${index + 1}.",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      uni['name'] ?? 'Unknown University',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      uni['course'] ?? 'Unknown Course',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.remove_circle_outline,
                  color: Colors.red,
                  size: 20,
                ),
                onPressed: () => onRemove(index),
              ),
            ],
          ),
        );
      }),
    );
  }
}
