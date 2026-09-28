import 'package:cloud_firestore/cloud_firestore.dart';

class AvatarSyncChecker {
  /// One-time check if avatar is synced
  static Future<bool> isAvatarSynced(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!doc.exists) return false;
      return doc.data()?['avatarSynced'] == true;
    } catch (e) {
      print("Error checking avatar sync: $e");
      return false;
    }
  }

  /// Real-time stream of sync status
  static Stream<Map<String, dynamic>> watchAvatarStatus(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        return {
          'synced': false,
          'failed': false,
          'fileName': null,
          'url': null,
        };
      }

      final data = doc.data() ?? {};
      return {
        'synced': data['avatarSynced'] == true,
        'failed': data['avatarSyncFailed'] == true,
        'fileName': data['avatarFileName'],
        'url': data['avatarUrl'],
        'gender': data['avatarGender'],
      };
    });
  }
}