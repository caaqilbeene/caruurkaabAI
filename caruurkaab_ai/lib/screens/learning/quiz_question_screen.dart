import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
  int _wrong = 0;
  int _earnedPoints = 0;

  bool _answered = false;
  int? _selectedOptionIndex;
  bool _showHint = false;
  bool _currentQuestionEvaluated = false;

  bool _isLoading = true;
  final List<_QuizQuestion> _questions = [];

  String? _quizId;
  int _quizPassingScorePercent = 60;

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

  String? _extractMissingQuizColumn(PostgrestException e) {
    final combined = '${e.message} ${e.details} ${e.hint}';
    final pgrstMatch = RegExp(
      r"Could not find the '([^']+)' column of 'quizzes'",
      caseSensitive: false,
    ).firstMatch(combined);
    if (pgrstMatch != null) {
      return pgrstMatch.group(1);
    }

    final pgMatch = RegExp(
      r'column\s+quizzes\.([a-zA-Z0-9_]+)\s+does not exist',
      caseSensitive: false,
    ).firstMatch(combined);
    return pgMatch?.group(1);
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

  Future<List<Map<String, dynamic>>> _fetchLatestQuizzes({
    String? subject,
    int? classLevel,
    String? lessonId,
    String? chapterId,
  }) async {
    final selectedColumns = <String>['id', 'questions', 'passing_score'];
    final removedColumns = <String>{};

    while (true) {
      try {
        var query = Supabase.instance.client
            .from('quizzes')
            .select(selectedColumns.join(','));

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

        final rows = await query
            .order('created_at', ascending: false)
            .limit(20);
        return rows.map((row) => Map<String, dynamic>.from(row)).toList();
      } on PostgrestException catch (e) {
        final missingColumn = _extractMissingQuizColumn(e);
        final canRecover =
            (e.code == 'PGRST204' || e.code == '42703') &&
            missingColumn != null &&
            selectedColumns.contains(missingColumn) &&
            !removedColumns.contains(missingColumn);
        if (!canRecover) rethrow;
        selectedColumns.remove(missingColumn);
        removedColumns.add(missingColumn);
      }
    }
  }

  bool _hasUsableQuestions(Map<String, dynamic> quiz) {
    final questions = quiz['questions'];
    if (questions is! List || questions.isEmpty) return false;

    for (final raw in questions) {
      if (raw is! Map) continue;
      final map = Map<String, dynamic>.from(raw);
      final questionText = map['question']?.toString().trim() ?? '';
      final optionsRaw = map['options'];
      final options = optionsRaw is List
          ? optionsRaw.map((o) => o.toString().trim()).toList()
          : <String>[];
      if (questionText.isNotEmpty && options.length >= 2) {
        return true;
      }
    }
    return false;
  }

  Future<Map<String, dynamic>?> _fetchFirstUsableQuiz({
    String? subject,
    int? classLevel,
    String? lessonId,
    String? chapterId,
  }) async {
    final rows = await _fetchLatestQuizzes(
      subject: subject,
      classLevel: classLevel,
      lessonId: lessonId,
      chapterId: chapterId,
    );
    for (final row in rows) {
      if (_hasUsableQuestions(row)) return row;
    }
    return null;
  }

  String _normalizeDifficulty(String value) {
    final lower = value.trim().toLowerCase();
    if (lower == 'easy' || lower == 'medium' || lower == 'hard') {
      return lower;
    }
    return 'medium';
  }

  int _defaultPointsForDifficulty(String difficulty) {
    return switch (_normalizeDifficulty(difficulty)) {
      'easy' => 10,
      'medium' => 15,
      'hard' => 20,
      _ => 15,
    };
  }

  Future<void> _loadQuestions() async {
    try {
      final subject = _normalizeSubject(widget.subjectName);
      final lessonId = widget.lessonId.trim();
      final chapterId = widget.chapterId?.trim();
      final hasChapterTarget = chapterId != null && chapterId.isNotEmpty;
      final hasLessonTarget = lessonId.isNotEmpty;

      Map<String, dynamic>? data;

      // First priority: lesson-specific quiz (mid cashar-gaar ah).
      if (hasLessonTarget) {
        data = await _fetchFirstUsableQuiz(
          subject: subject,
          classLevel: widget.classLevel,
          lessonId: lessonId,
        );
        data ??= await _fetchFirstUsableQuiz(
          classLevel: widget.classLevel,
          lessonId: lessonId,
        );
        data ??= await _fetchFirstUsableQuiz(lessonId: lessonId);
      }

      // Chapter-level fallback only when lesson id is not available.
      if (data == null && !hasLessonTarget && hasChapterTarget) {
        data = await _fetchFirstUsableQuiz(
          subject: subject,
          classLevel: widget.classLevel,
          chapterId: chapterId,
        );
        data ??= await _fetchFirstUsableQuiz(
          classLevel: widget.classLevel,
          chapterId: chapterId,
        );
        data ??= await _fetchFirstUsableQuiz(chapterId: chapterId);
      } else if (data == null && !hasLessonTarget) {
        data = await _fetchFirstUsableQuiz(
          subject: subject,
          classLevel: widget.classLevel,
        );
        data ??= await _fetchFirstUsableQuiz(subject: subject);
      }

      _quizId = data?['id']?.toString();
      _quizPassingScorePercent =
          int.tryParse(data?['passing_score']?.toString() ?? '') ?? 60;
      _quizPassingScorePercent = _quizPassingScorePercent.clamp(1, 100);

      final questions = data?['questions'];
      if (questions is List) {
        for (final raw in questions) {
          if (raw is! Map) continue;
          final map = Map<String, dynamic>.from(raw);

          final questionText = map['question']?.toString().trim() ?? '';
          final optionsRaw = map['options'];
          final options = optionsRaw is List
              ? optionsRaw.map((o) => o.toString().trim()).toList()
              : <String>[];
          final correctIndex = map['correctIndex'] is int
              ? map['correctIndex'] as int
              : int.tryParse(map['correctIndex']?.toString() ?? '') ?? 0;
          final imageUrl = map['imageUrl']?.toString().trim();
          final hint = map['hint']?.toString().trim() ?? '';
          final difficulty = _normalizeDifficulty(
            (map['difficulty'] ?? 'medium').toString(),
          );
          final type = (map['type'] ?? 'mcq').toString().trim();
          final points =
              int.tryParse(map['points']?.toString() ?? '') ??
              _defaultPointsForDifficulty(difficulty);

          if (questionText.isEmpty || options.length < 2) continue;

          _questions.add(
            _QuizQuestion(
              question: questionText,
              options: options.take(3).toList(),
              correctIndex: correctIndex.clamp(0, options.length - 1),
              imageUrl: imageUrl?.isEmpty ?? true ? null : imageUrl,
              hint: hint,
              difficulty: difficulty,
              type: type.isEmpty ? 'mcq' : type,
              points: points <= 0
                  ? _defaultPointsForDifficulty(difficulty)
                  : points,
            ),
          );
        }
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
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

  List<String> _resolveBadges({
    required int totalCorrect,
    required int totalPoints,
  }) {
    final badges = <String>[];
    if (totalCorrect >= 10) badges.add('Beginner');
    if (totalCorrect >= 30) badges.add('Smart Kid');
    final isMath = widget.subjectName.toLowerCase().contains('xisaab');
    if (isMath && totalCorrect >= 50) badges.add('Math Master');
    if (!isMath && totalPoints >= 800) badges.add('Math Master');
    return badges;
  }

  Future<_AdvancedProgressResult> _persistAdvancedProgress() async {
    final db = Supabase.instance.client;
    final userId = _getUserId();
    final lessonId = widget.lessonId.trim();
    final now = DateTime.now().toUtc();
    final today = now.toIso8601String().substring(0, 10);

    int totalCorrect = _score;
    int totalPoints = _earnedPoints;

    try {
      final rows = await db
          .from('student_quiz_progress')
          .select('correct_count,total_points')
          .eq('user_id', userId);
      for (final row in rows) {
        final map = Map<String, dynamic>.from(row);
        totalCorrect +=
            int.tryParse(map['correct_count']?.toString() ?? '') ?? 0;
        totalPoints += int.tryParse(map['total_points']?.toString() ?? '') ?? 0;
      }
    } catch (_) {
      // Ignore aggregate read failure.
    }

    final badges = _resolveBadges(
      totalCorrect: totalCorrect,
      totalPoints: totalPoints,
    );

    try {
      await db.from('student_quiz_progress').upsert({
        'user_id': userId,
        'lesson_id': lessonId,
        'quiz_id': _quizId,
        'correct_count': _score,
        'wrong_count': _wrong,
        'level': 1,
        'total_points': _earnedPoints,
        'badges': badges,
        'attempt_date': today,
      }, onConflict: 'user_id,lesson_id,attempt_date');
    } catch (_) {
      // Ignore progress write failure.
    }

    bool dailyRewardUnlocked = false;
    try {
      final target = 5;
      final answeredThisQuiz = min(target, _questions.length);
      final correctThisQuiz = min(target, _score);

      final existing = await db
          .from('student_daily_challenges')
          .select(
            'answered_questions,correct_questions,completed,points_earned,reward_claimed',
          )
          .eq('user_id', userId)
          .eq('challenge_date', today)
          .maybeSingle();

      final prevAnswered = existing == null
          ? 0
          : int.tryParse(existing['answered_questions']?.toString() ?? '') ?? 0;
      final prevCorrect = existing == null
          ? 0
          : int.tryParse(existing['correct_questions']?.toString() ?? '') ?? 0;
      final prevPoints = existing == null
          ? 0
          : int.tryParse(existing['points_earned']?.toString() ?? '') ?? 0;
      final wasCompleted = existing != null && existing['completed'] == true;
      final wasRewardClaimed =
          existing != null && existing['reward_claimed'] == true;

      final nextAnswered = min(target, prevAnswered + answeredThisQuiz);
      final nextCorrect = min(target, prevCorrect + correctThisQuiz);
      final nowCompleted = nextAnswered >= target;
      dailyRewardUnlocked = nowCompleted && !wasCompleted;

      await db.from('student_daily_challenges').upsert({
        'user_id': userId,
        'challenge_date': today,
        'target_questions': target,
        'answered_questions': nextAnswered,
        'correct_questions': nextCorrect,
        'completed': nowCompleted,
        'points_earned': prevPoints + _earnedPoints,
        'reward_claimed': wasRewardClaimed || dailyRewardUnlocked,
      }, onConflict: 'user_id,challenge_date');

      if (dailyRewardUnlocked) {
        await db.from('student_notifications').insert({
          'user_id': userId,
          'title': 'Daily Challenge Completed',
          'body': '🎁 Maanta challenge-ka waad dhamaysay!',
          'kind': 'daily_challenge',
          'is_read': false,
        });
      }
    } catch (_) {
      // Ignore daily challenge failure.
    }

    return _AdvancedProgressResult(
      badges: badges,
      dailyRewardUnlocked: dailyRewardUnlocked,
    );
  }

  void _onOptionSelected(int index) {
    if (_answered) return;
    setState(() {
      _selectedOptionIndex = index;
      _answered = true;
    });
  }

  Future<void> _submitAnswer() async {
    if (!_answered) return;

    final currentQ = _questions[_currentQuestionIndex];
    if (!_currentQuestionEvaluated) {
      final isCorrect = _selectedOptionIndex == currentQ.correctIndex;
      if (isCorrect) {
        _score++;
        _earnedPoints += currentQ.points;
      } else {
        _wrong++;
      }
      _currentQuestionEvaluated = true;
    }

    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _answered = false;
        _selectedOptionIndex = null;
        _showHint = false;
        _currentQuestionEvaluated = false;
      });
      return;
    }

    final requiredCorrect =
        (_questions.length * (_quizPassingScorePercent / 100)).ceil();
    final isPass = _score >= requiredCorrect;
    if (isPass) {
      await _markLessonComplete();
    }
    final advanced = await _persistAdvancedProgress();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => QuizResultScreen(
          score: _score,
          total: _questions.length,
          wrong: _wrong,
          earnedPoints: _earnedPoints,
          badges: advanced.badges,
          dailyRewardUnlocked: advanced.dailyRewardUnlocked,
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
              "Casharkan wali quiz looma soo xareynin.",
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
                    if (currentQ.hint.trim().isNotEmpty) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _showHint
                              ? null
                              : () => setState(() => _showHint = true),
                          icon: const Icon(Icons.lightbulb_outline),
                          label: const Text('Show Hint'),
                        ),
                      ),
                      if (_showHint)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Text(
                            "Hint: ${currentQ.hint}",
                            style: const TextStyle(
                              color: Color(0xFF92400E),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
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
        final isSelected = _selectedOptionIndex == index;
        final isCorrect = index == q.correctIndex;

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
  final String hint;
  final String difficulty;
  final String type;
  final int points;

  const _QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    this.imageUrl,
    required this.hint,
    required this.difficulty,
    required this.type,
    required this.points,
  });
}

class _AdvancedProgressResult {
  final List<String> badges;
  final bool dailyRewardUnlocked;

  const _AdvancedProgressResult({
    required this.badges,
    required this.dailyRewardUnlocked,
  });
}
