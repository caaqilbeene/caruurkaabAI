import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileAvatarService {
  static const String _bucketName = 'profile-images';
  static const String _tableName = 'user_profiles';

  static String? currentUserId() {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.uid != null && user!.uid.isNotEmpty) return user.uid;
    if (user?.email != null && user!.email!.isNotEmpty) return user.email!;
    return null;
  }

  static Future<String?> fetchAvatarUrl() async {
    final userId = currentUserId();
    if (userId == null) return null;

    try {
      final row = await Supabase.instance.client
          .from(_tableName)
          .select('avatar_url')
          .eq('user_id', userId)
          .maybeSingle();
      final url = row?['avatar_url']?.toString().trim();
      if (url == null || url.isEmpty) return null;
      return url;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> uploadAvatar(Uint8List bytes) async {
    final userId = currentUserId();
    if (userId == null) return null;

    try {
      final safeUserId = _safeSegment(userId);
      final filePath =
          'users/$safeUserId/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storage = Supabase.instance.client.storage.from(_bucketName);

      await storage.uploadBinary(
        filePath,
        bytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
      );

      final publicUrl = storage.getPublicUrl(filePath);

      await Supabase.instance.client.from(_tableName).upsert({
        'user_id': userId,
        'avatar_url': publicUrl,
      }, onConflict: 'user_id');

      return publicUrl;
    } catch (e) {
      debugPrint('Avatar upload failed: $e');
      return null;
    }
  }

  static String _safeSegment(String value) {
    return value.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }
}
