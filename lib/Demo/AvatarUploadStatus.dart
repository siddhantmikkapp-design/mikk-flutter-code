import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AvatarUploadStatus {
  idle,
  pending,
  uploading,
  completed,
  failed,
}

class AvatarUploadManager with WidgetsBindingObserver {
  // Singleton
  static final AvatarUploadManager _instance = AvatarUploadManager._internal();
  factory AvatarUploadManager() => _instance;
  AvatarUploadManager._internal();

  static const String _pendingUploadsKey = 'pending_avatar_uploads';
  static const int _maxRetries = 5;

  bool _isProcessing = false;
  bool _isObserving = false;

  // Stream to notify UI about status changes
  final StreamController<AvatarUploadStatus> _statusController =
  StreamController<AvatarUploadStatus>.broadcast();

  Stream<AvatarUploadStatus> get statusStream => _statusController.stream;

  AvatarUploadStatus _currentStatus = AvatarUploadStatus.idle;
  AvatarUploadStatus get currentStatus => _currentStatus;

  /// Call once in main.dart after Firebase.initializeApp()
  void initialize() {
    if (!_isObserving) {
      WidgetsBinding.instance.addObserver(this);
      _isObserving = true;
      print("[AvatarUploadManager] Initialized with lifecycle observer");
    }
    // Retry any pending uploads from previous session
    retryPendingUploads();
  }

