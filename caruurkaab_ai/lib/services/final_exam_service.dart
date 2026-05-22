import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'student_profile_service.dart';

class SubjectScoreData {
  final double chapterScoreOutOf40;
  final double finalScoreOutOf60;
  final double totalScore;
  final bool hasTakenFinal;

  SubjectScoreData({
    required this.chapterScoreOutOf40,
    required this.finalScoreOutOf60,
    required this.totalScore,
    required this.hasTakenFinal,
  });

  bool get isPassed => totalScore >= 50;
}


class FinalExamQuestion {
  final String type;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String correctAnswer;
  final String? imageUrl;

  const FinalExamQuestion({
    required this.type,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.correctAnswer,
    this.imageUrl,
  });
}

class FinalExamRecord {
  final String id;
  final String title;
  final String description;
  final String subjectName;
  final int classLevel;
  final String examType;
  final int passingScore;
  final int questionsToAnswer;
  final String noticeText;
  final int durationMinutes;
  final bool isActive;
  final List<FinalExamQuestion> questions;

  const FinalExamRecord({
    required this.id,
    required this.title,
    required this.description,
    required this.subjectName,
    required this.classLevel,
    required this.examType,
    required this.passingScore,
    required this.questionsToAnswer,
    required this.noticeText,
    required this.durationMinutes,
    required this.isActive,
    required this.questions,
  });

  bool get isGrandFinal => examType == 'grand_final';
  bool get isClassFinal => examType == 'final_class';
}

class FinalExamService {
  static const String _chapterQuizPassPrefix = 'chapter_pass:';
  static const String _examPassPrefix = 'exam_pass:';

  static bool isMissingExamsTableError(Object error) {
    if (error is! PostgrestException) return false;
    final code = (error.code ?? '').toString().trim();
    final combined = '${error.message} ${error.details} ${error.hint}'
        .toLowerCase();
    if (code == 'PGRST205' || code == '42P01') {
      return combined.contains('exams');
    }
    return combined.contains("table 'public.exams'") ||
        combined.contains('relation "exams" does not exist');
  }

  static bool isMissingStudentQuizProgressTableError(Object error) {
    if (error is! PostgrestException) return false;
    final code = (error.code ?? '').toString().trim();
    final combined = '${error.message} ${error.details} ${error.hint}'
        .toLowerCase();
    if (code == 'PGRST205' || code == '42P01') {
      return combined.contains('student_quiz_progress');
    }
    return combined.contains("table 'public.student_quiz_progress'") ||
        combined.contains('relation "student_quiz_progress" does not exist');
  }

  static List<String> _userKeys() {
    final keys = StudentProfileService.currentUserKeys();
    if (keys.isNotEmpty) return keys;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const [];
    final fallback = <String>[];
    final email = user.email?.trim().toLowerCase();
    if (email != null && email.isNotEmpty) fallback.add(email);
    final uid = user.uid.trim();
    if (uid.isNotEmpty && !fallback.contains(uid)) fallback.add(uid);
    return fallback;
  }

  static String _normalizeSubject(String subject) {
    final s = subject.trim().toLowerCase();
    final compact = s.replaceAll(RegExp(r'[\s\-_]'), '');
    if (compact == 'afsomali' ||
        compact == 'afsoomaali' ||
        compact == 'afsoomaaliga') {
      return 'Af Soomaali';
    }
    if (compact == 'saynis' || compact == 'seynis') {
      return 'Saynis';
    }
    if (compact == 'english') {
      return 'English';
    }
    if (compact == 'xisaab' || compact == 'math') {
      return 'Xisaab';
    }
    return subject.trim();
  }

  static String _normalizeExamType(String raw, {required String title}) {
    final v = raw.trim().toLowerCase();
    if (v == 'final_class' || v == 'grand_final') return v;
    final t = title.toLowerCase();
    if (t.contains('grand final')) return 'grand_final';
    return 'final_class';
  }

