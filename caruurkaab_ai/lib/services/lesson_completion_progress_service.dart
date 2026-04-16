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
}
