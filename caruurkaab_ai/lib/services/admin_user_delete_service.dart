import 'package:cloud_functions/cloud_functions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminUserDeleteException implements Exception {
  final String message;
  final String code;

  const AdminUserDeleteException({required this.message, required this.code});

  @override
  String toString() => message;
}

class AdminUserDeleteService {
  static const List<String> _regionsToTry = <String>[
    // Default Firebase Functions region.
    'us-central1',
    // Common alternatives (haddii project-ku hore region kale u isticmaalay).
    'europe-west1',
    'asia-south1',
  ];

  static String _friendlyMessage(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'not-found':
        return 'Delete service lama helin (Cloud Function not found).';
      case 'permission-denied':
        return 'Kaliya admin email la ogol yahay ayaa delete sameyn kara.';
      case 'unauthenticated':
        return 'Fadlan admin login samee mar kale.';
      case 'failed-precondition':
        return e.message ??
            'Backend config (ADMIN_EMAILS / SUPABASE secrets) wali ma dhameystirna.';
      default:
        return e.message ?? 'Delete failed. Fadlan isku day mar kale.';
    }
  }

  static Future<void> _deleteFromSupabase({
    required String userId,
    String? email,
  }) async {
    final client = Supabase.instance.client;
    final keys = <String>{
      userId.trim(),
      if (email != null && email.trim().isNotEmpty) email.trim(),
    }..removeWhere((v) => v.isEmpty);

    Future<void> deleteByKeys(String table) async {
      for (final key in keys) {
        await client.from(table).delete().eq('user_id', key);
      }
    }

    // student_registry + user_profiles user_id column ayay ku xiran yihiin.
    await deleteByKeys('student_registry');
    await deleteByKeys('user_profiles');
    await deleteByKeys('lesson_progress');

    // Haddii key uu email yahay, column email ku jira student_registry-na ka nadiifi.
    if (email != null && email.trim().isNotEmpty) {
      await client.from('student_registry').delete().eq('email', email.trim());
    }
  }

  /// Hal taabasho delete:
  /// Firebase Auth + Supabase (student_registry, user_profiles, lesson_progress)
  static Future<String> deleteUserEverywhere({
    required String userId,
    String? email,
  }) async {
    var cloudFunctionWorked = false;
    for (final region in _regionsToTry) {
      try {
        final functions = FirebaseFunctions.instanceFor(region: region);
        final callable = functions.httpsCallable(
          'deleteUserEverywhere',
          options: HttpsCallableOptions(timeout: const Duration(seconds: 45)),
        );
        await callable.call(<String, dynamic>{
          'userId': userId,
          'email': email,
        });
        cloudFunctionWorked = true;
        break;
      } on FirebaseFunctionsException catch (e) {
        if (e.code == 'not-found') {
          continue;
        }
        throw AdminUserDeleteException(
          message: _friendlyMessage(e),
          code: e.code,
        );
      } catch (_) {
        rethrow;
      }
    }

    // Supabase had iyo jeer ka nadiifi si user-ku list-ka uga boxo isla markiiba.
    try {
      await _deleteFromSupabase(userId: userId, email: email);
      return cloudFunctionWorked ? 'full' : 'supabase_only';
    } catch (e) {
      throw AdminUserDeleteException(
        code: cloudFunctionWorked ? 'supabase-delete-failed' : 'not-found',
        message:
            'Delete completed part ahaan, laakiin Supabase delete wuu fashilmay. Hubi RLS/policies. Faahfaahin: $e',
      );
    }
  }
}