  static String? _extractMissingExamColumn(PostgrestException e) {
    final combined = '${e.message} ${e.details} ${e.hint}';
    final pgrst = RegExp(
      r"Could not find the '([^']+)' column of 'exams'",
      caseSensitive: false,
    ).firstMatch(combined);
    if (pgrst != null) return pgrst.group(1);

    final pg = RegExp(
      r'column\s+exams\.([a-zA-Z0-9_]+)\s+does not exist',
      caseSensitive: false,
    ).firstMatch(combined);
    return pg?.group(1);
  }

  static Future<List<Map<String, dynamic>>> _fetchExamRows({
    String? subject,
    int? classLevel,
    String? examType,
  }) async {
    final selected = <String>[
      'id',
      'title',
      'desc',
      'subject_name',
      'class_level',
      'questions',
      'passing_score',
      'duration_minutes',
      'total_questions',
      'exam_type',
      'notice_text',
      'questions_to_answer',
      'is_active',
      'created_at',
    ];
    final removed = <String>{};

    while (true) {
      try {
        var query = Supabase.instance.client
            .from('exams')
            .select(selected.join(','));
        if (subject != null && subject.trim().isNotEmpty) {
          query = query.eq('subject_name', _normalizeSubject(subject));
        }
        if (classLevel != null) {
          query = query.eq('class_level', classLevel);
        }
        if (examType != null && examType.trim().isNotEmpty) {
          query = query.eq('exam_type', examType.trim());
        }

        final rows = await query.order('created_at', ascending: false);
        return rows.map((e) => Map<String, dynamic>.from(e)).toList();
      } on PostgrestException catch (e) {
        if (isMissingExamsTableError(e)) {
          return const [];
        }
        final missing = _extractMissingExamColumn(e);
        final canRecover =
            (e.code == 'PGRST204' || e.code == '42703') &&
            missing != null &&
            selected.contains(missing) &&
            !removed.contains(missing);
        if (!canRecover) rethrow;
        selected.remove(missing);
        removed.add(missing);
      }
    }
  }

  static FinalExamRecord? _toRecord(Map<String, dynamic> row) {
    final id = (row['id'] ?? '').toString().trim();
    if (id.isEmpty) return null;

    final title = (row['title'] ?? 'Final Exam').toString().trim();
    final desc = (row['desc'] ?? '').toString().trim();
    final subject = _normalizeSubject((row['subject_name'] ?? '').toString());
    final classLevel =
        int.tryParse((row['class_level'] ?? '0').toString()) ?? 0;
    final examType = _normalizeExamType(
      (row['exam_type'] ?? '').toString(),
      title: title,
    );
    final passingScore =
        int.tryParse((row['passing_score'] ?? '60').toString()) ?? 60;
    final totalQuestions =
        int.tryParse((row['total_questions'] ?? '10').toString()) ?? 10;
    final questionsToAnswer =
        int.tryParse((row['questions_to_answer'] ?? '').toString()) ??
        max(1, min(10, totalQuestions));
    final durationMinutes =
        int.tryParse((row['duration_minutes'] ?? '0').toString()) ?? 0;
    final noticeText =
        (row['notice_text'] ?? 'Imtixaan final ayaa diyaar kuu ah.').toString();
    final isActive = row['is_active'] == null ? true : row['is_active'] == true;

    final parsedQuestions = <FinalExamQuestion>[];
    final rawQuestions = row['questions'];
    if (rawQuestions is List) {
      for (final raw in rawQuestions) {
        if (raw is! Map) continue;
        final map = Map<String, dynamic>.from(raw);
        final type = (map['type'] ?? 'mcq').toString().trim().toLowerCase();
        final question = (map['question'] ?? '').toString().trim();
        final imageUrl = map['imageUrl']?.toString().trim() ?? map['image_url']?.toString().trim();
        final optionsRaw = map['options'];
        final options = optionsRaw is List
            ? optionsRaw
                  .map((o) => o.toString().trim())
                  .where((o) => o.isNotEmpty)
                  .toList()
            : <String>[];
        final correctIndex = map['correctIndex'] is int
            ? map['correctIndex'] as int
            : int.tryParse((map['correctIndex'] ?? '0').toString()) ?? 0;
        final correctAnswer = (map['correctAnswer'] ?? '').toString().trim();

        if (question.isEmpty) continue;

        final safeImage = imageUrl != null && imageUrl.isNotEmpty ? imageUrl : null;

        if (type == 'mcq' || type == 'true_false' || type == 'fill_blank') {
          if (options.length < 2) continue;
          final safeCorrect = correctIndex.clamp(0, options.length - 1);
          parsedQuestions.add(
            FinalExamQuestion(
              type: type,
              question: question,
              options: options,
              correctIndex: safeCorrect,
              correctAnswer: options[safeCorrect],
              imageUrl: safeImage,
            ),
          );
        } else {
          final answer = correctAnswer.isNotEmpty
              ? correctAnswer
              : (options.isNotEmpty ? options.first : '');
          if (answer.isEmpty) continue;
          parsedQuestions.add(
            FinalExamQuestion(
              type: 'short_answer',
              question: question,
              options: const [],
              correctIndex: 0,
              correctAnswer: answer,
              imageUrl: safeImage,
            ),
          );
        }
      }
    }

    if (parsedQuestions.isEmpty) return null;

    return FinalExamRecord(
      id: id,
      title: title,
      description: desc,
      subjectName: subject,
      classLevel: classLevel,
      examType: examType,
      passingScore: passingScore.clamp(1, 100),
      questionsToAnswer: max(1, questionsToAnswer),
      noticeText: noticeText,
      durationMinutes: max(0, durationMinutes),
      isActive: isActive,
      questions: parsedQuestions,
    );
  }

