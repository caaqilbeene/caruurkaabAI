import 'dart:math';

import 'package:caruurkaab_ai/screens/learning/student_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/student_class_service.dart';

class PlacementFlowScreen extends StatefulWidget {
  const PlacementFlowScreen({super.key});

  @override
  State<PlacementFlowScreen> createState() => _PlacementFlowScreenState();
}

class _PlacementFlowScreenState extends State<PlacementFlowScreen> {
  static const int _placementQuestionCount = 50;

  final Random _random = Random();
  int _step = 0;
  int _questionIndex = 0;
  int _score = 0;

  int? _selectedOptionIndex;

  String _assignedClass = "";
  List<Map<String, dynamic>> _questions = [];
  bool _isLoadingQuestions = true;
  final Map<String, int> _subjectTotals = {};
  final Map<String, int> _subjectScores = {};

  @override
  void initState() {
    super.initState();
    _loadPlacementQuestions();
  }

  Future<void> _loadPlacementQuestions() async {
    try {
      final response = await Supabase.instance.client
          .from('placement_questions')
          .select();

      final dbQuestions = List<Map<String, dynamic>>.from(response);

      if (dbQuestions.isNotEmpty) {
        final mappedQuestions = dbQuestions.map((q) {
          final options = List<String>.from(q['options'] ?? []);
          return {
            "subject": q['subject'] ?? 'Aqoonta Guud',
            "type": q['type'] ?? 'mcq',
            "question": q['question'] ?? '',
            "options": options,
            "correctIndex": q['correct_index'] ?? 0,
            "image": q['image_url'],
            "promptEmoji": q['prompt_emoji'],
          };
        }).toList();

        mappedQuestions.shuffle(_random);

        if (mounted) {
          setState(() {
            _questions = mappedQuestions.take(_placementQuestionCount).toList();
            _isLoadingQuestions = false;
            _setupSubjectScores();
          });
        }
        return;
      }
    } catch (e) {
      debugPrint("Error loading placement questions from DB: $e");
    }

    if (mounted) {
      setState(() {
        _questions = [];
        _isLoadingQuestions = false;
        _setupSubjectScores();
      });
    }
  }

  void _setupSubjectScores() {
    _subjectTotals.clear();
    _subjectScores.clear();
    for (final question in _questions) {
      final subject = (question["subject"] as String?) ?? "Kale";
      _subjectTotals[subject] = (_subjectTotals[subject] ?? 0) + 1;
      _subjectScores.putIfAbsent(subject, () => 0);
    }
  }

  Map<String, dynamic> get _currentQuestion => _questions[_questionIndex];

  bool get _canContinue {
    return _selectedOptionIndex != null;
  }

  void _startTest() {
    setState(() {
      _step = 1;
    });
  }

  void _selectMcqOption(int index) {
    setState(() {
      _selectedOptionIndex = index;
    });
  }

  Future<void> _submitQuestion() async {
    if (!_canContinue) return;

    final subject = (_currentQuestion["subject"] as String?) ?? "Kale";
    final correct = _currentQuestion["correctIndex"] as int;
    final isCorrect = _selectedOptionIndex == correct;

    if (isCorrect) {
      _score += 1;
      _subjectScores[subject] = (_subjectScores[subject] ?? 0) + 1;
    }

    if (_questionIndex < _questions.length - 1) {
      setState(() {
        _questionIndex += 1;
        _selectedOptionIndex = null;
      });
      return;
    }

    _assignedClass = _calculateAssignedClass();
    await StudentClassService.saveAssignedClass(_assignedClass);
    setState(() {
      _step = 2;
    });
  }

