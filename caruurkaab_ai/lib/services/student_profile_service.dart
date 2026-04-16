import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/student_profile_record.dart';

class StudentProfileService {
  static const String _tableName = 'student_registry';

  static List<String> currentUserKeys() {
    final user = fb.FirebaseAuth.instance.currentUser;
    if (user == null) return const [];

    final keys = <String>[];
    final email = user.email?.trim().toLowerCase();
    if (email != null && email.isNotEmpty) {
      keys.add(email);
    }

    final uid = user.uid.trim();
    if (uid.isNotEmpty && !keys.contains(uid)) {
      keys.add(uid);
    }
    return keys;
  }

  static String? currentUserKey() {
    final keys = currentUserKeys();
    if (keys.isEmpty) return null;
    return keys.first;
  }

  static Future<StudentProfileRecord?> fetchOrCreate() async {
    final user = fb.FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final userId = currentUserKey();
    if (userId == null) return null;

    try {
      final existing = await _fetch(userId);
      if (existing != null) {
        await _backfillIfNeeded(existing, user);
        return existing;
      }

      final joinedAt =
          user.metadata.creationTime?.toUtc() ?? DateTime.now().toUtc();
      final fullName = user.displayName?.trim();
      final email = user.email?.trim().toLowerCase();

      try {
        await Supabase.instance.client.from(_tableName).insert({
          'user_id': userId,
          'email': email,
          'full_name': (fullName == null || fullName.isEmpty) ? null : fullName,
          'joined_at': joinedAt.toIso8601String(),
        });
      } catch (_) {
        // Another device may have inserted the same row already.
      }

      final created = await _fetch(userId);
      return created;
    } catch (e) {
      debugPrint('StudentProfileService.fetchOrCreate failed: $e');
      return null;
    }
  }

  static Future<void> _backfillIfNeeded(
    StudentProfileRecord existing,
    fb.User user,
  ) async {
    final displayName = user.displayName?.trim();
    final email = user.email?.trim().toLowerCase();

    final needsName =
        (existing.fullName == null || existing.fullName!.isEmpty) &&
        (displayName != null && displayName.isNotEmpty);
    final needsEmail =
        (existing.email == null || existing.email!.isEmpty) &&
        (email != null && email.isNotEmpty);

    if (!needsName && !needsEmail) return;

    final update = <String, dynamic>{};
    if (needsName) update['full_name'] = displayName;
    if (needsEmail) update['email'] = email;
    update['updated_at'] = DateTime.now().toUtc().toIso8601String();

    try {
      await Supabase.instance.client
          .from(_tableName)
          .update(update)
          .eq('user_id', existing.userId);
    } catch (e) {
      debugPrint('StudentProfileService._backfillIfNeeded failed: $e');
    }
  }

  static Future<void> updateDisplayName(String name) async {
    final userId = currentUserKey();
    if (userId == null) return;
    final cleaned = name.trim();
    if (cleaned.isEmpty) return;

    try {
      await Supabase.instance.client
          .from(_tableName)
          .update({
            'full_name': cleaned,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('StudentProfileService.updateDisplayName failed: $e');
    }
  }

  static Future<StudentProfileRecord?> _fetch(String userId) async {
    final row = await Supabase.instance.client
        .from(_tableName)
        .select('user_id, student_no, joined_at, full_name, email')
        .eq('user_id', userId)
        .maybeSingle();

    if (row == null) {
      return null;
    }
    final studentNo = row['student_no'] as int?;
    final joinedAtRaw = row['joined_at']?.toString();
    if (studentNo == null || joinedAtRaw == null || joinedAtRaw.isEmpty) {
      return null;
    }

    final joinedAt = DateTime.tryParse(joinedAtRaw)?.toLocal();
    if (joinedAt == null) {
      return null;
    }

    return StudentProfileRecord(
      userId: row['user_id']?.toString() ?? userId,
      studentNo: studentNo,
      joinedAt: joinedAt,
      fullName: row['full_name']?.toString(),
      email: row['email']?.toString(),
    );
  }
}
