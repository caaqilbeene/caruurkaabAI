import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/student_profile_service.dart';
import 'quiz_result_screen.dart';

class QuizQuestionScreen extends StatefulWidget {
  final String lessonTitle;
  final String subjectName;
  final int classLevel;
  final String? chapterId;
  final String lessonId;
  final String? nextLessonId;
  final String? nextLessonTitle;
  final String? nextLessonChapterId;

  const QuizQuestionScreen({
    super.key,
    required this.lessonTitle,
    required this.subjectName,
    required this.classLevel,
    this.chapterId,
    required this.lessonId,
    this.nextLessonId,
    this.nextLessonTitle,
    this.nextLessonChapterId,
  });

  @override
  State<QuizQuestionScreen> createState() => _QuizQuestionScreenState();
}

class _QuizQuestionScreenState extends State<QuizQuestionScreen> {
  int _currentQuestionIndex = 0;
  int _score = 0;

  bool _answered = false;
  int? _selectedOptionIndex;

  bool _isLoading = true;
  String? _loadError;
  final List<_QuizQuestion> _questions = [];

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  String _normalizeSubject(String subject) {
    final s = subject.trim().toLowerCase();
    final compact = s.replaceAll(RegExp(r'[\s\-_]'), '');
    if (compact == 'afsomali' ||
        compact == 'afsoomaali' ||
        compact == 'afsoomaaliga') {
      return 'Af Soomaali';
    }
    if (compact == 'seynis' || compact == 'saynis') {
      return 'Saynis';
    }
    return subject;
  }

  dynamic _parseIdValue(String value) {
    final cleaned = value.trim();
    return int.tryParse(cleaned) ?? cleaned;
  }

  Future<Map<String, dynamic>?> _fetchLatestQuiz({
    String? subject,
    int? classLevel,
    String? lessonId,
    String? chapterId,
  }) async {
    var query = Supabase.instance.client.from('quizzes').select('questions');

    if (subject != null && subject.trim().isNotEmpty) {
      query = query.eq('subject_name', subject.trim());
    }
    if (classLevel != null) {
      query = query.eq('class_level', classLevel);
    }
    if (lessonId != null && lessonId.trim().isNotEmpty) {
      query = query.eq('lesson_id', _parseIdValue(lessonId));
    }
    if (chapterId != null && chapterId.trim().isNotEmpty) {
      query = query.eq('chapter_id', _parseIdValue(chapterId));
    }

    return query.order('created_at', ascending: false).limit(1).maybeSingle();
  }

  Future<void> _loadQuestions() async {
    try {
      final subject = _normalizeSubject(widget.subjectName);
      final lessonId = widget.lessonId.trim();
      final chapterId = widget.chapterId?.trim();
      final hasExactTarget =
          lessonId.isNotEmpty || (chapterId != null && chapterId.isNotEmpty);

      Map<String, dynamic>? data;

      // 1) Strict match (subject + class + lesson/chapter).
      if (lessonId.isNotEmpty) {
        data = await _fetchLatestQuiz(
          subject: subject,
          classLevel: widget.classLevel,
          lessonId: lessonId,
        );
      } else if (chapterId != null && chapterId.isNotEmpty) {
        data = await _fetchLatestQuiz(
          subject: subject,
          classLevel: widget.classLevel,
          chapterId: chapterId,
        );
      }

      // 2) Fallbacks si looga gudbo subject naming mismatch (Af Soomaali variants).
      if (data == null && lessonId.isNotEmpty) {
        data = await _fetchLatestQuiz(
          classLevel: widget.classLevel,
          lessonId: lessonId,
        );
      }
      if (data == null && lessonId.isNotEmpty) {
        data = await _fetchLatestQuiz(lessonId: lessonId);
      }

      if (data == null && chapterId != null && chapterId.isNotEmpty) {
        data = await _fetchLatestQuiz(
          classLevel: widget.classLevel,
          chapterId: chapterId,
        );
      }
      if (data == null && chapterId != null && chapterId.isNotEmpty) {
        data = await _fetchLatestQuiz(chapterId: chapterId);
      }

      // 3) Last fallback kaliya marka lesson/chapter target la waayo.
      // Tani waxay ka hortageysaa in quiz kale (cutub kale) uu kusoo noqnoqdo.
      if (!hasExactTarget) {
        data ??= await _fetchLatestQuiz(
          subject: subject,
          classLevel: widget.classLevel,
        );
      }

      final questions = data?['questions'];
      if (questions is List) {
        for (final raw in questions) {
          if (raw is! Map) continue;
          final questionText = raw['question']?.toString().trim() ?? '';
          final optionsRaw = raw['options'];
          final options = optionsRaw is List
              ? optionsRaw.map((o) => o.toString()).toList()
              : <String>[];
          final correctIndex = raw['correctIndex'] is int
              ? raw['correctIndex'] as int
              : int.tryParse(raw['correctIndex']?.toString() ?? '') ?? 0;
          final imageUrl = raw['imageUrl']?.toString().trim();

          if (questionText.isEmpty || options.isEmpty) continue;

          _questions.add(
            _QuizQuestion(
              question: questionText,
              options: options,
              correctIndex: correctIndex.clamp(0, options.length - 1),
              imageUrl: imageUrl?.isEmpty ?? true ? null : imageUrl,
            ),
          );
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = e.toString();
      });
    }
  }

