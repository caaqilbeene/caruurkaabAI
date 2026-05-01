import 'package:supabase_flutter/supabase_flutter.dart';

import 'student_profile_service.dart';

class StudentAchievementSummary {
  final int totalPoints;
  final int badgesEarned;
  final List<String> badges;

  const StudentAchievementSummary({
    required this.totalPoints,
    required this.badgesEarned,
    required this.badges,
  });
}

class StudentAchievementService {
  static Future<StudentAchievementSummary> fetchForCurrentUser() async {
    final userId = StudentProfileService.currentUserKey();
    if (userId == null || userId.isEmpty) {
      return const StudentAchievementSummary(
        totalPoints: 0,
        badgesEarned: 0,
        badges: [],
      );
    }

    try {
      final rows = await Supabase.instance.client
          .from('student_quiz_progress')
          .select('total_points,badges')
          .eq('user_id', userId);

      var points = 0;
      final badgeSet = <String>{};

      for (final row in rows) {
        final map = Map<String, dynamic>.from(row);
        points += int.tryParse(map['total_points']?.toString() ?? '') ?? 0;
        final badgesRaw = map['badges'];
        if (badgesRaw is List) {
          for (final badge in badgesRaw) {
            final text = badge.toString().trim();
            if (text.isNotEmpty) badgeSet.add(text);
          }
        }
      }

      final badges = badgeSet.toList()..sort();
      return StudentAchievementSummary(
        totalPoints: points,
        badgesEarned: badges.length,
        badges: badges,
      );
    } catch (_) {
      return const StudentAchievementSummary(
        totalPoints: 0,
        badgesEarned: 0,
        badges: [],
      );
    }
  }
}
