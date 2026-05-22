import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/final_exam_service.dart';
import 'student_dashboard.dart';

class FinalExamQuestionScreen extends StatefulWidget {
  final FinalExamRecord exam;
  final bool returnToClassSubjectsOnFinish;

  const FinalExamQuestionScreen({
    super.key,
    required this.exam,
    this.returnToClassSubjectsOnFinish = false,
  });

  @override
  State<FinalExamQuestionScreen> createState() =>
      _FinalExamQuestionScreenState();
}

class _FinalExamQuestionScreenState extends State<FinalExamQuestionScreen> {
  static const int _questionTimeLimitSeconds = 45;

  late final List<FinalExamQuestion> _questions;

  int _currentIndex = 0;
  int _score = 0;
  int _wrong = 0;
  int _earnedPoints = 0;
  final List<Map<String, String>> _mistakes = [];

  int? _selectedOptionIndex;
  final TextEditingController _shortAnswerController = TextEditingController();

  int _secondsLeft = _questionTimeLimitSeconds;
  Timer? _timer;
  bool _isSubmitting = false;

  bool _finished = false;
  bool _pass = false;

  @override
  void initState() {
    super.initState();
    _questions = FinalExamService.buildRandomQuestionSet(widget.exam);
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shortAnswerController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsLeft = _questionTimeLimitSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        timer.cancel();
        _secondsLeft = 0;
        _submitCurrent(autoByTimer: true);
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });
  }

  String _normalize(String input) {
    return input
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[\.!?,;:]'), '');
  }

  bool _isAnswerCorrect(FinalExamQuestion q) {
    if (q.type == 'short_answer') {
      final typed = _normalize(_shortAnswerController.text);
      final expected = _normalize(q.correctAnswer);
      if (typed.isEmpty || expected.isEmpty) return false;
      return typed == expected;
    }

    final selected = _selectedOptionIndex;
    if (selected == null) return false;
    return selected == q.correctIndex;
  }

  Future<void> _submitCurrent({bool autoByTimer = false}) async {
    if (_isSubmitting || _finished) return;
    if (!autoByTimer) {
      final q = _questions[_currentIndex];
      if (q.type == 'short_answer') {
        if (_shortAnswerController.text.trim().isEmpty) return;
      } else {
        if (_selectedOptionIndex == null) return;
      }
    }

    _isSubmitting = true;
    _timer?.cancel();

    final q = _questions[_currentIndex];
    final correct = _isAnswerCorrect(q);
    if (correct) {
      _score += 1;
      _earnedPoints += 10;
    } else {
      _wrong += 1;
      
      String correctAns = q.type == 'short_answer' ? q.correctAnswer : 'Saxda kuma jirto options-ka';
      String yourAns = q.type == 'short_answer' 
          ? _shortAnswerController.text.trim() 
          : (_selectedOptionIndex == null ? 'Lama dooran' : q.options[_selectedOptionIndex!]);
          
      if (yourAns.isEmpty) yourAns = 'Lama qorin';

      if (q.options.isNotEmpty && q.type != 'short_answer' && q.correctIndex < q.options.length) {
          correctAns = q.options[q.correctIndex];
      }
      
      _mistakes.add({
        'question': q.question,
        'correct_answer': correctAns,
        'your_answer': yourAns,
      });
    }

    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex += 1;
        _selectedOptionIndex = null;
        _shortAnswerController.clear();
      });
      _startTimer();
      _isSubmitting = false;
      return;
    }

    final percent = (_score / _questions.length) * 100;
    final pass = percent >= widget.exam.passingScore;
    if (pass) {
      try {
        await FinalExamService.markExamPass(
          examId: widget.exam.id,
          score: _score,
          wrong: _wrong,
          totalPoints: _earnedPoints,
        );
      } catch (_) {
        // Keep UX smooth if save fails.
      }
    }

    if (!mounted) return;
    setState(() {
      _pass = pass;
      _finished = true;
      _isSubmitting = false;
    });
  }

  String _fillPrefix(String question) {
    if (question.contains('__')) {
      return question.split('__').first;
    }
    if (question.contains('_____')) {
      return question.split('_____').first;
    }
    return '$question ';
  }

  String _fillSuffix(String question) {
    if (question.contains('__')) {
      final parts = question.split('__');
      return parts.length > 1 ? parts.sublist(1).join('__') : '';
    }
    if (question.contains('_____')) {
      final parts = question.split('_____');
      return parts.length > 1 ? parts.sublist(1).join('_____') : '';
    }
    return '';
  }

  void _continueAfterResult() {
    if (widget.exam.isGrandFinal) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    if (widget.returnToClassSubjectsOnFinish) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => ClassSubjectsScreen(
            className: 'Fasalka ${widget.exam.classLevel}',
            maxUnlockedLevel: 4,
          ),
        ),
        (route) => route.isFirst,
      );
      return;
    }

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Imtixaan su’aalo kuma jiraan.')),
      );
    }

    if (_finished) {
      final percentage = ((_score / _questions.length) * 100).round();
      return Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: _pass
                        ? const Color(0xFFECFDF5)
                        : const Color(0xFFFEF2F2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _pass ? Icons.emoji_events : Icons.cancel,
                    size: 60,
                    color: _pass
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  _pass ? 'Waad Gudubtay Final Exam ✅' : 'Waad ku dhacday ❌',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _pass
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Sax: $_score / ${_questions.length}',
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Qalad: $_wrong',
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Boqolley: $percentage% (Pass ${widget.exam.passingScore}%)',
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                
                if (_mistakes.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text(
                    "Khaladaadkaagii (Your Mistakes):",
                    style: TextStyle(
                      color: Color(0xFFEF4444),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ..._mistakes.map((m) {
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m['question'] ?? '',
                            style: const TextStyle(
                              color: Color(0xFF111827),
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Adiga: ${m['your_answer']}",
                            style: const TextStyle(
                              color: Color(0xFFEF4444),
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Saxda: ${m['correct_answer']}",
                            style: const TextStyle(
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _continueAfterResult,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D5AFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Sii wad',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
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

    final q = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FA),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Final ${_currentIndex + 1} / ${_questions.length}',
          style: const TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFE5E7EB),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF1D5AFF),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$_secondsLeft s',
                        style: const TextStyle(
                          color: Color(0xFF1D4ED8),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _typeLabel(q.type),
                          style: const TextStyle(
                            color: Color(0xFF1D4ED8),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildQuestionView(q),
                      const SizedBox(height: 16),
                      _buildSafeNetworkImage(q.imageUrl),
                      _buildAnswerArea(q),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSubmitEnabled(q) && !_isSubmitting
                      ? () => _submitCurrent()
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D5AFF),
                    disabledBackgroundColor: const Color(0xFFD1D5DB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _currentIndex == _questions.length - 1
                        ? 'DHAMMEE IMTIXAANKA'
                        : 'SU’AASHA XIGTA',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'true_false':
        return 'True / False';
      case 'fill_blank':
        return 'Fill in the blank';
      case 'short_answer':
        return 'Qor jawaabta';
      default:
        return 'MCQ';
    }
  }

  bool _isSubmitEnabled(FinalExamQuestion q) {
    if (q.type == 'short_answer') {
      return _shortAnswerController.text.trim().isNotEmpty;
    }
    return _selectedOptionIndex != null;
  }

  Widget _buildQuestionView(FinalExamQuestion q) {
    if (q.type != 'fill_blank') {
      return Text(
        q.question,
        style: const TextStyle(
          color: Color(0xFF111827),
          fontSize: 24,
          fontWeight: FontWeight.w900,
          height: 1.3,
        ),
      );
    }

    final selected = _selectedOptionIndex == null
        ? '______'
        : q.options[_selectedOptionIndex!];
    final prefix = _fillPrefix(q.question);
    final suffix = _fillSuffix(q.question);

    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: Color(0xFF111827),
          fontSize: 24,
          fontWeight: FontWeight.w900,
          height: 1.3,
        ),
        children: [
          TextSpan(text: prefix),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _selectedOptionIndex == null
                    ? const Color(0xFFF3F4F6)
                    : const Color(0xFFDBEAFE),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _selectedOptionIndex == null
                      ? const Color(0xFFD1D5DB)
                      : const Color(0xFF3B82F6),
                ),
              ),
              child: Text(
                selected,
                style: TextStyle(
                  color: _selectedOptionIndex == null
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF1D4ED8),
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          TextSpan(text: suffix),
        ],
      ),
    );
  }

  Widget _buildAnswerArea(FinalExamQuestion q) {
    if (q.type == 'short_answer') {
      return TextField(
        controller: _shortAnswerController,
        maxLines: 2,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Qor jawaabtaada...',
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
        ),
      );
    }

    return Column(
      children: List.generate(q.options.length, (index) {
        final selected = _selectedOptionIndex == index;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              setState(() => _selectedOptionIndex = index);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFEFF6FF) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFFE5E7EB),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  if (q.type == 'true_false')
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? const Color(0xFF2563EB)
                              : const Color(0xFFCBD5E1),
                        ),
                        color: selected
                            ? const Color(0xFF2563EB)
                            : Colors.white,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      q.options[index],
                      style: TextStyle(
                        color: const Color(0xFF374151),
                        fontSize: 16,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSafeNetworkImage(String? url) {
    if (url == null || url.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          url.trim(),
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 200,
              color: const Color(0xFFF3F4F6),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.broken_image,
                    color: Color(0xFFEF4444),
                    size: 48,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Sawirka waa la waayay',
                    style: TextStyle(
                      color: Color(0xFF991B1B),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
