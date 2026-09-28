import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'AvatarUploadStatus.dart';


import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AvatarManager {
  static final AvatarManager _instance = AvatarManager._internal();
  factory AvatarManager() => _instance;
  AvatarManager._internal();

  final Dio _dio = Dio();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _currentUid;
  String? _avatarDirPath;

  static const String _avatarTimestampsKey = 'avatar_timestamps_cache';

  final Map<String, StreamSubscription> _avatarListeners = {};

  // Track which users' avatars are currently being downloaded
  final Set<String> _downloadingAvatars = {};

  /// Initialize - call once
  Future<void> initialize() async {
    _currentUid = FirebaseAuth.instance.currentUser?.uid;
    _avatarDirPath = await _getAvatarDirectory();
    debugPrint("[AvatarManager] Initialized. Dir: $_avatarDirPath");
  }

  Future<String> _getAvatarDirectory() async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final Directory avatarDir = Directory('${appDocDir.path}/avatars');

    if (!await avatarDir.exists()) {
      await avatarDir.create(recursive: true);
    }

    return avatarDir.path;
  }

  // ═══════════════════════════════════════════════════════════════
  // CHECK IF OTHER USER'S AVATAR IS READY LOCALLY
  // ═══════════════════════════════════════════════════════════════

  /// Quick check - is other user's avatar file present locally AND up to date?
  Future<bool> isOtherAvatarReady(String otherUserId) async {
    if (_avatarDirPath == null) await initialize();

    try {
      final info = await _getOtherUserAvatarInfo(otherUserId);
      if (info == null || info['fileName'] == null) return false;

      final filePath = '$_avatarDirPath/${info['fileName']}';

      // File must exist
      if (!File(filePath).existsSync()) return false;

      // File must be up to date (not outdated by a server update)
      final bool needsUpdate =
      await _doesAvatarNeedUpdate(otherUserId, info['updatedAt']);

      if (needsUpdate) {
        debugPrint(
            "[AvatarManager] File exists but outdated for: $otherUserId");
        return false;
      }

      return true;
    } catch (e) {
      debugPrint("[AvatarManager] Error checking avatar ready: $e");
      return false;
    }
  }

  /// Is this user's avatar currently being downloaded?
  bool isDownloading(String otherUserId) {
    return _downloadingAvatars.contains(otherUserId);
  }

  // ═══════════════════════════════════════════════════════════════
  // GET AVATAR INFO FROM FIRESTORE
  // ═══════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>?> _getOtherUserAvatarInfo(
      String otherUserId) async {
    try {
      final doc =
      await _firestore.collection('users').doc(otherUserId).get();

      if (!doc.exists) return null;

      final data = doc.data();
      if (data == null) return null;

      return {
        'fileName': data['avatarFileName'],
        'url': data['avatarUrl'],
        'synced': data['avatarSynced'] == true,
        'gender': data['avatarGender'],
        'updatedAt': data['avatarUpdatedAt'],
      };
    } catch (e) {
      debugPrint("[AvatarManager] Error getting avatar info: $e");
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // DOWNLOAD OTHER USER'S AVATAR
  // ═══════════════════════════════════════════════════════════════

  /// Download other user's avatar silently in background
  /// Returns local file path if successful, null if failed
  /// Download other user's avatar silently in background
  /// onProgress callback reports 0.0 to 1.0
  Future<String?> downloadOtherUserAvatar(
      String otherUserId, {
        Function(double progress)? onProgress,
      }) async {
    if (_avatarDirPath == null) await initialize();

    // Prevent duplicate downloads
    if (_downloadingAvatars.contains(otherUserId)) {
      debugPrint("[AvatarManager] Already downloading for: $otherUserId");
      return null;
    }

    _downloadingAvatars.add(otherUserId);

    try {
      final info = await _getOtherUserAvatarInfo(otherUserId);

      if (info == null) {
        debugPrint("[AvatarManager] No avatar info for: $otherUserId");
        return null;
      }

      final String? fileName = info['fileName'];
      final String? downloadUrl = info['url'];
      final bool synced = info['synced'] ?? false;

      if (fileName == null || downloadUrl == null || !synced) {
        debugPrint(
            "[AvatarManager] Avatar not uploaded yet for: $otherUserId");
        return null;
      }

      final String filePath = '$_avatarDirPath/$fileName';

      // Check if we already have the latest version
      final bool needsUpdate =
      await _doesAvatarNeedUpdate(otherUserId, info['updatedAt']);

      if (File(filePath).existsSync() && !needsUpdate) {
        debugPrint("[AvatarManager] Already up to date: $fileName");
        onProgress?.call(1.0);
        return filePath;
      }

      // Delete old file if exists
      final existingFile = File(filePath);
      if (existingFile.existsSync()) {
        await existingFile.delete();
      }

      // Download with progress
      debugPrint("[AvatarManager] Downloading: $downloadUrl");

      await _dio.download(
        downloadUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            onProgress?.call(progress);
          }
        },
      );

      // Save timestamp
      await _saveAvatarTimestamp(otherUserId, info['updatedAt']);

      onProgress?.call(1.0);
      debugPrint("[AvatarManager] Downloaded: $filePath");
      return filePath;
    } catch (e) {
      debugPrint("[AvatarManager] Download error: $e");
      return null;
    } finally {
      _downloadingAvatars.remove(otherUserId);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // AVATAR UPDATE DETECTION
  // ═══════════════════════════════════════════════════════════════

  Future<bool> _doesAvatarNeedUpdate(
      String otherUserId, dynamic serverTimestamp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String cacheJson =
          prefs.getString(_avatarTimestampsKey) ?? '{}';
      final Map<String, dynamic> cache =
      Map<String, dynamic>.from(_safeJsonDecode(cacheJson));

      final int? lastDownloadedAt = cache[otherUserId] as int?;

      if (lastDownloadedAt == null) return true;
      if (serverTimestamp == null) return false;

      int serverMillis;
      if (serverTimestamp is Timestamp) {
        serverMillis = serverTimestamp.millisecondsSinceEpoch;
      } else if (serverTimestamp is int) {
        serverMillis = serverTimestamp;
      } else {
        return false;
      }

      return serverMillis > lastDownloadedAt;
    } catch (e) {
      return true;
    }
  }

  Future<void> _saveAvatarTimestamp(
      String otherUserId, dynamic serverTimestamp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String cacheJson =
          prefs.getString(_avatarTimestampsKey) ?? '{}';
      final Map<String, dynamic> cache =
      Map<String, dynamic>.from(_safeJsonDecode(cacheJson));

      int timestampMillis = DateTime.now().millisecondsSinceEpoch;
      if (serverTimestamp is Timestamp) {
        timestampMillis = serverTimestamp.millisecondsSinceEpoch;
      } else if (serverTimestamp is int) {
        timestampMillis = serverTimestamp;
      }

      cache[otherUserId] = timestampMillis;
      await prefs.setString(_avatarTimestampsKey, jsonEncode(cache));
    } catch (e) {
      debugPrint("[AvatarManager] Error saving timestamp: $e");
    }
  }

  Map<String, dynamic> _safeJsonDecode(String json) {
    try {
      return Map<String, dynamic>.from(
          jsonDecode(json) as Map<String, dynamic>);
    } catch (e) {
      return {};
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // REAL-TIME LISTENER FOR OTHER USER'S AVATAR CHANGES
  // ═══════════════════════════════════════════════════════════════

  /// Listen for avatar changes from a specific user
  /// Automatically re-downloads when they update their avatar
  StreamSubscription<DocumentSnapshot>? listenToUserAvatarChanges(
      String otherUserId, {
        required Function(String? newLocalPath) onAvatarUpdated,
      }) {
    debugPrint("[AvatarManager] Listening to avatar changes: $otherUserId");

    final subscription = _firestore
        .collection('users')
        .doc(otherUserId)
        .snapshots()
        .listen((snapshot) async {
      if (!snapshot.exists) return;

      final data = snapshot.data();
      if (data == null) return;

      final bool synced = data['avatarSynced'] == true;
      final String? fileName = data['avatarFileName'];
      final String? url = data['avatarUrl'];

      if (!synced || fileName == null || url == null) return;

      // Check if update needed
      final needsUpdate = await _doesAvatarNeedUpdate(
          otherUserId, data['avatarUpdatedAt']);
      final filePath = '$_avatarDirPath/$fileName';
      final fileExists = File(filePath).existsSync();

      if (!fileExists || needsUpdate) {
        debugPrint("[AvatarManager] Avatar update detected: $otherUserId");
        final newPath = await downloadOtherUserAvatar(otherUserId);
        onAvatarUpdated(newPath);
      }
    }, onError: (e) {
      debugPrint("[AvatarManager] Listener error: $e");
    });

    _avatarListeners[otherUserId] = subscription;
    return subscription;
  }

  /// Stop listening to a specific user
  void stopListeningToUserAvatar(String otherUserId) {
    _avatarListeners[otherUserId]?.cancel();
    _avatarListeners.remove(otherUserId);
  }

  /// Stop all listeners
  void stopAllAvatarListeners() {
    for (final sub in _avatarListeners.values) {
      sub.cancel();
    }
    _avatarListeners.clear();
  }

  void dispose() {
    stopAllAvatarListeners();
  }
}