  String _calculateAssignedClass() {
    final percent = (_score / _questions.length) * 100;
    if (percent < 35) return "Fasalka 1";
    if (percent < 60) return "Fasalka 2";
    if (percent < 80) return "Fasalka 3";
    return "Fasalka 4";
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingQuestions) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F8FA),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Color(0xFF1D5AFF)),
          ),
        ),
      );
    }
    if (_step == 0) return _buildPlacementChoice();
    if (_step == 1) return _buildPlacementTest();
    if (_step == 2) return _buildPlacementResult();
    return _buildAssignedClass();
  }

  Widget _buildPlacementChoice() {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Dooro Meesha Aad Ka Bilaabayso",
                      style: TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Dooro halkii aad ka bilaabi lahayd",
                      style: TextStyle(
                        color: Color(0xFF1D5AFF),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Aan kuu helno heerka kugu habboon.",
                      style: TextStyle(
                        color: Color(0xFF4B5563),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF4FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.quiz_rounded, color: Color(0xFF1D5AFF)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Imtixaanku waa ${_questions.length} su'aal oo (af-Soomaali).",
                              style: const TextStyle(
                                color: Color(0xFF1F2937),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_questions.isEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626)),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Ma jiraan su'aalo la soo galiyay hadda. Fadlan maamulaha kala xiriir si uu u soo geliyo su'aalaha.",
                                style: TextStyle(
                                  color: Color(0xFF991B1B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _questions.isEmpty ? null : _startTest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D5AFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    "Bilow Imtixaanka",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlacementTest() {
    final options = (_currentQuestion["options"] as List).cast<String>();
    final isImageQuestion =
        (_currentQuestion["promptEmoji"] as String?) != null;
    final isMathQuestion = (_currentQuestion["subject"] as String?) == "Xisaab";

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    "SU'AAL",
                    style: TextStyle(
                      color: Color(0xFF1D5AFF),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "${_questionIndex + 1} / ${_questions.length}",
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: (_questionIndex + 1) / _questions.length,
                minHeight: 10,
                borderRadius: BorderRadius.circular(99),
                backgroundColor: const Color(0xFFE5E7EB),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF1D5AFF)),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFD6E0FF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentQuestion["question"] as String,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if ((_currentQuestion["promptEmoji"] as String?) != null)
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F8F3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF86D59D)),
                        ),
                        child: Center(
                          child: Text(
                            _currentQuestion["promptEmoji"] as String,
                            style: const TextStyle(fontSize: 46),
                          ),
                        ),
                      ),
                    if ((_currentQuestion["image"] as String?) != null) ...[
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _currentQuestion["image"] as String,
                          height: 170,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (!isImageQuestion && !isMathQuestion)
                ...List.generate(options.length, (index) {
                  final isSelected = _selectedOptionIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: () => _selectMcqOption(index),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFEFF4FF)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF1D5AFF)
                                : const Color(0xFFD1D5DB),
                            width: 1.4,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                options[index],
                                style: TextStyle(
                                  color: isSelected
                                      ? const Color(0xFF1D5AFF)
                                      : const Color(0xFF111827),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: Color(0xFF1D5AFF),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                })
              else if (isMathQuestion)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final boxWidth = (constraints.maxWidth - 24) / 3;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: List.generate(options.length, (index) {
                        final isSelected = _selectedOptionIndex == index;
                        return InkWell(
                          onTap: () => _selectMcqOption(index),
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            width: boxWidth,
                            height: 90,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF1D4FFF)
                                  : const Color(0xFF2B8DEB),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Center(
                              child: Text(
                                options[index],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    );
                  },
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final boxWidth = (constraints.maxWidth - 12) / 2;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: List.generate(options.length, (index) {
                        final isSelected = _selectedOptionIndex == index;
                        return InkWell(
                          onTap: () => _selectMcqOption(index),
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            width: boxWidth,
                            height: 140,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFEFF4FF)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF1D5AFF)
                                    : const Color(0xFFD1D5DB),
                                width: 1.4,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: Text(
                                    options[index],
                                    style: const TextStyle(fontSize: 50),
                                  ),
                                ),
                                if (isSelected)
                                  const Positioned(
                                    right: 10,
                                    top: 10,
                                    child: Icon(
                                      Icons.check_circle,
                                      color: Color(0xFF1D5AFF),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _canContinue ? _submitQuestion : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D5AFF),
                    disabledBackgroundColor: const Color(0xFFA5B4FC),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _questionIndex == _questions.length - 1
                        ? "Xaqiiji / Confirm"
                        : "Sii wad / Next",
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlacementResult() {
    final percent = ((_score / _questions.length) * 100).round();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            children: [
              const SizedBox(height: 30),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFD6E0FF)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F7EE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.emoji_events,
                        color: Color(0xFF10B981),
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      "Hambalyo!",
                      style: TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Dhibcahaaga: $percent/100",
                      style: const TextStyle(
                        color: Color(0xFF374151),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Jawaabaha saxda ah: $_score/${_questions.length}",
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF4FF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        "Fasalka laguu qoondeeyay: $_assignedClass",
                        style: const TextStyle(
                          color: Color(0xFF1D5AFF),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        children: _subjectTotals.keys.map((subject) {
                          final total = _subjectTotals[subject] ?? 0;
                          final got = _subjectScores[subject] ?? 0;
                          final subjectPercent = total == 0
                              ? 0
                              : ((got / total) * 100).round();
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    subject,
                                    style: const TextStyle(
                                      color: Color(0xFF111827),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Text(
                                  "$got/$total ($subjectPercent%)",
                                  style: const TextStyle(
                                    color: Color(0xFF1D5AFF),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _step = 3;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D5AFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Sii wad / Next",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssignedClass() {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFD6E0FF)),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Heerkaaga waa",
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _assignedClass,
                      style: const TextStyle(
                        color: Color(0xFF1D5AFF),
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Ku bilow waxbarashada heerkan.",
                      style: TextStyle(
                        color: Color(0xFF4B5563),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StudentDashboardScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D5AFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Ku Bilow Waxbarashada",
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
