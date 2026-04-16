import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'student_profile_service.dart';

class StudentClassService {
  static const String _keyPrefix = 'assigned_student_class_';

  static String _storageKeyForCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email?.trim().toLowerCase();
    if (email != null && email.isNotEmpty) {
      return '$_keyPrefix$email';
    }
    final uid = user?.uid.trim();
    if (uid != null && uid.isNotEmpty) {
      return '$_keyPrefix$uid';
    }
    return '${_keyPrefix}guest';
  }

  static String normalizeClassLabel(String raw) {
    final text = raw.trim().toLowerCase();
    if (text.isEmpty) return 'Class 1';

    final match = RegExp(r'\d+').firstMatch(text);
    final level = match?.group(0);
    if (level == null) {
      if (text == 'class' || text == 'fasalka') return 'Class 1';
      return 'Class 1';
    }
    return 'Class $level';
  }

  static int extractClassLevel(String classLabel) {
    final match = RegExp(r'\d+').firstMatch(classLabel);
    final level = int.tryParse(match?.group(0) ?? '');
    if (level == null) return 1;
    return level.clamp(1, 4);
  }

  static String toFasalkaLabel(String classLabel) {
    final level = extractClassLevel(classLabel);
    return 'Fasalka $level';
  }

  static Future<void> saveAssignedClass(String rawClass) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = normalizeClassLabel(rawClass);
    await prefs.setString(_storageKeyForCurrentUser(), normalized);
  }

  static Future<String> fetchAssignedClass() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_storageKeyForCurrentUser());
    if (saved == null || saved.trim().isEmpty) {
      return 'Class 1';
    }
    return normalizeClassLabel(saved);
  }

  static Future<String> refreshAssignedClassByProgress() async {
    final assigned = await fetchAssignedClass();
    int currentLevel = extractClassLevel(assigned);

    final userKeys = StudentProfileService.currentUserKeys();
    if (userKeys.isEmpty) return assigned;

    final db = Supabase.instance.client;
    final lessonsRows = await db.from('lessons').select('id, class_level');

    if (lessonsRows.isEmpty) return assigned;

    final progressQuery = db
        .from('lesson_progress')
        .select('lesson_id')
        .eq('completed', true);

    final List<dynamic> completedRows = userKeys.length == 1
        ? await progressQuery.eq('user_id', userKeys.first)
        : await progressQuery.inFilter('user_id', userKeys);

    final completedIds = <String>{
      for (final row in completedRows)
        if (row['lesson_id'] != null) row['lesson_id'].toString(),
    };

    final Map<int, int> totalsByClass = <int, int>{};
    final Map<int, int> completedByClass = <int, int>{};

    for (final row in lessonsRows) {
      final rawClass = row['class_level'];
      final rawId = row['id'];
      final level = int.tryParse(rawClass.toString());
      if (level == null || level < 1 || level > 4 || rawId == null) continue;

      totalsByClass[level] = (totalsByClass[level] ?? 0) + 1;
      if (completedIds.contains(rawId.toString())) {
        completedByClass[level] = (completedByClass[level] ?? 0) + 1;
      }
    }

    while (currentLevel < 4) {
      final total = totalsByClass[currentLevel] ?? 0;
      final completed = completedByClass[currentLevel] ?? 0;
      if (total > 0 && completed >= total) {
        currentLevel += 1;
      } else {
        break;
      }
    }

    final promoted = 'Class $currentLevel';
    if (promoted != assigned) {
      await saveAssignedClass(promoted);
    }
    return promoted;
  }
}