  static Future<FinalExamRecord?> fetchClassFinalExam({
    required String subject,
    required int classLevel,
  }) async {
    final rows = await _fetchExamRows(subject: subject, classLevel: classLevel);
    for (final row in rows) {
      final record = _toRecord(row);
      if (record == null || !record.isActive) continue;
      if (record.isClassFinal &&
          record.classLevel == classLevel &&
          _normalizeSubject(record.subjectName) == _normalizeSubject(subject)) {
        return record;
      }
    }
    return null;
  }

  static Future<List<FinalExamRecord>> fetchAllActiveClassFinalExams() async {
    try {
      final rows = await _fetchExamRows(examType: 'final_class');
      final records = <FinalExamRecord>[];
      for (final row in rows) {
        final rec = _toRecord(row);
        if (rec != null && rec.isActive) {
          records.add(rec);
        }
      }
      return records;
    } catch (_) {
      return [];
    }
  }

  static Future<FinalExamRecord?> fetchGrandFinalExam() async {
    final rows = await _fetchExamRows();
    for (final row in rows) {
      final record = _toRecord(row);
      if (record == null || !record.isActive) continue;
      if (record.isGrandFinal) return record;
    }
    return null;
  }

  static Future<Set<String>> _loadCompletedLessonIds(
    List<String> userKeys,
  ) async {
    if (userKeys.isEmpty) return <String>{};
    final query = Supabase.instance.client
        .from('lesson_progress')
        .select('lesson_id, completed');
    final rows = userKeys.length == 1
        ? await query.eq('user_id', userKeys.first)
        : await query.inFilter('user_id', userKeys);
    return {
      for (final row in rows)
        if (row['completed'] == true) row['lesson_id'].toString(),
    };
  }

  static Future<Set<String>> _loadPassedChapterIds(
    List<String> userKeys,
  ) async {
    if (userKeys.isEmpty) return <String>{};
    final rows = await (() async {
      try {
        return await Supabase.instance.client
            .from('student_quiz_progress')
            .select('lesson_id')
            .inFilter('user_id', userKeys)
            .like('lesson_id', '$_chapterQuizPassPrefix%');
      } catch (e) {
        if (isMissingStudentQuizProgressTableError(e)) {
          return <Map<String, dynamic>>[];
        }
        rethrow;
      }
    })();

    final ids = <String>{};
    for (final row in rows) {
      final key = (row['lesson_id'] ?? '').toString();
      if (!key.startsWith(_chapterQuizPassPrefix)) continue;
      final chapterId = key.substring(_chapterQuizPassPrefix.length).trim();
      if (chapterId.isNotEmpty) ids.add(chapterId);
    }
    return ids;
  }

