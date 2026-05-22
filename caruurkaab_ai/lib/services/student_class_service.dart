import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'final_exam_service.dart';
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
    
    // Fetch all active final exams
    final examsRows = await db
        .from('exams')
        .select('id, class_level, subject_name')
        .eq('exam_type', 'final_class')
        .eq('is_active', true);

    if (examsRows.isEmpty) return assigned;

    while (currentLevel < 4) {
      final currentLevelExams = examsRows.where((row) {
        final level = int.tryParse(row['class_level'].toString());
        return level == currentLevel;
      }).toList();

      if (currentLevelExams.isEmpty) {
        break; // No exams defined for this level, cannot promote
      }

      bool allPassed = true;
      for (final examRow in currentLevelExams) {
        final subjectName = examRow['subject_name']?.toString();
        final examId = examRow['id']?.toString();
        
        if (subjectName == null || examId == null) {
          allPassed = false;
          break;
        }

        final scoreData = await FinalExamService.fetchCombinedSubjectScore(
          subjectName,
          currentLevel,
          examId,
        );

        if (scoreData == null || !scoreData.isPassed) {
          allPassed = false;
          break;
        }
      }

      if (allPassed) {
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