  void _submitAnswer() {
    if (!_answered) return;

    final currentQ = _questions[_currentQuestionIndex];
    if (_selectedOptionIndex == currentQ.correctIndex) {
      _score++;
    }

    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _answered = false;
        _selectedOptionIndex = null;
      });
    } else {
      final isPass = _score >= (_questions.length * 0.6).ceil();
      if (isPass) {
        _markLessonComplete();
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => QuizResultScreen(
            score: _score,
            total: _questions.length,
            lessonTitle: widget.lessonTitle,
            subjectName: widget.subjectName,
            classLevel: widget.classLevel,
            chapterId: widget.chapterId,
            lessonId: widget.lessonId,
            nextLessonId: widget.nextLessonId,
            nextLessonTitle: widget.nextLessonTitle,
            nextLessonChapterId: widget.nextLessonChapterId,
          ),
        ),
      );
    }
  }

  String _getUserId() {
    final key = StudentProfileService.currentUserKey();
    if (key != null && key.isNotEmpty) return key;

    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email?.trim().toLowerCase();
    if (email != null && email.isNotEmpty) {
      return email;
    }
    final uid = user?.uid;
    if (uid != null && uid.isNotEmpty) return uid;
    return 'guest';
  }

  Future<void> _markLessonComplete() async {
    try {
      final userId = _getUserId();
      final lessonId = widget.lessonId.trim();
      if (lessonId.isEmpty) return;
      await Supabase.instance.client.from('lesson_progress').upsert({
        'user_id': userId,
        'lesson_id': int.tryParse(lessonId) ?? lessonId,
        'completed': true,
        'completed_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id,lesson_id');
    } catch (_) {
      // Ignore progress write errors.
    }
  }

  void _onOptionSelected(int index) {
    if (_answered) return;
    setState(() {
      _selectedOptionIndex = index;
      _answered = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F8FA),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF7F8FA),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF111827)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _loadError != null
                  ? "Quiz lama helin. Fadlan ku dar Su’aalo admin-ka.\n\n$_loadError"
                  : "Quiz lama helin. Fadlan ku dar Su’aalo admin-ka.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
        ),
      );
    }

    final currentQ = _questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _questions.length;

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
          "Su'aasha ${_currentQuestionIndex + 1} / ${_questions.length}",
          style: const TextStyle(
            color: Color(0xFF111827),
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFEEF2FF),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF1D5AFF),
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      currentQ.question,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111827),
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    if (currentQ.imageUrl != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            currentQ.imageUrl!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    _buildOptionsList(currentQ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: InkWell(
                onTap: _answered ? _submitAnswer : null,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: _answered
                        ? const Color(0xFF1D5AFF)
                        : const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: _answered
                        ? [
                            BoxShadow(
                              color: const Color(
                                0xFF1D5AFF,
                              ).withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ]
                        : [],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _currentQuestionIndex == _questions.length - 1
                        ? "DHAMMEE (FINISH)"
                        : "XIGTA (NEXT)",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
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

  Widget _buildOptionsList(_QuizQuestion q) {
    return Column(
      children: List.generate(q.options.length, (index) {
        bool isSelected = _selectedOptionIndex == index;
        bool isCorrect = index == q.correctIndex;

        Color bgColor = Colors.white;
        Color borderColor = const Color(0xFFE5E7EB);
        Color textColor = const Color(0xFF4B5563);
        Widget trailing = const SizedBox.shrink();

        if (_answered) {
          if (isCorrect) {
            bgColor = const Color(0xFFD1FAE5);
            borderColor = const Color(0xFF10B981);
            textColor = const Color(0xFF065F46);
            trailing = const Icon(Icons.check_circle, color: Color(0xFF10B981));
          } else if (isSelected && !isCorrect) {
            bgColor = const Color(0xFFFEE2E2);
            borderColor = const Color(0xFFEF4444);
            textColor = const Color(0xFF991B1B);
            trailing = const Icon(Icons.cancel, color: Color(0xFFEF4444));
          }
        } else if (isSelected) {
          bgColor = const Color(0xFFEFF6FF);
          borderColor = const Color(0xFF3B82F6);
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () => _onOptionSelected(index),
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 2),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      q.options[index],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ),
                  trailing,
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String? imageUrl;

  const _QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    this.imageUrl,
  });
}