  static Future<Set<String>> _loadChapterIdsThatHaveQuiz({
    required String subject,
    required int classLevel,
  }) async {
    try {
      final rows = await Supabase.instance.client
          .from('quizzes')
          .select('chapter_id')
          .eq('subject_name', _normalizeSubject(subject))
          .eq('class_level', classLevel);

      final chapterIds = <String>{};
      for (final row in rows) {
        final chapterId = (row['chapter_id'] ?? '').toString().trim();
        if (chapterId.isNotEmpty) {
          chapterIds.add(chapterId);
        }
      }
      return chapterIds;
    } catch (_) {
      // If quiz table check fails, keep old strict behavior.
      return const <String>{};
    }
  }

  static String _localChapterPassKey({
    required String userId,
    required int classLevel,
    required String subjectName,
    required String chapterId,
  }) {
    final subject = _normalizeSubject(subjectName).trim().toLowerCase();
    return 'chapter_quiz_pass:$userId:$classLevel:$subject:$chapterId';
  }

  static Future<Set<String>> _loadPassedChapterIdsFromLocalCache({
    required List<String> userKeys,
    required List<String> chapterIds,
    required String subjectName,
    required int classLevel,
  }) async {
    if (chapterIds.isEmpty) return <String>{};
    final prefs = await SharedPreferences.getInstance();

    final keysToCheck = <String>{...userKeys};
    final firstKey = StudentProfileService.currentUserKey();
    if (firstKey != null && firstKey.isNotEmpty) {
      keysToCheck.add(firstKey);
    }
    if (keysToCheck.isEmpty) return <String>{};

    final passed = <String>{};
    for (final chapterId in chapterIds) {
      if (chapterId.trim().isEmpty) continue;
      for (final userId in keysToCheck) {
        final key = _localChapterPassKey(
          userId: userId,
          classLevel: classLevel,
          subjectName: subjectName,
          chapterId: chapterId,
        );
        if (prefs.getBool(key) == true) {
          passed.add(chapterId);
          break;
        }
      }
    }
    return passed;
  }

  static Future<bool> isEligibleForClassFinal({
    required String subject,
    required int classLevel,
  }) async {
    final normalizedSubject = _normalizeSubject(subject);

    final chaptersRows = await Supabase.instance.client
        .from('chapters')
        .select('id,course_order')
        .eq('subject_name', normalizedSubject)
        .eq('class_level', classLevel)
        .order('course_order', ascending: true);

    final lessonsRows = await Supabase.instance.client
        .from('lessons')
        .select('id,chapter_id')
        .eq('subject_name', normalizedSubject)
        .eq('class_level', classLevel)
        .order('created_at', ascending: true);

    final chapters = chaptersRows
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final lessons = lessonsRows
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    if (chapters.isEmpty || lessons.isEmpty) return false;

    final userKeys = _userKeys();
    final completedLessons = await _loadCompletedLessonIds(userKeys);
    final passedChapters = await _loadPassedChapterIds(userKeys);
    final chaptersWithQuiz = await _loadChapterIdsThatHaveQuiz(
      subject: normalizedSubject,
      classLevel: classLevel,
    );
    final chapterIds = chapters
        .map((c) => c['id']?.toString().trim() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
    try {
      final localPassed = await _loadPassedChapterIdsFromLocalCache(
        userKeys: userKeys,
        chapterIds: chapterIds,
        subjectName: normalizedSubject,
        classLevel: classLevel,
      );
      passedChapters.addAll(localPassed);
    } catch (_) {
      // Local cache read failure should not block final exam checks.
    }

    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final ch in chapters) {
      grouped[ch['id'].toString()] = [];
    }
    for (final l in lessons) {
      final chapterId = l['chapter_id']?.toString();
      if (chapterId != null && grouped.containsKey(chapterId)) {
        grouped[chapterId]!.add(l);
      }
    }

    for (final ch in chapters) {
      final chapterId = ch['id']?.toString() ?? '';
      if (chapterId.isEmpty) continue;
      final chapterLessons = grouped[chapterId] ?? const [];
      if (chapterLessons.isEmpty) {
        // Ignore empty chapters so legacy/placeholder rows don't block finals.
        continue;
      }

      for (final lesson in chapterLessons) {
        final lessonId = lesson['id']?.toString() ?? '';
        if (lessonId.isEmpty) continue;
        if (!completedLessons.contains(lessonId)) return false;
      }

      final hasChapterQuiz = chaptersWithQuiz.contains(chapterId);
      if (hasChapterQuiz && !passedChapters.contains(chapterId)) return false;
    }

    return true;
  }

