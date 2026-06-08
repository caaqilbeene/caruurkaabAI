import 'package:supabase_flutter/supabase_flutter.dart';

import 'student_profile_service.dart';

class LessonCompletionProgress {
  final int completed;
  final int total;

  const LessonCompletionProgress({
    required this.completed,
    required this.total,
  });

  double get ratio {
    if (total <= 0) return 0;
    return completed / total;
  }

  int get percentage => (ratio * 100).round();
}

class LessonCompletionProgressService {
  static Future<LessonCompletionProgress> fetchForCurrentUser() async {
    final db = Supabase.instance.client;
    final userKeys = StudentProfileService.currentUserKeys();
    if (userKeys.isEmpty) {
      return const LessonCompletionProgress(completed: 0, total: 0);
    }

    final lessons = await db.from('lessons').select('id');
    final total = lessons.length;

    if (total == 0) {
      return const LessonCompletionProgress(completed: 0, total: 0);
    }

    final progressQuery = db
        .from('lesson_progress')
        .select('lesson_id')
        .eq('completed', true);

    final List<dynamic> completedRows = userKeys.length == 1
        ? await progressQuery.eq('user_id', userKeys.first)
        : await progressQuery.inFilter('user_id', userKeys);

    final completedIds = <String>{};
    for (final row in completedRows) {
      final lessonId = row['lesson_id']?.toString();
      if (lessonId != null && lessonId.isNotEmpty) {
        completedIds.add(lessonId);
      }
    }
    final completed = completedIds.length;
    return LessonCompletionProgress(completed: completed, total: total);
  }

  static Future<Map<String, LessonCompletionProgress>> fetchSubjectProgressForCurrentUser() async {
    final db = Supabase.instance.client;
    final userKeys = StudentProfileService.currentUserKeys();
    if (userKeys.isEmpty) {
      return {};
    }

    // 1. Fetch all lessons with their subject_name
    final lessons = await db.from('lessons').select('id, subject_name');
    if (lessons.isEmpty) {
      return {};
    }

    // 2. Fetch completed lesson progress
    final progressQuery = db
        .from('lesson_progress')
        .select('lesson_id')
        .eq('completed', true);

    final List<dynamic> completedRows = userKeys.length == 1
        ? await progressQuery.eq('user_id', userKeys.first)
        : await progressQuery.inFilter('user_id', userKeys);

    final completedIds = <String>{};
    for (final row in completedRows) {
      final lessonId = row['lesson_id']?.toString();
      if (lessonId != null && lessonId.isNotEmpty) {
        completedIds.add(lessonId);
      }
    }

    // 3. Tally total and completed per subject
    final subjectTotals = <String, int>{};
    final subjectCompleted = <String, int>{};

    for (final row in lessons) {
      final id = row['id']?.toString() ?? '';
      final rawSubject = row['subject_name']?.toString() ?? 'Kale';
      
      // Normalize subject name to match the 4 standard ones
      String subject = rawSubject;
      final lower = rawSubject.toLowerCase();
      if (lower == 'af-soomaali' || lower == 'afsoomaali' || lower == 'af soomaali') {
        subject = 'Af Soomaali';
      } else if (lower == 'english') {
        subject = 'English';
      } else if (lower == 'xisaab') {
        subject = 'Xisaab';
      } else if (lower == 'saynis' || lower == 'seynis') {
        subject = 'Saynis';
      }

      subjectTotals[subject] = (subjectTotals[subject] ?? 0) + 1;
      if (completedIds.contains(id)) {
        subjectCompleted[subject] = (subjectCompleted[subject] ?? 0) + 1;
      }
    }

    final result = <String, LessonCompletionProgress>{};
    for (final subject in ['Af Soomaali', 'English', 'Xisaab', 'Saynis']) {
      final total = subjectTotals[subject] ?? 0;
      final completed = subjectCompleted[subject] ?? 0;
      result[subject] = LessonCompletionProgress(completed: completed, total: total);
    }

    return result;
  }
}