  /// Auto-retry when app comes back to foreground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print("[AvatarUploadManager] App resumed - checking pending uploads");
      retryPendingUploads();
    }
  }

  /// Queue an avatar for background upload
  Future<void> queueUpload({
    required String uid,
    required String localFilePath,
    required String fileName,
    required String gender,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final List<String> pendingUploads =
          prefs.getStringList(_pendingUploadsKey) ?? [];

      // Remove any existing entry for same fileName (avoid duplicates)
      pendingUploads.removeWhere((entry) {
        try {
          final map = jsonDecode(entry) as Map<String, dynamic>;
          return map['fileName'] == fileName;
        } catch (_) {
          return false;
        }
      });

      // Add new entry
      final uploadEntry = jsonEncode({
        'uid': uid,
        'localFilePath': localFilePath,
        'fileName': fileName,
        'gender': gender,
        'retryCount': 0,
        'queuedAt': DateTime.now().toIso8601String(),
      });

      pendingUploads.add(uploadEntry);
      await prefs.setStringList(_pendingUploadsKey, pendingUploads);

      _updateStatus(AvatarUploadStatus.pending);
      print("[AvatarUploadManager] Queued upload: $fileName");

      // Start processing immediately using microtask
      // This ensures it runs even if the calling screen is disposed
      Future.microtask(() => _processQueue());
    } catch (e) {
      print("[AvatarUploadManager] Error queuing upload: $e");
    }
  }

  /// Retry pending uploads - call from any screen
  Future<void> retryPendingUploads() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> pendingUploads =
          prefs.getStringList(_pendingUploadsKey) ?? [];

      if (pendingUploads.isNotEmpty) {
        print(
            "[AvatarUploadManager] Found ${pendingUploads.length} pending uploads, processing...");
        _processQueue();
      } else {
        _updateStatus(AvatarUploadStatus.idle);
      }
    } catch (e) {
      print("[AvatarUploadManager] Error checking pending uploads: $e");
    }
  }

  /// Main queue processor
  Future<void> _processQueue() async {
    if (_isProcessing) {
      print("[AvatarUploadManager] Already processing, skipping");
      return;
    }

    _isProcessing = true;
    _updateStatus(AvatarUploadStatus.uploading);

    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> pendingUploads =
          prefs.getStringList(_pendingUploadsKey) ?? [];

      if (pendingUploads.isEmpty) {
        _isProcessing = false;
        _updateStatus(AvatarUploadStatus.idle);
        return;
      }

      // Check if user is logged in
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print("[AvatarUploadManager] User not logged in, will retry later");
        _isProcessing = false;
        _updateStatus(AvatarUploadStatus.pending);
        return;
      }

      final List<String> remainingUploads = [];

      for (final entry in pendingUploads) {
        try {
          final map = jsonDecode(entry) as Map<String, dynamic>;
          final success = await _uploadSingle(map);

          if (!success) {
            final retryCount = (map['retryCount'] as int) + 1;

            if (retryCount < _maxRetries) {
              map['retryCount'] = retryCount;
              map['lastRetryAt'] = DateTime.now().toIso8601String();
              remainingUploads.add(jsonEncode(map));
              print(
                  "[AvatarUploadManager] Failed, will retry ($retryCount/$_maxRetries): ${map['fileName']}");
            } else {
              print(
                  "[AvatarUploadManager] Permanently failed after $_maxRetries retries: ${map['fileName']}");

              // Mark as failed in Firestore
              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(map['uid'])
                    .set({
                  'avatarSyncFailed': true,
                  'avatarSyncError': 'Max retries exceeded',
                  'avatarSyncLastAttempt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));
              } catch (_) {}
            }
          }
        } catch (e) {
          print("[AvatarUploadManager] Error processing entry: $e");
          // Keep the entry for retry
          remainingUploads.add(entry);
        }
      }

      // Update queue
      await prefs.setStringList(_pendingUploadsKey, remainingUploads);

      if (remainingUploads.isEmpty) {
        _updateStatus(AvatarUploadStatus.completed);
        print("[AvatarUploadManager] All uploads completed!");
      } else {
        _updateStatus(AvatarUploadStatus.failed);
        print(
            "[AvatarUploadManager] ${remainingUploads.length} uploads remaining");
      }
    } catch (e) {
      print("[AvatarUploadManager] Error processing queue: $e");
      _updateStatus(AvatarUploadStatus.failed);
    } finally {
      _isProcessing = false;
    }
  }

  /// Upload a single avatar file to Firebase Storage + update Firestore
  Future<bool> _uploadSingle(Map<String, dynamic> uploadInfo) async {
    try {
      final String localFilePath = uploadInfo['localFilePath'];
      final String fileName = uploadInfo['fileName'];
      final String uid = uploadInfo['uid'];
      final String gender = uploadInfo['gender'];

      final file = File(localFilePath);

      // Check if local file still exists
      if (!await file.exists()) {
        print(
            "[AvatarUploadManager] Local file gone: $localFilePath — removing from queue");
        return true; // Remove from queue
      }

      print("[AvatarUploadManager] Uploading: $fileName ...");

      // Upload to Firebase Storage
      final storageRef =
      FirebaseStorage.instance.ref().child('avatars/$uid/$fileName');

      final uploadTask = await storageRef.putFile(
        file,
        SettableMetadata(contentType: 'model/gltf-binary'),
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Update Firestore with download URL
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'avatarFileName': fileName,
        'avatarUrl': downloadUrl,
        'avatarGender': gender,
        'avatarStoragePath': 'avatars/$uid/$fileName',
        'avatarUploadedAt': FieldValue.serverTimestamp(),
        'avatarSynced': true,
        'avatarSyncFailed': false,
      }, SetOptions(merge: true));

      print(
          "[AvatarUploadManager] Upload successful: $fileName → $downloadUrl");
      return true;
    } catch (e) {
      print("[AvatarUploadManager] Upload failed: $e");
      return false;
    }
  }

  /// Check if there are pending uploads
  Future<bool> hasPendingUploads() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> pendingUploads =
          prefs.getStringList(_pendingUploadsKey) ?? [];
      return pendingUploads.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get count of pending uploads
  Future<int> pendingUploadCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> pendingUploads =
          prefs.getStringList(_pendingUploadsKey) ?? [];
      return pendingUploads.length;
    } catch (e) {
      return 0;
    }
  }

  /// Clear all pending uploads
  Future<void> clearQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingUploadsKey);
    _updateStatus(AvatarUploadStatus.idle);
  }

  void _updateStatus(AvatarUploadStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  void dispose() {
    if (_isObserving) {
      WidgetsBinding.instance.removeObserver(this);
      _isObserving = false;
    }
    _statusController.close();
  }
}