  static Future<bool> isEligibleForGrandFinal() async {
    // Grand final: require all available class-final exams to be passed.
    final userKeys = _userKeys();
    if (userKeys.isEmpty) return false;

    final allRows = await _fetchExamRows();
    final finals = allRows
        .map(_toRecord)
        .whereType<FinalExamRecord>()
        .where((e) => e.isActive && e.isClassFinal)
        .toList();

    if (finals.isEmpty) return false;

    final progressRows = await (() async {
      try {
        return await Supabase.instance.client
            .from('student_quiz_progress')
            .select('lesson_id')
            .inFilter('user_id', userKeys)
            .like('lesson_id', '$_examPassPrefix%');
      } catch (e) {
        if (isMissingStudentQuizProgressTableError(e)) {
          return <Map<String, dynamic>>[];
        }
        rethrow;
      }
    })();

    final passedExamIds = <String>{};
    for (final row in progressRows) {
      final key = (row['lesson_id'] ?? '').toString();
      if (!key.startsWith(_examPassPrefix)) continue;
      final examId = key.substring(_examPassPrefix.length).trim();
      if (examId.isNotEmpty) passedExamIds.add(examId);
    }

    for (final exam in finals) {
      if (!passedExamIds.contains(exam.id)) return false;
    }
    return true;
  }

  static Future<void> markExamPass({
    required String examId,
    required int score,
    required int wrong,
    required int totalPoints,
  }) async {
    final userKeys = _userKeys();
    if (userKeys.isEmpty) return;
    final userId = userKeys.first;
    final today = DateTime.now().toUtc().toIso8601String().substring(0, 10);

    try {
      await Supabase.instance.client.from('student_quiz_progress').upsert({
        'user_id': userId,
        'lesson_id': '$_examPassPrefix$examId',
        'quiz_id': examId,
        'correct_count': score,
        'wrong_count': wrong,
        'level': 1,
        'total_points': totalPoints,
        'badges': const <String>[],
        'attempt_date': today,
      }, onConflict: 'user_id,lesson_id,attempt_date');
    } catch (e) {
      if (isMissingStudentQuizProgressTableError(e)) {
        return;
      }
      rethrow;
    }
  }

  static List<FinalExamQuestion> buildRandomQuestionSet(FinalExamRecord exam) {
    final pool = exam.questions.map((q) => q).toList();
    pool.shuffle(Random());
    final count = min(max(1, exam.questionsToAnswer), pool.length);

    return pool.take(count).map((q) {
      if (q.type == 'mcq' || q.type == 'true_false' || q.type == 'fill_blank') {
        final idx = List<int>.generate(q.options.length, (i) => i)
          ..shuffle(Random());
        final shuffledOptions = idx.map((i) => q.options[i]).toList();
        final shuffledCorrectIndex = idx.indexOf(q.correctIndex);
        return FinalExamQuestion(
          type: q.type,
          question: q.question,
          options: shuffledOptions,
          correctIndex: shuffledCorrectIndex,
          correctAnswer: shuffledOptions[shuffledCorrectIndex],
          imageUrl: q.imageUrl,
        );
      }
      return q;
    }).toList();
  }

