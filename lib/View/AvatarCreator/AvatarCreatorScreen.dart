import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../Demo/AvatarUploadStatus.dart';
import '../../View_Model/auth_view_model.dart';
import '../../values/Color.dart';



import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';



class AvatarCreatorScreen extends StatefulWidget {
  final String gender;
  final bool isProfile;

  const AvatarCreatorScreen(
      {super.key, required this.gender, required this.isProfile});

  @override
  _AvatarCreatorScreenState createState() => _AvatarCreatorScreenState();
}

class _AvatarCreatorScreenState extends State<AvatarCreatorScreen> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  String? _avatarUrl;
  String? _savedFilePath;
  bool _isLoading = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _statusMessage = "";
  final Dio _dio = Dio();
  bool _hasCheckedExistingAvatar = false;
  bool _hasHandledInitialLink = false;
  String? _lastProcessedUrl;

  final AvatarUploadManager _uploadManager = AvatarUploadManager();

  @override
  void initState() {
    super.initState();
    _checkExistingAvatar();
    _initDeepLinks();
    _createAvatarDirectory();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  // =============================================
  // HELPERS
  // =============================================

  /// Generate file name: {first3UID}_{gender}.glb
  String _generateFileName(String uid) {
    final String uidPrefix = uid.length >= 3 ? uid.substring(0, 3) : uid;
    return '${uidPrefix}_${widget.gender.toLowerCase()}.glb';
  }

  /// Get current user UID
  String? _getCurrentUid() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  /// Create avatar directory if not exists
  Future<String> _createAvatarDirectory() async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final Directory avatarDir = Directory('${appDocDir.path}/avatars');

    if (!await avatarDir.exists()) {
      await avatarDir.create(recursive: true);
    }

    return avatarDir.path;
  }

  // =============================================
  // CHECK EXISTING AVATAR
  // =============================================

  Future<void> _checkExistingAvatar() async {
    try {
      final String avatarDirPath = await _createAvatarDirectory();
      final uid = _getCurrentUid();

      // Check for user-specific avatar
      if (uid != null) {
        final String fileName = _generateFileName(uid);
        final String filePath = '$avatarDirPath/$fileName';
        final file = File(filePath);

        if (await file.exists()) {
          setState(() {
            _savedFilePath = filePath;
            _hasCheckedExistingAvatar = true;
          });
          print("Existing avatar found: $filePath");
          return;
        }
      }

      // Fallback: check by gender pattern
      final Directory avatarDir = Directory(avatarDirPath);
      if (await avatarDir.exists()) {
        final genderPattern = '_${widget.gender.toLowerCase()}.glb';
        for (var file in avatarDir.listSync()) {
          if (file.path.endsWith(genderPattern)) {
            setState(() {
              _savedFilePath = file.path;
              _hasCheckedExistingAvatar = true;
            });
            print("Existing avatar found by pattern: ${file.path}");
            return;
          }
        }
      }

      setState(() => _hasCheckedExistingAvatar = true);
      print("No existing avatar found");
    } catch (e) {
      print("Error checking existing avatar: $e");
      setState(() => _hasCheckedExistingAvatar = true);
    }
  }

  // =============================================
  // DEEP LINKS
  // =============================================

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Listen for links while app is running
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      print("Deep link received (stream): $uri");
      _handleDeepLink(uri, isInitialLink: false);
    });

    // Check for initial link (app opened via deep link)
    try {
      final uri = await _appLinks.getInitialAppLink();
      if (uri != null && !_hasHandledInitialLink) {
        print("Initial deep link: $uri");
        await Future.delayed(const Duration(milliseconds: 500));
        if (_hasCheckedExistingAvatar && mounted) {
          _handleDeepLink(uri, isInitialLink: true);
          _hasHandledInitialLink = true;
        }
      }
    } catch (e) {
      print("Error getting initial link: $e");
    }
  }

  void _handleDeepLink(Uri uri, {bool isInitialLink = false}) {
    if (!uri.queryParameters.containsKey('url')) return;

    final newAvatarUrl = uri.queryParameters['url'];
    print("Deep link URL: $newAvatarUrl");

    // Skip duplicate
    if (_lastProcessedUrl == newAvatarUrl) {
      print("Already processed this URL, skipping");
      return;
    }

    // Skip if initial link + profile mode + already have avatar
    if (isInitialLink && widget.isProfile && _savedFilePath != null) {
      print("Initial link in profile mode with existing avatar, skipping");
      _lastProcessedUrl = newAvatarUrl;
      return;
    }

    // Skip if download in progress
    if (_isDownloading) {
      print("Download in progress, skipping");
      return;
    }

    setState(() => _avatarUrl = newAvatarUrl);
    _lastProcessedUrl = newAvatarUrl;

    if (widget.isProfile) {
      _handleProfileUpdate(_avatarUrl!);
    } else {
      _handleSignupFlow(_avatarUrl!);
    }
  }

  // =============================================
  // OPEN BROWSER
  // =============================================

  Future<void> _openAvaturnInBrowser() async {
    setState(() => _isLoading = true);

    const String customPageUrl =
        "https://optimus-prime-cd.github.io/sag/index.html";

    try {
      bool launched = await launchUrl(
        Uri.parse(customPageUrl),
        mode: LaunchMode.externalApplication,
      );

      setState(() => _isLoading = false);

      if (!launched) _showError("Could not open avatar creator");
    } catch (e) {
      setState(() => _isLoading = false);
      _showError("Error: $e");
    }
  }

  // =============================================
  // LOCAL FILE OPERATIONS
  // =============================================

  /// Delete only the file with the exact same name
  Future<void> _deleteExistingFile(String fileName) async {
    try {
      final String avatarDirPath = await _createAvatarDirectory();
      final file = File('$avatarDirPath/$fileName');

      if (await file.exists()) {
        await file.delete();
        print("Deleted existing file: ${file.path}");
      }
    } catch (e) {
      print("Error deleting file: $e");
    }
  }

  /// Download avatar from URL to local storage
  Future<String> _downloadToLocal(String url, String fileName) async {
    final String avatarDirPath = await _createAvatarDirectory();
    final String filePath = '$avatarDirPath/$fileName';

    // Only delete file with same name
    await _deleteExistingFile(fileName);

    print("Downloading: $url → $filePath");

    await _dio.download(
      url,
      filePath,
      onReceiveProgress: (received, total) {
        if (total != -1 && mounted) {
          setState(() {
            _downloadProgress = received / total;
            _statusMessage =
            "Processing avatar... ${(received / total * 100).toStringAsFixed(0)}%";
          });
        }
      },
    );

    print("Download complete: $filePath");
    return filePath;
  }

  // =============================================
  // FIRESTORE - INITIAL SAVE (fast, no URL yet)
  // =============================================

  Future<void> _saveInitialAvatarInfo(
      String uid, String fileName, String gender) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'avatarFileName': fileName,
      'avatarGender': gender,
      'avatarSynced': false,
      'avatarSyncFailed': false,
      'avatarUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    print("Initial avatar info saved to Firestore");
  }

  // =============================================
  // SIGNUP FLOW: Sign in → Download → Queue upload
  // =============================================

  Future<void> _handleSignupFlow(String avatarUrl) async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
      _isLoading = true;
      _downloadProgress = 0.0;
      _statusMessage = "Creating your account...";
    });

    try {
      // STEP 1: Sign in anonymously FIRST (we need UID for file name)
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      await authViewModel.signInAnonymously();

      if (authViewModel.user == null) {
        setState(() {
          _isDownloading = false;
          _isLoading = false;
          _statusMessage = "";
        });
        _showError("Failed to create account. Please try again.");
        return;
      }

      final uid = authViewModel.user!.uid;
      print("Signed in with UID: $uid");

      // STEP 2: Save FCM token
      setState(() => _statusMessage = "Setting up notifications...");
      await _saveFcmToken(uid);

      // STEP 3: Generate file name based on UID
      final String fileName = _generateFileName(uid);
      print("Avatar file name: $fileName");

      // STEP 4: Download avatar locally (user waits for this ~3-5s)
      setState(() => _statusMessage = "Downloading your avatar...");
      final String localFilePath = await _downloadToLocal(avatarUrl, fileName);

      // STEP 5: Save initial metadata to Firestore (fast, ~0.5s)
      setState(() => _statusMessage = "Saving avatar info...");
      await _saveInitialAvatarInfo(uid, fileName, widget.gender.toLowerCase());

      // STEP 6: Queue background upload (user does NOT wait)
      _uploadManager.queueUpload(
        uid: uid,
        localFilePath: localFilePath,
        fileName: fileName,
        gender: widget.gender.toLowerCase(),
      );

      setState(() {
        _savedFilePath = localFilePath;
        _isDownloading = false;
        _downloadProgress = 1.0;
        _statusMessage = "All done!";
      });

      print("Signup complete! Cloud upload queued in background.");

      if (mounted) {
        _showSuccessDialogAndNavigate(localFilePath, authViewModel);
      }
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _isLoading = false;
        _statusMessage = "";
      });
      print("Signup flow error: $e");
      if (mounted) _showError("Failed to complete signup: $e");
    }
  }

  // =============================================
  // PROFILE UPDATE FLOW: Download → Queue upload
  // =============================================

  Future<void> _handleProfileUpdate(String avatarUrl) async {
    if (_isDownloading) return;

    final uid = _getCurrentUid();
    if (uid == null) {
      _showError("You must be logged in to update your avatar.");
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _statusMessage = "Downloading avatar...";
    });

    try {
      final String fileName = _generateFileName(uid);

      // STEP 1: Download locally (user waits for this only)
      final String localFilePath = await _downloadToLocal(avatarUrl, fileName);

      // STEP 2: Update Firestore metadata (fast)
      await _saveInitialAvatarInfo(uid, fileName, widget.gender.toLowerCase());

      // STEP 3: Queue background upload (user doesn't wait)
      _uploadManager.queueUpload(
        uid: uid,
        localFilePath: localFilePath,
        fileName: fileName,
        gender: widget.gender.toLowerCase(),
      );

      setState(() {
        _savedFilePath = localFilePath;
        _isDownloading = false;
        _downloadProgress = 1.0;
        _statusMessage = "";
      });

      print("Profile update complete! Cloud upload queued.");

      if (mounted) _showSuccessDialog(localFilePath);
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _statusMessage = "";
      });
      print("Profile update error: $e");
      if (mounted) _showError("Failed to update avatar: $e");
    }
  }

  // =============================================
  // FCM TOKEN
  // =============================================

  Future<void> _saveFcmToken(String uid) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'fcmToken': token,
      }, SetOptions(merge: true));

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update({'fcmToken': newToken});
      });
    } catch (e) {
      debugPrint("FCM token save failed: $e");
    }
  }

  // =============================================
  // DIALOGS
  // =============================================

  void _showSuccessDialogAndNavigate(
      String filePath, AuthViewModel authViewModel) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: primaryColor2, size: 30),
            const SizedBox(width: 10),
            const Text("Welcome!", style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Your account and avatar are ready!",
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.white.withOpacity(0.08),
                  Colors.white.withOpacity(0.05),
                ]),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Colors.white.withOpacity(0.1), width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.cloud_upload_outlined,
                      color: Colors.orange, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Avatar saved! Cloud sync will happen automatically in the background.",
                      style: TextStyle(fontSize: 11, color: Colors.white54),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isLoading = false);
              authViewModel.checkForRedirect(context, clearStack: true);
            },
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient:
                LinearGradient(colors: [primaryColor2, primaryColor2]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "Let's Go!",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String filePath) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: primaryColor2, size: 30),
            const SizedBox(width: 10),
            const Text("Avatar Updated",
                style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Your avatar has been updated!",
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.white.withOpacity(0.08),
                  Colors.white.withOpacity(0.05),
                ]),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Colors.white.withOpacity(0.1), width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.cloud_upload_outlined,
                      color: Colors.orange, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Cloud sync will happen automatically.",
                      style: TextStyle(fontSize: 11, color: Colors.white54),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
            const Text("Done", style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  // =============================================
  // ERROR
  // =============================================

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
      ),
    );
  }

  // =============================================
  // BUILD UI
  // =============================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            children: [
              // Header
              SafeArea(
                child: Padding(
                  padding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                  child: Row(
                    children: [
                      // Back button
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            Colors.white.withOpacity(0.08),
                            Colors.white.withOpacity(0.05),
                          ]),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.1), width: 1),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(12.r),
                            child: Padding(
                              padding: EdgeInsets.all(10.r),
                              child: Icon(Icons.arrow_back_ios_new,
                                  color: Colors.white, size: 20.r),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      // Title
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("3D Avatar",
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            SizedBox(height: 2.h),
                            Text(
                              widget.isProfile
                                  ? "Update your 3D avatar"
                                  : "Create your 3D avatar",
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.white60),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 50.h),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 20.h),
                      _buildAvatarIcon(),
                      SizedBox(height: 40.h),
                      _buildInfoCard(),
                      SizedBox(height: 32.h),
                      _buildCreateButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Loading overlay
          if (_isLoading || _isDownloading)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor2),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      _statusMessage.isNotEmpty
                          ? _statusMessage
                          : _isDownloading
                          ? "Processing your Avatar..."
                          : "Opening Avatar Creator...",
                      style:
                      const TextStyle(fontSize: 16, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (_isDownloading) ...[
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: _downloadProgress,
                          minHeight: 8,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor:
                          AlwaysStoppedAnimation<Color>(primaryColor2),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarIcon() {
    return Container(
      width: 120.w,
      height: 120.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          primaryColor2.withOpacity(0.2),
          primaryColor2.withOpacity(0.1),
        ]),
        borderRadius: BorderRadius.circular(60.r),
        border:
        Border.all(color: primaryColor2.withOpacity(0.3), width: 2),
      ),
      child: Icon(
        widget.gender.toLowerCase() == 'male' ? Icons.man : Icons.woman,
        size: 60.r,
        color: primaryColor2,
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          Colors.white.withOpacity(0.08),
          Colors.white.withOpacity(0.05),
        ]),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
            color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: primaryColor2, size: 24.r),
          SizedBox(width: 12.w),
          const Expanded(
            child: Text(
              "The clearer the picture you take, the better the avatar result (Good lighting and steady hands lead to great avatars)",
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return Container(
      width: double.infinity,
      height: 52.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor2, primaryColor2],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _openAvaturnInBrowser,
          borderRadius: BorderRadius.circular(12.r),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.open_in_browser,
                    color: Colors.white, size: 20.r),
                SizedBox(width: 8.w),
                Text(
                  widget.isProfile
                      ? "Open Avatar Creator"
                      : "Create Avatar",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}













/*

class AvatarCreatorScreen extends StatefulWidget {
  final String gender;
  final bool isProfile;

  const AvatarCreatorScreen({super.key, required this.gender, required this.isProfile});

  @override
  _AvatarCreatorScreenState createState() => _AvatarCreatorScreenState();
}

class _AvatarCreatorScreenState extends State<AvatarCreatorScreen> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  String? _avatarUrl;
  String? _savedFilePath;
  bool _isLoading = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  final Dio _dio = Dio();
  bool _hasCheckedExistingAvatar = false;
  bool _hasHandledInitialLink = false;
  String? _lastProcessedUrl;

  @override
  void initState() {
    super.initState();
    _checkExistingAvatar();
    _initDeepLinks();
    _createAvatarDirectory();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  // Check if avatar already exists
  Future<void> _checkExistingAvatar() async {
    try {
      final String avatarDirPath = await _createAvatarDirectory();
      final String fileName = '${widget.gender.toLowerCase()}.glb';
      final String filePath = '$avatarDirPath/$fileName';

      final file = File(filePath);
      if (await file.exists()) {
        setState(() {
          _savedFilePath = filePath;
          _hasCheckedExistingAvatar = true;
        });
        print("Existing avatar found: $filePath");
      } else {
        setState(() {
          _hasCheckedExistingAvatar = true;
        });
        print("No existing avatar found");
      }
    } catch (e) {
      print("Error checking existing avatar: $e");
      setState(() {
        _hasCheckedExistingAvatar = true;
      });
    }
  }

  // Initialize deep links
  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Handle links when app is already running
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      print("Received deep link (stream): $uri");
      _handleDeepLink(uri, isInitialLink: false);
    });

    // Handle the initial link if app was opened via deep link
    try {
      final uri = await _appLinks.getInitialAppLink();
      if (uri != null && !_hasHandledInitialLink) {
        print("Initial deep link: $uri");
        // Wait for existing avatar check before handling deep link
        await Future.delayed(Duration(milliseconds: 500));
        if (_hasCheckedExistingAvatar && mounted) {
          _handleDeepLink(uri, isInitialLink: true);
          _hasHandledInitialLink = true;
        }
      }
    } catch (e) {
      print("Error getting initial link: $e");
    }
  }

  void _handleDeepLink(Uri uri, {bool isInitialLink = false}) {
    // Extract the GLB URL from the deep link
    if (uri.queryParameters.containsKey('url')) {
      final newAvatarUrl = uri.queryParameters['url'];

      print("Processing deep link URL: $newAvatarUrl");
      print("Last processed URL: $_lastProcessedUrl");
      print("Saved file path: $_savedFilePath");
      print("Is initial link: $isInitialLink");
      print("Is profile mode: ${widget.isProfile}");

      // Skip if we've already processed this exact URL
      if (_lastProcessedUrl == newAvatarUrl) {
        print("Already processed this URL, skipping");
        return;
      }

      // For initial links in profile mode, skip if we already have a saved avatar
      if (isInitialLink && widget.isProfile && _savedFilePath != null) {
        print("Initial link but avatar already exists in profile mode, skipping download");
        _lastProcessedUrl = newAvatarUrl;
        return;
      }

      // Only download if it's a new URL and no download is in progress
      if (!_isDownloading) {
        setState(() {
          _avatarUrl = newAvatarUrl;
        });
        _lastProcessedUrl = newAvatarUrl;
        _downloadAndSaveAvatar(_avatarUrl!);
      } else {
        print("Download already in progress, skipping");
      }
    }
  }

  Future<String> _createAvatarDirectory() async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final Directory avatarDir = Directory('${appDocDir.path}/avatars');

    if (!await avatarDir.exists()) {
      await avatarDir.create(recursive: true);
      print("Avatar directory created: ${avatarDir.path}");
    }

    return avatarDir.path;
  }

  Future<void> _openAvaturnInBrowser() async {
    setState(() {
      _isLoading = true;
    });

    final String customPageUrl = "https://optimus-prime-cd.github.io/sag/index.html";
    final Uri uri = Uri.parse(customPageUrl);

    try {
      bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      setState(() {
        _isLoading = false;
      });

      if (!launched) {
        _showError("Could not open avatar creator");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError("Error: $e");
    }
  }

  Future<void> _deleteAllExistingAvatars() async {
    try {
      final String avatarDirPath = await _createAvatarDirectory();
      final Directory avatarDir = Directory(avatarDirPath);

      if (await avatarDir.exists()) {
        final List<FileSystemEntity> files = avatarDir.listSync();
        for (var file in files) {
          if (file.path.endsWith('.glb')) {
            await file.delete();
            print("Deleted existing avatar: ${file.path}");
          }
        }
      }
    } catch (e) {
      print("Error deleting existing avatars: $e");
    }
  }

  Future<void> _downloadAndSaveAvatar(String url) async {
    // Prevent duplicate downloads
    if (_isDownloading) {
      print("Download already in progress, skipping");
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      await _deleteAllExistingAvatars();
      final String avatarDirPath = await _createAvatarDirectory();
      final String fileName = '${widget.gender.toLowerCase()}.glb';
      final String filePath = '$avatarDirPath/$fileName';

      print("Downloading avatar from: $url");
      print("Saving to: $filePath");

      await _dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress = received / total;
            });
            print("Download progress: ${(received / total * 100).toStringAsFixed(0)}%");
          }
        },
      );

      setState(() {
        _savedFilePath = filePath;
        _isDownloading = false;
        _downloadProgress = 1.0;
      });

      print("Avatar saved successfully at: $filePath");

      // Only show dialog if widget is still mounted
      if (mounted) {
        // If coming from signup (not profile), handle authentication
        if (!widget.isProfile) {
          await _handleSignupFlow(filePath);
        } else {
          // Profile mode - just show success dialog
          _showSuccessDialog(filePath);
        }
      }

    } catch (e) {
      setState(() {
        _isDownloading = false;
      });
      print("Error downloading avatar: $e");
      if (mounted) {
        _showError("Failed to download avatar: $e");
      }
    }
  }

  // NEW METHOD: Handle signup flow (sign in + push to Firestore)
  Future<void> _handleSignupFlow(String filePath) async {
    try {
      // Get the AuthViewModel
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

      // Update loading message
      setState(() {
        _isLoading = true;
      });

      // Sign in anonymously
      await authViewModel.signInAnonymously();



      if (authViewModel.user != null) {

        final uid = authViewModel.user!.uid;
        await _saveFcmToken(uid);

        // Avatar is already saved, now navigate
        _showSuccessDialogAndNavigate(filePath, authViewModel);
      } else {
        setState(() {
          _isLoading = false;
        });
        _showError("Failed to complete signup. Please try again.");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("Error in signup flow: $e");
      _showError("Failed to complete signup: $e");
    }
  }


  Future<void> _saveFcmToken(String uid) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();

      if (token == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({
        'fcmToken': token,
      }, SetOptions(merge: true));

      // Listen for token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update({'fcmToken': newToken});
      });
    } catch (e) {
      debugPrint("FCM token save failed: $e");
    }
  }






  void _showSuccessDialogAndNavigate(String filePath, AuthViewModel authViewModel) {
    final String fileName = '${widget.gender.toLowerCase()}.glb';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: primaryColor2, size: 30),
            SizedBox(width: 10),
            Text(
              "Welcome!",
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Your account and avatar are ready!",
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 15),
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.08),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    "Your avatar has been created successfully. Let's get started!",
                    style: TextStyle(fontSize: 12, color: Colors.white54),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              setState(() {
                _isLoading = false;
              });
              // Navigate using checkForRedirect
              authViewModel.checkForRedirect(context,clearStack: true);
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor2, primaryColor2],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Continue",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String filePath) {
    final String fileName = '${widget.gender.toLowerCase()}.glb';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: primaryColor2, size: 30),
            SizedBox(width: 10),
            Text(
              "Avatar Updated",
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Your custom avatar has been updated successfully!",
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 15),
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.08),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    "Your avatar has been saved. Take a look!",
                    style: TextStyle(fontSize: 10, color: Colors.white54),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text("Close", style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  String _getFileSize(String filePath) {
    try {
      final file = File(filePath);
      final bytes = file.lengthSync();
      if (bytes < 1024) return "$bytes B";
      if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(2)} KB";
      return "${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB";
    } catch (e) {
      return "Unknown";
    }
  }

  Future<List<FileSystemEntity>> _getSavedAvatars() async {
    final String avatarDirPath = await _createAvatarDirectory();
    final Directory avatarDir = Directory(avatarDirPath);

    if (await avatarDir.exists()) {
      return avatarDir.listSync().where((file) => file.path.endsWith('.glb')).toList();
    }
    return [];
  }

  void _showSavedAvatars() async {
    final avatars = await _getSavedAvatars();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        title: Text("Saved Avatars", style: TextStyle(color: Colors.white)),
        content: Container(
          width: double.maxFinite,
          child: avatars.isEmpty
              ? Center(
            child: Text(
              "No avatars saved yet",
              style: TextStyle(color: Colors.white60),
            ),
          )
              : ListView.builder(
            shrinkWrap: true,
            itemCount: avatars.length,
            itemBuilder: (context, index) {
              final file = avatars[index];
              final fileName = file.path.split('/').last;
              return Container(
                margin: EdgeInsets.only(bottom: 8.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.08),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: ListTile(
                  leading: Icon(Icons.insert_drive_file, color: primaryColor2),
                  title: Text(fileName, style: TextStyle(color: Colors.white)),
                  subtitle: Text(
                    _getFileSize(file.path),
                    style: TextStyle(color: Colors.white60),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      File(file.path).deleteSync();
                      Navigator.pop(context);
                      setState(() {
                        _savedFilePath = null;
                        _lastProcessedUrl = null;
                      });
                      _showSavedAvatars();
                    },
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    print("Selected avatar: ${file.path}");
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close", style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            children: [
              // Custom Header with Back Button
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                  child: Row(
                    children: [
                      // Back Button
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.08),
                              Colors.white.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(12.r),
                            child: Padding(
                              padding: EdgeInsets.all(10.r),
                              child: Icon(
                                Icons.arrow_back_ios_new,
                                color: Colors.white,
                                size: 20.r,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      // Title and Subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "3D Avatar",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              widget.isProfile
                                  ? "Update your 3D avatar"
                                  : "Create your 3D avatar",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.normal,
                                color: Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 50.h),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 20.h),
                      _buildAvatarIcon(),
                      SizedBox(height: 40.h),
                      _buildInfoCard(),
                      SizedBox(height: 32.h),
                      _buildCreateButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_isLoading || _isDownloading)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor2),
                  ),
                  SizedBox(height: 20),
                  Text(
                    _isDownloading
                        ? "Processing your Avatar... ${(_downloadProgress * 100).toStringAsFixed(0)}%"
                        : widget.isProfile
                        ? "Opening Avatar Creator..."
                        : "Setting up your account...",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  if (_isDownloading) ...[
                    SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: LinearProgressIndicator(
                        value: _downloadProgress,
                        minHeight: 8,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor2),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarIcon() {
    return Container(
      width: 120.w,
      height: 120.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor2.withOpacity(0.2),
            primaryColor2.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(60.r),
        border: Border.all(
          color: primaryColor2.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Icon(
        widget.gender.toLowerCase() == 'male' ? Icons.man : Icons.woman,
        size: 60.r,
        color: primaryColor2,
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: primaryColor2, size: 24.r),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              "The clearer the picture you take, the better the avatar result (Good lighting and steady hands lead to great avatars)",
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return Container(
      width: double.infinity,
      height: 52.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor2, primaryColor2],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _openAvaturnInBrowser,
          borderRadius: BorderRadius.circular(12.r),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.open_in_browser, color: Colors.white, size: 20.r),
                SizedBox(width: 8.w),
                Text(
                  widget.isProfile ? "Open Avatar Creator" : "Create Avatar",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}




*/









