  static Future<SubjectScoreData?> fetchCombinedSubjectScore(
    String subjectName,
    int classLevel,
    String finalExamId,
  ) async {
    final userKeys = _userKeys();
    if (userKeys.isEmpty) return null;

    final normalizedSubject = _normalizeSubject(subjectName);

    try {
      // 1. Check if final exam is taken
      final finalExamRows = await Supabase.instance.client
          .from('student_quiz_progress')
          .select('correct_count, wrong_count, total_points')
          .inFilter('user_id', userKeys)
          .eq('lesson_id', '$_examPassPrefix$finalExamId');

      if (finalExamRows.isEmpty) {
        return SubjectScoreData(
          chapterScoreOutOf40: 0,
          finalScoreOutOf60: 0,
          totalScore: 0,
          hasTakenFinal: false,
        );
      }

      // Calculate Final Exam Score (out of 60)
      double finalScoreOutOf60 = 0.0;
      int bestFinalScore = 0;
      int bestFinalTotal = 0;
      // Find the best attempt if there are multiple
      for (final row in finalExamRows) {
        final correct = int.tryParse((row['correct_count'] ?? '0').toString()) ?? 0;
        final wrong = int.tryParse((row['wrong_count'] ?? '0').toString()) ?? 0;
        final totalQs = correct + wrong;
        if (totalQs > 0) {
          final percentage = correct / totalQs;
          final currentPoints = (percentage * 60).round();
          if (currentPoints > bestFinalScore) {
             bestFinalScore = currentPoints;
             bestFinalTotal = totalQs;
          }
        }
      }
      
      if (bestFinalTotal > 0) {
        finalScoreOutOf60 = bestFinalScore.toDouble();
      }

      // 2. Fetch chapter quizzes for this subject
      // First, get all chapters for this subject and classLevel
      final chaptersRows = await Supabase.instance.client
          .from('chapters')
          .select('id')
          .eq('subject_name', normalizedSubject)
          .eq('class_level', classLevel);
      
      final validChapterIds = chaptersRows
          .map((row) => row['id'].toString())
          .toSet();

      final chapterPassRows = await Supabase.instance.client
          .from('student_quiz_progress')
          .select('lesson_id, correct_count, wrong_count')
          .inFilter('user_id', userKeys)
          .like('lesson_id', '$_chapterQuizPassPrefix%');

      // To avoid counting the same chapter multiple times (e.g. retakes), track the best score per chapter
      final Map<String, double> bestChapterPercentages = {};

      for (final row in chapterPassRows) {
        final lessonId = (row['lesson_id'] ?? '').toString();
        if (!lessonId.startsWith(_chapterQuizPassPrefix)) continue;
        
        final chapterId = lessonId.substring(_chapterQuizPassPrefix.length).trim();
        if (!validChapterIds.contains(chapterId)) continue;
        
        final correct = int.tryParse((row['correct_count'] ?? '0').toString()) ?? 0;
        final wrong = int.tryParse((row['wrong_count'] ?? '0').toString()) ?? 0;
        final totalQs = correct + wrong;
        
        if (totalQs > 0) {
          final percentage = correct / totalQs;
          if (!bestChapterPercentages.containsKey(chapterId) || percentage > bestChapterPercentages[chapterId]!) {
             bestChapterPercentages[chapterId] = percentage;
          }
        }
      }

      double chapterScoreOutOf40 = 0.0;
      if (bestChapterPercentages.isNotEmpty) {
        // Average the percentages of all taken chapters
        double sumPercentages = 0.0;
        for (final pct in bestChapterPercentages.values) {
          sumPercentages += pct;
        }
        
        // Wait, should we divide by number of TAKEN chapters or total chapters?
        // The user said: "maada aksta inta cutub ay ka kooban tahay in 40 laxu qiimeeyo".
        // If a subject has 10 chapters, the max score is out of those 10.
        // If they only took 5, they should get 5/10 * 40? Yes.
        // So we divide by validChapterIds.length
        double avgPercentage = sumPercentages / (validChapterIds.isEmpty ? 1 : validChapterIds.length);
        chapterScoreOutOf40 = (avgPercentage * 40).roundToDouble();
      }

      return SubjectScoreData(
        chapterScoreOutOf40: chapterScoreOutOf40,
        finalScoreOutOf60: finalScoreOutOf60,
        totalScore: chapterScoreOutOf40 + finalScoreOutOf60,
        hasTakenFinal: true,
      );

    } catch (e) {
      return null;
    }
  }
}
