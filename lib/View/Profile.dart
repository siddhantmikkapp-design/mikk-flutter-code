import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mikk/Demo/AvatarDashBoard.dart';
import 'package:mikk/Model/SearchModel.dart';

import 'package:mikk/Model/UserProfileModel.dart';
import 'package:mikk/Model/auth/UserNameModel.dart';
import 'package:mikk/View/SettingsScreen.dart';
import 'package:mikk/View/UnityChatScreen.dart';
import 'package:mikk/View_Model/SettingsDetailViewModel/PersonalInformationViewModel.dart';
import 'package:mikk/resources/Custom_InkWell.dart';
import 'package:mikk/resources/GradientBorder.dart';
import 'package:mikk/utils/CommonMethods.dart';
import 'package:mikk/utils/LogHelper.dart';
import 'package:mikk/values/ImageUrl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../Demo/MessageClass.dart';
import '../Demo/avatar_viewer.dart';
import '../Model/auth/SignUpModel.dart';
import '../View_Model/Chat/DatabaseService.dart';
import '../View_Model/Chat/FirestoreChatService.dart';
import '../View_Model/FollowerFollowingViewModel.dart';
import '../View_Model/ProfileViewModel.dart';
import '../resources/TextWidget.dart';
import '../resources/loader.dart';

import '../values/AppFontStyleAndSize.dart';
import '../values/Color.dart';
import '../values/StaticText.dart';
import 'AvatarCreator/AvatarCreatorScreen.dart';
import 'chat_screen.dart';


class Profile extends StatefulWidget {
  final SearchModel? user;
  final VoidCallback? onBackToHome;

  const Profile({super.key, this.user, this.onBackToHome});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> with SingleTickerProviderStateMixin {
  double screenHeight = 0.0;
  double screenWidth = 0.0;

  String viewerUrl = "";
  HttpServer? _localServer;
  bool isLoadingServer = true;
  String avatarUrl = "";
  String mineURL = "";


  final DraggableScrollableController _dragController = DraggableScrollableController();
  bool _isWebViewFullScreen = false;
  late AnimationController _zoomAnimationController;

  // Dark theme colors
  final Color darkBg = const Color(0xFF0A0A0A);
  final Color darkCard = const Color(0xFF1E1E1E);
  final Color darkBorder = const Color(0xFF2A2A2A);


  @override
  void initState() {
    super.initState();
    _zoomAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    loadProfile();
  }

  @override
  void dispose() {
    _localServer?.close();
    _dragController.dispose();
    _zoomAnimationController.dispose();
    super.dispose();
  }

  void _toggleWebViewFullScreen() {
    setState(() {
      _isWebViewFullScreen = !_isWebViewFullScreen;
    });

    if (_isWebViewFullScreen) {
      _zoomAnimationController.forward();
    } else {
      _zoomAnimationController.reverse();
    }
  }

  Future<void> loadProfile() async {
    if (!mounted) return;

    final profileVM = Provider.of<ProfileViewModel>(context, listen: false);

    // Get current user ID or passed user ID
    String userId = widget.user?.userId ?? FirebaseAuth.instance.currentUser?.uid ?? "";

    if (userId.isNotEmpty) {
      await profileVM.getUserProfile(userId: userId);
    }

    if(profileVM.isOwnProfile){
      avatarUrl = profileVM.currentUser!.modelURL.toString();
      mineURL = profileVM.currentUser!.modelURL.toString();

      await _loadProfileAvatar(avatarUrl);


  //    await _startLocalServerForGLB(userId,profileVM);
    } else {

      avatarUrl = profileVM.profileUser!.modelURL.toString();
      mineURL = profileVM.currentUser!.modelURL.toString();

      await _loadProfileAvatar(avatarUrl);

      /* setState(() {
        avatarUrl = profileVM.currentUser!.id.toString();
        viewerUrl = "";
        isLoadingServer = false;
      });*/
    }










  }

  Future<void> _startLocalServerForGLB(String userId, ProfileViewModel profileVM) async {
    setState(() {
      isLoadingServer = true;
    });

    try {
      // Get app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final avatarFile = File('${directory.path}/avatars/${profileVM.currentUser?.gender}.glb');

      LogHelper("🔍 Looking for avatar at: ${avatarFile.path}");

      // Check if avatar exists
      if (!await avatarFile.exists()) {
        LogHelper("❌ Avatar file not found");
        setState(() {
          viewerUrl = "";
          isLoadingServer = false;
        });
        return;
      }

      LogHelper("✅ Avatar file found: ${avatarFile.path}");
      final fileSize = await avatarFile.length();
      LogHelper("📦 File size: ${(fileSize / 1024).toStringAsFixed(2)} KB");

      // Close existing server if any
      await _localServer?.close();

      // Start local HTTP server
      _localServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final port = _localServer!.port;

      LogHelper("🌐 Local server started on port: $port");

      // Handle HTTP requests - ONLY serve GLB file
      _localServer!.listen((HttpRequest request) async {
        try {
          final path = request.uri.path;
          LogHelper("📥 HTTP Request: $path");

          // Only serve GLB files
          if (path.endsWith('.glb') || path.contains('avatar')) {
            if (await avatarFile.exists()) {
              // Set CORS headers for WebView
              request.response.headers.set('Access-Control-Allow-Origin', '*');
              request.response.headers.set('Access-Control-Allow-Methods', 'GET');
              request.response.headers.set('Access-Control-Allow-Headers', '*');
              request.response.headers.set('Content-Type', 'model/gltf-binary');
              request.response.headers.set('Cache-Control', 'no-cache');

              // Stream file to response
              await avatarFile.openRead().pipe(request.response);

              LogHelper("✅ GLB file served successfully");
            } else {
              request.response.statusCode = HttpStatus.notFound;
              request.response.write('Avatar file not found');
              await request.response.close();
              LogHelper("❌ Avatar file not found");
            }
          } else {
            request.response.statusCode = HttpStatus.notFound;
            request.response.write('Not found');
            await request.response.close();
          }
        } catch (e) {
          LogHelper("❌ Server error: $e");
          request.response.statusCode = HttpStatus.internalServerError;
          request.response.write('Server error');
          await request.response.close();
        }
      });

      // Build the viewer URL with only modelUrl parameter
      final modelUrl = 'http://127.0.0.1:$port/avatar.glb';
      final encodedModelUrl = Uri.encodeComponent(modelUrl);

      setState(() {
        viewerUrl = 'https://optimus-prime-cd.github.io/readyplayerme-viewer/?modelUrl=$encodedModelUrl';
        isLoadingServer = false;
      });

      LogHelper("✅ Viewer URL: $viewerUrl");
    } catch (e) {
      LogHelper("❌ Error starting server: $e");
      setState(() {
        viewerUrl = "";
        isLoadingServer = false;
      });
    }
  }



  Future<void> _loadOtherUserAvatar(ProfileViewModel profileVM) async {
    setState(() {
      isLoadingServer = true;
    });

    try {
      // Get avatar URL from profileUser (stored in Firestore)
      final avatarUrl = "https://github.com/siddhantmikkapp-design/mike-asset/releases/download/version1/male.glb";

      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        // Load from hosted URL (Firebase Storage or Ready Player Me)
        final encodedUrl = Uri.encodeComponent(avatarUrl);

        setState(() {
          viewerUrl = 'https://optimus-prime-cd.github.io/readyplayerme-viewer/?modelUrl=$encodedUrl';
          isLoadingServer = false;
        });

        LogHelper("✅ Loading other user's avatar from URL: $avatarUrl");
      } else {
        // No avatar URL found
        setState(() {
          viewerUrl = "";
          isLoadingServer = false;
        });

        LogHelper("ℹ️ User has no avatar URL");
      }
    } catch (e) {
      LogHelper("❌ Error loading other user avatar: $e");
      setState(() {
        viewerUrl = "";
        isLoadingServer = false;
      });
    }
  }



  Future<void> _pickAndUploadProfileImage(ProfileViewModel profileVM) async {
    try {




      // Pick image from gallery
      final ImagePicker picker = ImagePicker();
      final XFile? pickedImage = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedImage == null) {
        LogHelper("No image selected");
        return;
      }

      // Show loading
      setState(() {
        isLoadingServer = true;
      });

      // Get current user ID
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) {
        CommonMethods.showToast("User not logged in");
        setState(() {
          isLoadingServer = false;
        });
        return;
      }

      // Upload to Firebase Storage
      final File imageFile = File(pickedImage.path);
      final String fileName = 'profile_${currentUserId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child(fileName);

      // Upload file
      final UploadTask uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Show upload progress (optional)
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        LogHelper("Upload progress: ${progress.toStringAsFixed(2)}%");
      });

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      LogHelper("✅ Image uploaded successfully: $downloadUrl");

      // ═══════════════════════════════════════════════════════════════
      // 1. Update main user profile in Firestore
      // ═══════════════════════════════════════════════════════════════
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .update({'profilePic': downloadUrl});

      LogHelper("✅ Updated main user profile");

      // ═══════════════════════════════════════════════════════════════
      // 2. Update profile photo in all conversations (Firestore)
      // ═══════════════════════════════════════════════════════════════
      try {
        LogHelper("🔄 Updating profile photo in all conversations...");

        await _updateProfilePicInAllConversations(
          currentUserId: currentUserId,
          newProfilePicUrl: downloadUrl,
        );

      } catch (chatError) {
        LogHelper("⚠️ Error updating conversations (non-critical): $chatError");
        // Don't throw error here, as the main profile update was successful
      }

      // Refresh profile data
      await profileVM.getUserProfile(userId: currentUserId);

      CommonMethods.showToast("Profile picture updated successfully!");

      setState(() {
        isLoadingServer = false;
      });

    } catch (e) {
      LogHelper("❌ Error uploading profile image: $e");
      CommonMethods.showToast("Failed to update profile picture");
      setState(() {
        isLoadingServer = false;
      });
    }
  }

  /// Update profile picture in all conversations where this user appears
  Future<void> _updateProfilePicInAllConversations({
    required String currentUserId,
    required String newProfilePicUrl,
  }) async {
    final firestore = FirebaseFirestore.instance;

    // ═══════════════════════════════════════════════════════════════
    // Step 1: Find all conversations where current user is a participant
    // ═══════════════════════════════════════════════════════════════

    final conversationsSnapshot = await firestore
        .collection('conversations')
        .where('participants', arrayContains: currentUserId)
        .get();

    if (conversationsSnapshot.docs.isEmpty) {
      LogHelper("ℹ️ No conversations found to update");
      return;
    }

    LogHelper("📋 Found ${conversationsSnapshot.docs.length} conversations to update");

    // ═══════════════════════════════════════════════════════════════
    // Step 2: For each conversation, update the other user's view
    // ═══════════════════════════════════════════════════════════════

    final batch = firestore.batch();
    int updateCount = 0;

    for (var conversationDoc in conversationsSnapshot.docs) {
      final conversationId = conversationDoc.id;
      final data = conversationDoc.data();
      final participants = List<String>.from(data['participants'] ?? []);

      // Find the other user(s) in this conversation
      for (var oduserId in participants) {
        if (oduserId == currentUserId) continue; // Skip self

        // Update other user's conversation list entry
        // Their view shows MY profile picture
        final otherUserConversationRef = firestore
            .collection('userConversations')
            .doc(oduserId)
            .collection('conversations')
            .doc(conversationId);

        batch.update(otherUserConversationRef, {
          'otherUserProfilePic': newProfilePicUrl,
        });

        updateCount++;
        LogHelper("📝 Queued update for user: $oduserId");
      }
    }

    // ═══════════════════════════════════════════════════════════════
    // Step 3: Execute batch update
    // ═══════════════════════════════════════════════════════════════

    if (updateCount > 0) {
      await batch.commit();
      LogHelper("✅ Updated profile photo in $updateCount conversation entries");
    } else {
      LogHelper("ℹ️ No conversation entries needed updating");
    }
  }

/*  Future<void> _pickAndUploadProfileImage(ProfileViewModel profileVM) async {
    try {
      // Request permission
      final status = await Permission.photos.request();

      if (status.isDenied) {
        CommonMethods.showToast("Permission denied. Please allow access to photos.");
        return;
      }

      if (status.isPermanentlyDenied) {
        CommonMethods.showToast("Permission permanently denied. Please enable in settings.");
        await openAppSettings();
        return;
      }

      // Pick image from gallery
      final ImagePicker picker = ImagePicker();
      final XFile? pickedImage = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedImage == null) {
        LogHelper("No image selected");
        return;
      }

      // Show loading
      setState(() {
        isLoadingServer = true;
      });

      // Get current user ID
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) {
        CommonMethods.showToast("User not logged in");
        setState(() {
          isLoadingServer = false;
        });
        return;
      }

      // Upload to Firebase Storage
      final File imageFile = File(pickedImage.path);
      final String fileName = 'profile_${currentUserId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child(fileName);

      // Upload file
      final UploadTask uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Show upload progress (optional)
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        LogHelper("Upload progress: ${progress.toStringAsFixed(2)}%");
      });

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      LogHelper("✅ Image uploaded successfully: $downloadUrl");

      // Update Firestore with new profile picture URL
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .update({
        'profilePic': downloadUrl});



      try {
        LogHelper("🔄 Updating profile photo in all user rooms...");

        // Get reference to Realtime Database
     //   final DatabaseReference dbRef = FirebaseDatabase.instance.ref();

        final dbService = Provider.of<DatabaseService>(context, listen: false);


        // Get all UserRooms
        DatabaseEvent event = await dbService.baseRef.child('UserRooms').once();

        if (event.snapshot.value != null) {
          Map<dynamic, dynamic> allUserRooms = event.snapshot.value as Map<dynamic, dynamic>;

          // Create batch updates
          Map<String, dynamic> updates = {};
          int updateCount = 0;

          // Iterate through all other users
          allUserRooms.forEach((otherUserId, rooms) {
            if (rooms != null && rooms is Map) {
              // Check if current user exists in this other user's rooms
              if (rooms.containsKey(currentUserId)) {
                // Update current user's profile pic in this room
                updates['UserRooms/$otherUserId/$currentUserId/profilePic'] = downloadUrl;
                updateCount++;
                LogHelper("📝 Queued update for room: $otherUserId -> $currentUserId");
              }
            }
          });

          // Execute all updates at once
          if (updates.isNotEmpty) {
            await dbService.baseRef.update(updates);
            LogHelper("✅ Updated profile photo in $updateCount user rooms");
          } else {
            LogHelper("ℹ️ No user rooms found to update");
          }
        } else {
          LogHelper("ℹ️ No UserRooms exist yet");
        }
      } catch (chatError) {
        LogHelper("⚠️ Error updating user rooms (non-critical): $chatError");
        // Don't throw error here, as the main profile update was successful
      }







      // Refresh profile data
      await profileVM.getUserProfile(userId: currentUserId);












      CommonMethods.showToast("Profile picture updated successfully!");

      setState(() {
        isLoadingServer = false;
      });

    } catch (e) {
      LogHelper("❌ Error uploading profile image: $e");
      CommonMethods.showToast("Failed to update profile picture");
      setState(() {
        isLoadingServer = false;
      });
    }
  }*/



  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: darkBg,
      body: Consumer<ProfileViewModel>(
        builder: (context, profileVM, child) {
          return Stack(
            children: [
              // Main Content
              if (!_isWebViewFullScreen) _buildSplitView(profileVM),

              // Full Screen WebView
              if (_isWebViewFullScreen) _buildFullScreenWebView(profileVM),

              // App Bar (always on top)
              if (!_isWebViewFullScreen) _buildAppBar(profileVM),

              // Loading Overlay
              if (profileVM.isLoading || isLoadingServer)
                Positioned.fill(
                  child: Container(
                    color: Colors.black54,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: primaryColor2),
                          SizedBox(height: 16),
                          TextWidget(
                            txt: isLoadingServer ? "Loading avatar..." : "Loading profile...",
                            fontSize: 14,
                            fontWeight: FontSizeAndWidth.medium,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSplitView(ProfileViewModel profileVM) {
    return Stack(
      children: [
        // WebView - Background
        Positioned.fill(
          child: Container(
            color: Colors.black,
            child: _buildAvatarViewer(),
          ),
        ),

        // Zoom Button on WebView
        Positioned(
          top: MediaQuery.of(context).padding.top + 70,
          right: 15,
          child: GestureDetector(
            onTap: _toggleWebViewFullScreen,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.zoom_out_map,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),

        // Draggable Profile Section
        DraggableScrollableSheet(
          controller: _dragController,
          initialChildSize: 0.5,
          minChildSize: 0.5,
          maxChildSize: 1.0,
          snap: true,
          snapSizes: const [0.5, 1.0],
          builder: (BuildContext context, ScrollController scrollController) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    darkBg,
                    darkBg.withOpacity(0.98),
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Drag Handle
                  GestureDetector(
                    onTap: () {
                      if (_dragController.size < 0.75) {
                        _dragController.animateTo(
                          1.0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOutCubic,
                        );
                      } else {
                        _dragController.animateTo(
                          0.5,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOutCubic,
                        );
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Container(
                          width: 50,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2.5),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Divider
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                  // Profile Content
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProfileHeader(profileVM),
                          const SizedBox(height: 32),
                          _buildActionButton(profileVM),
                          const SizedBox(height: 24),
                          _buildAdditionalContent(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAvatarViewer() {
    if (isLoadingServer) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (viewerUrl.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_circle_outlined,
              size: 80,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            TextWidget(
              txt: "No avatar yet",
              fontSize: 18,
              fontWeight: FontSizeAndWidth.medium,
              color: Colors.white.withOpacity(0.5),
            ),
          ],
        ),
      );
    }

    return AvatarViewerPage(viewerUrl: viewerUrl);
  }

  Widget _buildFullScreenWebView(ProfileViewModel profileVM) {
    return Stack(
      children: [
        // Full Screen WebView
        Positioned.fill(
          child: Container(
            color: Colors.black,
            child: _buildAvatarViewer(),
          ),
        ),

        // Top Controls
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: _toggleWebViewFullScreen,
                        icon: const Icon(Icons.close, color: Colors.white, size: 24),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextWidget(
                        txt: profileVM.profileUser?.id ?? "Profile",
                        fontSize: 16,
                        fontWeight: FontSizeAndWidth.semiBold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Minimize Button
        Positioned(
          bottom: 30,
          right: 20,
          child: GestureDetector(
            onTap: _toggleWebViewFullScreen,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.zoom_in_map,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /*Widget _buildAppBar(ProfileViewModel profileVM) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () => widget.onBackToHome?.call(),
                    icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20.r),
                    padding: EdgeInsets.zero,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: TextWidget(
                    txt: profileVM.profileUser?.id ?? "Loading...",
                    fontSize: 16,
                    fontWeight: FontSizeAndWidth.semiBold,
                    color: Colors.white,
                  ),
                ),
                if (profileVM.isOwnProfile)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () => CommonMethods.goToNext(context, const SettingsScreen()),
                      icon: Icon(Icons.settings_outlined, color: Colors.white, size: 20.r),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: Colors.white, size: 20.r),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      color: darkCard,
                      offset: Offset(0, 50.h),
                      onSelected: (value) {
                        if (value == 'block') {
                          _showBlockDialog(profileVM);
                        } else if (value == 'report') {
                          _showReportDialog(profileVM);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'report',
                          child: Row(
                            children: [
                              Icon(Icons.report_outlined, size: 20.r, color: Colors.white70),
                              SizedBox(width: 12.w),
                              TextWidget(
                                txt: "Report User",
                                fontSize: 14,
                                fontWeight: FontSizeAndWidth.medium,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'block',
                          child: Row(
                            children: [
                              Icon(Icons.block_outlined, size: 20.r, color: Colors.redAccent),
                              SizedBox(width: 12.w),
                              TextWidget(
                                txt: "Block User",
                                fontSize: 14,
                                fontWeight: FontSizeAndWidth.medium,
                                color: Colors.redAccent,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }*/

  void _handleBackNavigation(ProfileViewModel profileVM) {
    // Check if viewing own profile or another user's profile
    if (profileVM.isOwnProfile) {
      // Own profile - use the callback
      widget.onBackToHome?.call();
    } else {
      // Other user's profile - just pop
      Navigator.pop(context);
    }
  }

  Widget _buildAppBar(ProfileViewModel profileVM) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () => _handleBackNavigation(profileVM),
                    icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20.r),
                    padding: EdgeInsets.zero,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: TextWidget(
                    txt: profileVM.profileUser?.id ?? "Loading...",
                    fontSize: 16,
                    fontWeight: FontSizeAndWidth.semiBold,
                    color: Colors.white,
                  ),
                ),
                if (profileVM.isOwnProfile)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () => CommonMethods.goToNext(context, const SettingsScreen()),
                      icon: Icon(Icons.settings_outlined, color: Colors.white, size: 20.r),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: Colors.white, size: 20.r),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      color: darkCard,
                      offset: Offset(0, 50.h),
                      onSelected: (value) {
                        if (value == 'block') {
                          _showBlockDialog(profileVM);
                        } else if (value == 'report') {
                          _showReportDialog(profileVM);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'report',
                          child: Row(
                            children: [
                              Icon(Icons.report_outlined, size: 20.r, color: Colors.white70),
                              SizedBox(width: 12.w),
                              TextWidget(
                                txt: "Report User",
                                fontSize: 14,
                                fontWeight: FontSizeAndWidth.medium,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'block',
                          child: Row(
                            children: [
                              Icon(Icons.block_outlined, size: 20.r, color: Colors.redAccent),
                              SizedBox(width: 12.w),
                              TextWidget(
                                txt: "Block User",
                                fontSize: 14,
                                fontWeight: FontSizeAndWidth.medium,
                                color: Colors.redAccent,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }






  void _showBlockDialog(ProfileViewModel profileVM) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(Icons.block, color: Colors.redAccent, size: 24.r),
            SizedBox(width: 12.w),
            TextWidget(
              txt: "Block User",
              fontSize: 18,
              fontWeight: FontSizeAndWidth.bold,
              color: Colors.white,
            ),
          ],
        ),
        content: TextWidget(
          txt: "Are you sure you want to block ${profileVM.profileUser?.name ?? 'this user'}? They won't be able to find your profile or send you messages.",
          fontSize: 14,
          fontWeight: FontSizeAndWidth.regular,
          color: Colors.white70,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: TextWidget(
              txt: "Cancel",
              fontSize: 14,
              fontWeight: FontSizeAndWidth.semiBold,
              color: Colors.white60,
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Handle block user logic
              Navigator.pop(context);
              _blockUser(profileVM);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: TextWidget(
              txt: "Block",
              fontSize: 14,
              fontWeight: FontSizeAndWidth.semiBold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(ProfileViewModel profileVM) {
    String? selectedReason;
    final reasons = [
      "Spam or fake account",
      "Inappropriate content",
      "Harassment or bullying",
      "Hateful speech",
      "Violence or threats",
      "Other",
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: darkCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Row(
            children: [
              Icon(Icons.report_outlined, color: Colors.orangeAccent, size: 24.r),
              SizedBox(width: 12.w),
              TextWidget(
                txt: "Report User",
                fontSize: 18,
                fontWeight: FontSizeAndWidth.bold,
                color: Colors.white,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextWidget(
                txt: "Why are you reporting ${profileVM.profileUser?.name ?? 'this user'}?",
                fontSize: 14,
                fontWeight: FontSizeAndWidth.regular,
                color: Colors.white70,
              ),
              SizedBox(height: 16.h),
              ...reasons.map((reason) {
                return RadioListTile<String>(
                  title: TextWidget(
                    txt: reason,
                    fontSize: 13,
                    fontWeight: FontSizeAndWidth.medium,
                    color: Colors.white,
                  ),
                  value: reason,
                  groupValue: selectedReason,
                  activeColor: primaryColor2,
                  onChanged: (value) {
                    setState(() {
                      selectedReason = value;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: TextWidget(
                txt: "Cancel",
                fontSize: 14,
                fontWeight: FontSizeAndWidth.semiBold,
                color: Colors.white60,
              ),
            ),
            ElevatedButton(
              onPressed: selectedReason != null
                  ? () {
                Navigator.pop(context);
                _reportUser(profileVM, selectedReason!);
              }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                disabledBackgroundColor: Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: TextWidget(
                txt: "Report",
                fontSize: 14,
                fontWeight: FontSizeAndWidth.semiBold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

// Add these methods to handle block and report actions

  Future<void> _blockUser(ProfileViewModel profileVM) async {
    try {
      if (profileVM.profileUser == null) return;
      final chatService = Provider.of<FirestoreChatService>(context, listen: false);

      await chatService.blockUser(
        profileVM.profileUser!.userId!,
        name: profileVM.profileUser!.name,
        id: profileVM.profileUser!.id,
        profilePic: profileVM.profileUser!.profilePic, // NEW
      );

      CommonMethods.showToast("User blocked successfully");
      widget.onBackToHome?.call();
    } catch (e) {
      LogHelper("Error blocking user: $e");
      CommonMethods.showToast("Failed to block user");
    }
  }


  Future<void> _unblockUser(ProfileViewModel profileVM) async {
    try {
      if (profileVM.profileUser == null) return;
      final chatService = Provider.of<FirestoreChatService>(context, listen: false);
      await chatService.unblockUser(profileVM.profileUser!.userId!);
      CommonMethods.showToast("User unblocked");
    } catch (e) {
      LogHelper("Error unblocking user: $e");
      CommonMethods.showToast("Failed to unblock user");
    }
  }

  void _showUnblockDialog(ProfileViewModel profileVM) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            Icon(Icons.block, color: primaryColor2, size: 24.r),
            SizedBox(width: 12.w),
            TextWidget(txt: "Unblock User", fontSize: 18, fontWeight: FontSizeAndWidth.bold, color: Colors.white),
          ],
        ),
        content: TextWidget(
          txt: "Unblock ${profileVM.profileUser?.name ?? 'this user'}? They'll be able to message you again.",
          fontSize: 14,
          fontWeight: FontSizeAndWidth.regular,
          color: Colors.white70,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: TextWidget(txt: "Cancel", fontSize: 14, fontWeight: FontSizeAndWidth.semiBold, color: Colors.white60),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _unblockUser(profileVM);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            child: TextWidget(txt: "Unblock", fontSize: 14, fontWeight: FontSizeAndWidth.semiBold, color: Colors.white),
          ),
        ],
      ),
    );
  }





  Future<void> _reportUser(ProfileViewModel profileVM, String reason) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null || profileVM.profileUser == null) return;

      // Add to reports collection
      await FirebaseFirestore.instance.collection('reports').add({
        'reportedUserId': profileVM.profileUser!.userId,
        'reportedUserName': profileVM.profileUser!.name,
        'reportedById': currentUser.uid,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      CommonMethods.showToast("Report submitted successfully");
    } catch (e) {
      LogHelper("Error reporting user: $e");
      CommonMethods.showToast("Failed to submit report");
    }
  }


  Widget _buildProfileHeader(ProfileViewModel profileVM) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profile Picture with Edit Icon
        Stack(
          children: [
            // Profile Picture
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                gradient: LinearGradient(
                  colors: [Colors.white.withOpacity(0.09), Colors.white.withOpacity(0.09)],
                ),
              ),
              padding: EdgeInsets.all(3.r),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14.r),
                child: SizedBox(
                  height: 80.h,
                  width: 80.h,
                  child: profileVM.profileUser?.profilePic != null &&
                      profileVM.profileUser!.profilePic!.isNotEmpty
                      ? CachedNetworkImage(
                    imageUrl: profileVM.profileUser!.profilePic!,
                    placeholder: (context, url) => Container(
                      color: darkCard,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Container(
                      color: darkCard,
                      child: Icon(Icons.person, size: 40.r, color: Colors.grey[600]),
                    ),
                  )
                      : Container(
                    color: darkCard,
                    child: Icon(Icons.person, size: 40.r, color: Colors.grey[600]),
                  ),
                ),
              ),
            ),

            // Edit Icon - Only show for own profile
            if (profileVM.isOwnProfile)
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => _pickAndUploadProfileImage(profileVM),
                  child: Container(
                    padding: EdgeInsets.all(6.r),
                    decoration: BoxDecoration(
                      color: primaryColor2,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: darkBg,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 14.r,
                    ),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(width: 16.w),

        // Name and ID
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name
              TextWidget(
                txt: profileVM.profileUser?.name ?? "Unknown User",
                fontSize: 22,
                fontWeight: FontSizeAndWidth.bold,
                color: Colors.white,
              ),
              SizedBox(height: 8.h),

              // ✅ ID Badge is now wrapped in a GestureDetector
              GestureDetector(
                onTap: () {
                  // Get the user ID. If it's null, use an empty string.
                  final String userId = profileVM.profileUser?.id ?? "";

                  // Only copy if the ID is not empty.
                  if (userId.isNotEmpty) {
                    Clipboard.setData(ClipboardData(text: userId));

                    // Show a confirmation message to the user.
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("User ID copied to clipboard"),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: Container( // This is your original Container for the badge
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: primaryColor2.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: primaryColor2.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.badge_outlined,
                        color: primaryColor2,
                        size: 16.r,
                      ),
                      SizedBox(width: 6.w),
                      TextWidget(
                        txt: profileVM.profileUser?.id ?? "N/A",
                        fontSize: 14,
                        fontWeight: FontSizeAndWidth.semiBold,
                        color: primaryColor2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


/*  Widget _buildProfileHeader(ProfileViewModel profileVM) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profile Picture
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            gradient: LinearGradient(
              colors: [primaryColor2, primaryColor2],
            ),
          ),
          padding: EdgeInsets.all(3.r),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14.r),
            child: SizedBox(
              height: 80.h,
              width: 80.h,
              child: profileVM.profileUser?.profilePic != null &&
                  profileVM.profileUser!.profilePic!.isNotEmpty
                  ? CachedNetworkImage(
                imageUrl: profileVM.profileUser!.profilePic!,
                placeholder: (context, url) => Container(
                  color: darkCard,
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(
                  color: darkCard,
                  child: Icon(Icons.person, size: 40.r, color: Colors.grey[600]),
                ),
              )
                  : Container(
                color: darkCard,
                child: Icon(Icons.person, size: 40.r, color: Colors.grey[600]),
              ),
            ),
          ),
        ),
        SizedBox(width: 16.w),

        // Name and ID
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name
              TextWidget(
                txt: profileVM.profileUser?.name ?? "Unknown User",
                fontSize: 22,
                fontWeight: FontSizeAndWidth.bold,
                color: Colors.white,
              ),
              SizedBox(height: 8.h),

              // ID Badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: primaryColor2.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: primaryColor2.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.badge_outlined,
                      color: primaryColor2,
                      size: 16.r,
                    ),
                    SizedBox(width: 6.w),
                    TextWidget(
                      txt: profileVM.profileUser?.id ?? "N/A",
                      fontSize: 14,
                      fontWeight: FontSizeAndWidth.semiBold,
                      color: primaryColor2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }*/

  Widget _buildActionButton(ProfileViewModel profileVM) {
    // Edit Profile button for own profile
    if (profileVM.isOwnProfile) {
      return Container(
        width: double.infinity,
        height: 52.h,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor2, primaryColor2],
          ),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              //   CommonMethods.goToNext(context, const AvatarCreatorScreen());
              gotoAvatarCreatorScreen(profileVM,context);
            },
            borderRadius: BorderRadius.circular(12.r),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit_outlined, color: Colors.white, size: 20.r),
                  SizedBox(width: 8.w),
                  TextWidget(
                    txt: "Edit Avatar",
                    fontSize: 16,
                    fontWeight: FontSizeAndWidth.semiBold,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final chatService = Provider.of<FirestoreChatService>(context);
    final otherId = profileVM.profileUser?.userId ?? '';
    final blocked = chatService.isBlockedSync(otherId);

    if (blocked) {
      return Container(
        width: double.infinity,
        height: 52.h,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.white24),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showUnblockDialog(profileVM), // NEW — tappable now
            borderRadius: BorderRadius.circular(12.r),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.block, color: Colors.white70, size: 20.r),
                  SizedBox(width: 8.w),
                  TextWidget(
                    txt: "Blocked · Tap to Unblock",
                    fontSize: 15,
                    fontWeight: FontSizeAndWidth.semiBold,
                    color: Colors.white70,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }





    // Send Message button for other users
    return Container(
      width: double.infinity,
      height: 52.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor2, primaryColor2],
        ),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navigate to chat/message screen
            // LogHelper("Send message to: ${profileVM.profileUser?.name}");

            gotoChatScreen(profileVM,context);

            // CommonMethods.goToNext(context, ChatScreen(user: profileVM.profileUser));
          },
          borderRadius: BorderRadius.circular(12.r),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.send_outlined, color: Colors.white, size: 20.r),
                SizedBox(width: 8.w),
                TextWidget(
                  txt: "Send Message",
                  fontSize: 16,
                  fontWeight: FontSizeAndWidth.semiBold,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdditionalContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history, size: 18.r, color: primaryColor2),
            SizedBox(width: 8.w),
            TextWidget(
              txt: "Recent Activity",
              fontSize: 16,
              fontWeight: FontSizeAndWidth.bold,
              color: Colors.white,
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: darkCard,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: darkBorder),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.circle, size: 8.r, color: Colors.green),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: TextWidget(
                  txt: "No recent activity",
                  fontSize: 14,
                  fontWeight: FontSizeAndWidth.regular,
                  color: Colors.white60,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }



  /*Future<void> gotoChatScreen(ProfileViewModel profileVM, BuildContext context) async {

    final First_id = profileVM.currentUser?.userId;
    final Second_id = profileVM.profileUser?.userId;

    final String roomname = createRoomName(First_id!, Second_id!);
    final profilepic = profileVM.profileUser?.profilePic ?? "";
    final name = profileVM.profileUser?.name ?? "";
    final mineprofile = profileVM.currentUser?.profilePic ?? "";

    final dbService = Provider.of<DatabaseService>(context, listen: false);
    MessageClass senderModel = MessageClass(
        otherUserId: profileVM.profileUser?.userId,
        name: profileVM.profileUser?.name,
        roomName: roomname,
        profilePic: profilepic
    );


    MessageClass receiverModel = MessageClass(
        otherUserId: profileVM.currentUser?.userId,
        name: profileVM.currentUser?.name,
        roomName: roomname,
        profilePic:mineprofile
    );

    await dbService.updateCurrentUserName(newCurrentUserName: profileVM.currentUser!.name.toString());

      await  dbService.updateReceiverUser(newReceiverUser: senderModel);

        final refUserRoomReceiver = dbService.baseRef.child("UserRooms").child(senderModel.otherUserId.toString()).child(profileVM.currentUser!.userId.toString());
        final refUserRoomSender = dbService.baseRef.child("UserRooms").child(profileVM.currentUser!.userId.toString()).child(senderModel!.otherUserId.toString());

        await refUserRoomReceiver.update(receiverModel.toJson());
        await refUserRoomSender.update(senderModel.toJson());
        CommonMethods.goToNext(context, ChatScreen(receiverUser: senderModel, roomName: roomname,avatarUrl: avatarUrl,profilePicUrl: profilepic,name:name));








  }

  String createRoomName(String userId1, String oduserId2) {
    final ids = [userId1, oduserId2]..sort();
    return ids[0].substring(0, 3) + ids[1].substring(0, 3);
  }*/

// profile.dart

  Future<void> gotoChatScreen(
      ProfileViewModel profileVM,
      BuildContext context,
      ) async {
    final firstId = profileVM.currentUser?.userId;
    final secondId = profileVM.profileUser?.userId;

    // Validate IDs
    if (firstId == null || secondId == null) {
      debugPrint('❌ Cannot start chat: User IDs are null');
      return;
    }

    final chatService = Provider.of<FirestoreChatService>(context, listen: false);
    if (await chatService.isBlocked(secondId)) {
      CommonMethods.showToast("You can't message this user");
      return;
    }




    final String roomName = createRoomName(firstId, secondId);
    final profilePic = profileVM.profileUser?.profilePic ?? "";
    final name = profileVM.profileUser?.name ?? "";
    final mineProfilePic = profileVM.currentUser?.profilePic ?? "";
    final mineName = profileVM.currentUser?.name ?? "";


    // ✅ Changed: DatabaseService → FirestoreChatService

    // Create message models
    MessageClass senderModel = MessageClass(
      otherUserId: secondId,
      name: name,
      roomName: roomName,
      profilePic: profilePic,
    );

    // Update current user name (for when we send messages)
    await chatService.updateCurrentUserName(
      newCurrentUserName: mineName,
    );

    // Update receiver user
    await chatService.updateReceiverUser(newReceiverUser: senderModel);

    // ✅ NEW: Create/Update conversation in Firestore
    await _createOrUpdateConversation(
      chatService: chatService,
      myUserId: firstId,
      otherUserId: secondId,
      myName: mineName,
      myProfilePic: mineProfilePic,
      otherName: name,
      otherProfilePic: profilePic,
      roomName: roomName,
    );

    // Navigate to chat screen
    CommonMethods.goToNext(
      context,
      UnityChatScreen(
        receiverUser: senderModel,
        roomName: roomName,
        avatarUrl: mineURL, // Your avatar URL variable
        profilePicUrl: profilePic,
        name: name,
      ),
    );
  }

  /// Create or update conversation entries for both users
  Future<void> _createOrUpdateConversation({
    required FirestoreChatService chatService,
    required String myUserId,
    required String otherUserId,
    required String myName,
    required String myProfilePic,
    required String otherName,
    required String otherProfilePic,
    required String roomName,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final conversationId = chatService.createConversationId(myUserId, otherUserId);

    try {
      final batch = firestore.batch();

      // ═══════════════════════════════════════════════════════════════
      // 1. Create/Update main conversation document
      // ═══════════════════════════════════════════════════════════════
      final conversationRef = firestore.collection('conversations').doc(conversationId);

      batch.set(
        conversationRef,
        {
          'participants': [myUserId, otherUserId],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'roomName': roomName,
        },
        SetOptions(merge: true),
      );

      // ═══════════════════════════════════════════════════════════════
      // 2. Create/Update MY conversation list entry
      // ═══════════════════════════════════════════════════════════════
      final myConversationRef = firestore
          .collection('userConversations')
          .doc(myUserId)
          .collection('conversations')
          .doc(conversationId);

      batch.set(
        myConversationRef,
        {
          'otherUserId': otherUserId,
          'otherUserName': otherName,
          'otherUserProfilePic': otherProfilePic,
          'roomName': roomName,
          'lastMessage': '', // Empty until first message
          'lastMessageTime': FieldValue.serverTimestamp(),
          'isRead': true,
          'unreadCount': 0,
        },
        SetOptions(merge: true),
      );

      // ═══════════════════════════════════════════════════════════════
      // 3. Create/Update OTHER USER's conversation list entry
      // ═══════════════════════════════════════════════════════════════
      final otherConversationRef = firestore
          .collection('userConversations')
          .doc(otherUserId)
          .collection('conversations')
          .doc(conversationId);

      batch.set(
        otherConversationRef,
        {
          'otherUserId': myUserId,
          'otherUserName': myName,
          'otherUserProfilePic': myProfilePic,
          'roomName': roomName,
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'isRead': true,
          'unreadCount': 0,
        },
        SetOptions(merge: true),
      );

      await batch.commit();
      debugPrint('✅ Conversation created/updated: $conversationId');
    } catch (e) {
      debugPrint('❌ Error creating conversation: $e');
    }
  }

  /// Create consistent room name from two user IDs
  String createRoomName(String oduserId1, String oduserId2) {
    final ids = [oduserId1, oduserId2]..sort();
    return ids[0].substring(0, 3) + ids[1].substring(0, 3);
  }


  void gotoAvatarCreatorScreen(ProfileViewModel profileVM, BuildContext context) {

    var gender = profileVM.currentUser?.gender ?? '';

    CommonMethods.goToNext(context, const AvatarDashBoard(isInitialScreen: false,));






  }

Future<void>_loadProfileAvatar(String avatarUrl) async {
  setState(() {
    isLoadingServer = true;
  });

  try {
    // Get avatar URL from profileUser (stored in Firestore)

    if (avatarUrl.isNotEmpty) {
      // Load from hosted URL (Firebase Storage or Ready Player Me)
      final encodedUrl = Uri.encodeComponent(avatarUrl);


      setState(() {
        viewerUrl = 'https://optimus-prime-cd.github.io/minus/?modelUrl=$encodedUrl';
        isLoadingServer = false;
      });

      LogHelper("✅ Loading other user's avatar from URL: $avatarUrl");
    } else {
      // No avatar URL found
      setState(() {
        viewerUrl = "";
        isLoadingServer = false;
      });

      LogHelper("ℹ️ User has no avatar URL");
    }
  } catch (e) {
    LogHelper("❌ Error loading other user avatar: $e");
    setState(() {
      viewerUrl = "";
      isLoadingServer = false;
    });
  }


}







 }














/*

class Profile extends StatefulWidget {
  final SearchModel? user; // User to view (if null, show own profile)
  final VoidCallback? onBackToHome;

  const Profile({super.key, this.user, this.onBackToHome});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> with SingleTickerProviderStateMixin {
  double screenHeight = 0.0;
  double screenWidth = 0.0;

  final String user = "https://models.readyplayer.me/6813614e7d3bdc863ca281a6.glb";

  String viewerUrl = "";
  String avatarUrl = "";

  final DraggableScrollableController _dragController = DraggableScrollableController();
  bool _isWebViewFullScreen = false;
  late AnimationController _zoomAnimationController;

  // Dark theme colors
  final Color darkBg = const Color(0xFF0A0A0A);
  final Color darkCard = const Color(0xFF1E1E1E);
  final Color darkBorder = const Color(0xFF2A2A2A);

  @override
  void initState() {
    super.initState();
    _zoomAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    loadProfile();
  }

  @override
  void dispose() {
    _dragController.dispose();
    _zoomAnimationController.dispose();
    super.dispose();
  }

  void _toggleWebViewFullScreen() {
    setState(() {
      _isWebViewFullScreen = !_isWebViewFullScreen;
    });

    if (_isWebViewFullScreen) {
      _zoomAnimationController.forward();
    } else {
      _zoomAnimationController.reverse();
    }
  }

  Future<void> loadProfile() async {
    if (!mounted) return;

    final profileVM = Provider.of<ProfileViewModel>(context, listen: false);

    // Get current user ID or passed user ID
    String userId = widget.user?.userId ?? FirebaseAuth.instance.currentUser?.uid ?? "";

    if (userId.isNotEmpty) {
      await profileVM.getUserProfile(userId: userId);
    }

    // Load avatar URL (you can add this to UserModel if needed)
    viewerUrl = Uri.encodeFull(
      'https://optimus-prime-cd.github.io/readyplayerme-viewer/?modelUrl=https://models.readyplayer.me/682e1240092177c0ba355fde.glb',
    );
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: darkBg,
      body: Consumer<ProfileViewModel>(
        builder: (context, profileVM, child) {
          return Stack(
            children: [
              // Main Content
              if (!_isWebViewFullScreen) _buildSplitView(profileVM),

              // Full Screen WebView
              if (_isWebViewFullScreen) _buildFullScreenWebView(profileVM),

              // App Bar (always on top)
              if (!_isWebViewFullScreen) _buildAppBar(profileVM),

              // Loading Overlay
              if (profileVM.isLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black54,
                    child: Center(
                      child: CircularProgressIndicator(color: primaryColor2),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSplitView(ProfileViewModel profileVM) {
    return Stack(
      children: [
        // WebView - Background
        Positioned.fill(
          child: Container(
            color: Colors.black,
            child: viewerUrl.isNotEmpty
                ? AvatarViewerPage(viewerUrl: viewerUrl)
                : const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
        ),

        // Zoom Button on WebView
        Positioned(
          top: MediaQuery.of(context).padding.top + 70,
          right: 15,
          child: GestureDetector(
            onTap: _toggleWebViewFullScreen,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.zoom_out_map,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),

        // Draggable Profile Section
        DraggableScrollableSheet(
          controller: _dragController,
          initialChildSize: 0.5,
          minChildSize: 0.5,
          maxChildSize: 1.0,
          snap: true,
          snapSizes: const [0.5, 1.0],
          builder: (BuildContext context, ScrollController scrollController) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    darkBg,
                    darkBg.withOpacity(0.98),
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Drag Handle
                  GestureDetector(
                    onTap: () {
                      if (_dragController.size < 0.75) {
                        _dragController.animateTo(
                          1.0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOutCubic,
                        );
                      } else {
                        _dragController.animateTo(
                          0.5,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOutCubic,
                        );
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Container(
                          width: 50,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2.5),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Divider
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                  // Profile Content
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProfileHeader(profileVM),
                          const SizedBox(height: 32),
                          _buildActionButton(profileVM),
                          const SizedBox(height: 24),
                          _buildAdditionalContent(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFullScreenWebView(ProfileViewModel profileVM) {
    return Stack(
      children: [
        // Full Screen WebView
        Positioned.fill(
          child: Container(
            color: Colors.black,
            child: viewerUrl.isNotEmpty
                ? AvatarViewerPage(viewerUrl: viewerUrl)
                : const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
        ),

        // Top Controls
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: _toggleWebViewFullScreen,
                        icon: const Icon(Icons.close, color: Colors.white, size: 24),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextWidget(
                        txt: profileVM.profileUser?.id ?? "Profile",
                        fontSize: 16,
                        fontWeight: FontSizeAndWidth.semiBold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Minimize Button
        Positioned(
          bottom: 30,
          right: 20,
          child: GestureDetector(
            onTap: _toggleWebViewFullScreen,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.zoom_in_map,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(ProfileViewModel profileVM) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () => widget.onBackToHome?.call(),
                    icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20.r),
                    padding: EdgeInsets.zero,
                  ),
                ),

                // User ID at top
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: TextWidget(
                    txt: profileVM.profileUser?.id ?? "Loading...",
                    fontSize: 16,
                    fontWeight: FontSizeAndWidth.semiBold,
                    color: Colors.white,
                  ),
                ),

                // Settings (own profile) OR Three-dot menu (other user)
                if (profileVM.isOwnProfile)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () => CommonMethods.goToNext(context, const SettingsScreen()),
                      icon: Icon(Icons.settings_outlined, color: Colors.white, size: 20.r),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: Colors.white, size: 20.r),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      color: darkCard,
                      offset: Offset(0, 50.h),
                      onSelected: (value) {
                        if (value == 'block') {
                          _showBlockDialog(profileVM);
                        } else if (value == 'report') {
                          _showReportDialog(profileVM);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'report',
                          child: Row(
                            children: [
                              Icon(Icons.report_outlined, size: 20.r, color: Colors.white70),
                              SizedBox(width: 12.w),
                              TextWidget(
                                txt: "Report User",
                                fontSize: 14,
                                fontWeight: FontSizeAndWidth.medium,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'block',
                          child: Row(
                            children: [
                              Icon(Icons.block_outlined, size: 20.r, color: Colors.redAccent),
                              SizedBox(width: 12.w),
                              TextWidget(
                                txt: "Block User",
                                fontSize: 14,
                                fontWeight: FontSizeAndWidth.medium,
                                color: Colors.redAccent,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }*/

// Add these dialog methods to your _ProfileState class






/*
class Profile extends StatefulWidget {
  final UserNameModel? user;
  final bool? isRequestSent;
  final VoidCallback? onBackToHome;
  const Profile({super.key, this.user, this.isRequestSent = false, this.onBackToHome});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> with SingleTickerProviderStateMixin {
  double screenHeight = 0.0;
  double screenWidth = 0.0;

  final String postername = "your_poster_url_here";
  final String user = "https://models.readyplayer.me/6813614e7d3bdc863ca281a6.glb";
  bool isLightTheme = true;
  SignUpModel? userData;
  bool isLoading = true;

  String profileBtnStatus = "";
  String viewerUrl = "";
  String avatarUrl = "";
  String profilePic = "";
  UserProfileModel? userProfile;

  final DraggableScrollableController _dragController = DraggableScrollableController();
  bool _isWebViewFullScreen = false;
  late AnimationController _zoomAnimationController;

  // Dark theme colors
  final Color darkBg = const Color(0xFF121212);
  final Color darkCard = const Color(0xFF1E1E1E);
  final Color darkBorder = const Color(0xFF2A2A2A);

  @override
  void initState() {
    super.initState();
    _zoomAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    fillData();
  }

  @override
  void dispose() {
    _dragController.dispose();
    _zoomAnimationController.dispose();
    super.dispose();
  }

  void _toggleWebViewFullScreen() {
    setState(() {
      _isWebViewFullScreen = !_isWebViewFullScreen;
    });

    if (_isWebViewFullScreen) {
      _zoomAnimationController.forward();
    } else {
      _zoomAnimationController.reverse();
    }
  }

  Future<void> fillData() async {
    if (!mounted) return;

    final followerVM = Provider.of<FollowerFollowingViewModel>(context, listen: false);
    final personalInfoVM = Provider.of<PersonalInformationViewModel>(context, listen: false);

    try {
      await Future.wait([
        followerVM.getFollowerData(),
        followerVM.getFollowingList(),
      ]);

      if (widget.user != null) {
        await followerVM.getFollowStatus(widget.user!.userId.toString());
      }

      userProfile = await personalInfoVM.getUserProfile(
        userId: widget.user?.userId.toString() ?? "",
      );

      if (userProfile != null) {
        profilePic = userProfile!.profilePic.toString();
        avatarUrl = userProfile!.avatarUrl.toString();
      }

      viewerUrl = Uri.encodeFull(
        (userProfile != null && avatarUrl.isNotEmpty)
            ? 'https://optimus-prime-cd.github.io/readyplayerme-viewer/?modelUrl=$avatarUrl'
            : 'https://optimus-prime-cd.github.io/readyplayerme-viewer/?modelUrl=https://models.readyplayer.me/682e1240092177c0ba355fde.glb',
      );

      final userDataList = await personalInfoVM.getUserData(
        userId: widget.user?.userId.toString() ?? "",
      );

      if (userDataList.isNotEmpty) {
        userData = userDataList.map((data) => SignUpModel.fromJson(data!)).first;
      }

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile data: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: darkBg,
      body: Stack(
        children: [
          // Main Content
          if (!_isWebViewFullScreen) _buildSplitView(),

          // Full Screen WebView
          if (_isWebViewFullScreen) _buildFullScreenWebView(),

          // App Bar (always on top)
          if (!_isWebViewFullScreen) _buildAppBar(),

          // Loading Overlay
          if (isLoading)
            Positioned.fill(
              child: Loader(),
            ),
        ],
      ),
    );
  }

  Widget _buildSplitView() {
    return Stack(
      children: [
        // WebView - Background (will be covered by profile when dragged)
        Positioned.fill(
          child: Container(
            color: blackColor,
            child: viewerUrl.isNotEmpty
                ? AvatarViewerPage(viewerUrl: viewerUrl)
                : const Center(
              child: CircularProgressIndicator(color: whiteColor),
            ),
          ),
        ),

        // Zoom Button on WebView
        Positioned(
          top: MediaQuery.of(context).padding.top + 70,
          right: 15,
          child: GestureDetector(
            onTap: _toggleWebViewFullScreen,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white12, Colors.white12],
                ),
                shape: BoxShape.circle,

              ),
              child: const Icon(
                Icons.zoom_out_map,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),

        // Draggable Profile Section
        DraggableScrollableSheet(
          controller: _dragController,
          initialChildSize: 0.5,  // Start at 50%
          minChildSize: 0.5,      // Minimum 50%
          maxChildSize: 1.0,      // Maximum 100% (full screen)
          snap: true,
          snapSizes: const [0.5, 1.0],
          builder: (BuildContext context, ScrollController scrollController) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    darkBg,
                    darkBg.withOpacity(0.98),
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Drag Handle
                  GestureDetector(
                    onTap: () {
                      if (_dragController.size < 0.75) {
                        _dragController.animateTo(
                          1.0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOutCubic,
                        );
                      } else {
                        _dragController.animateTo(
                          0.5,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOutCubic,
                        );
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Container(
                          width: 50,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2.5),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Subtle Divider
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                  // Profile Content
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProfileHeader(),
                          const SizedBox(height: 24),
                          _buildStatsRow(),
                          const SizedBox(height: 24),
                          _buildActionButton(),
                          const SizedBox(height: 24),
                          *//*_buildBioSection(),
                          const SizedBox(height: 24),*//*
                          _buildAdditionalContent(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFullScreenWebView() {
    return Stack(
      children: [
        // Full Screen WebView
        Positioned.fill(
          child: Container(
            color: blackColor,
            child: viewerUrl.isNotEmpty
                ? AvatarViewerPage(viewerUrl: viewerUrl)
                : const Center(
              child: CircularProgressIndicator(color: whiteColor),
            ),
          ),
        ),

        // Top Controls
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back to split view
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: _toggleWebViewFullScreen,
                        icon: const Icon(Icons.close, color: Colors.white, size: 24),
                      ),
                    ),

                    // Username
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextWidget(
                        txt: userData?.userName ?? "Profile",
                        fontSize: FontSizeAndWidth.title,
                        fontWeight: FontSizeAndWidth.semiBold,
                        color: whiteColor,
                      ),
                    ),

                    const SizedBox(width: 48), // Balance
                  ],
                ),
              ),
            ),
          ),
        ),

        // Minimize Button
        Positioned(
          bottom: 30,
          right: 20,
          child: GestureDetector(
            onTap: _toggleWebViewFullScreen,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white12, Colors.white12],
                ),
                shape: BoxShape.circle,),
              child: const Icon(
                Icons.zoom_in_map,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () => widget.onBackToHome?.call(),
                    icon: Icon(Icons.arrow_back_ios_new, color: whiteColor, size: 20),
                    padding: EdgeInsets.zero,
                  ),
                ),

                // Username
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextWidget(
                    txt: userData?.userName ?? "Profile",
                    fontSize: FontSizeAndWidth.title,
                    fontWeight: FontSizeAndWidth.semiBold,
                    color: whiteColor,
                  ),
                ),

                // Actions
                if (widget.user == null)
                  Row(
                    children: [
                      *//*Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () => CommonMethods.goToNext(context, const SettingsScreen()),
                          icon: CommonMethods.assetImage(
                            img: ImageUrl.ic_menu,
                            height: 16.0.h,
                            width: 16.0.h,
                            color: whiteColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),*//*
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () => CommonMethods.goToNext(context, const SettingsScreen()),
                          icon: CommonMethods.assetImage(
                            img: ImageUrl.ic_menu,
                            height: 16.0.h,
                            width: 16.0.h,
                            color: whiteColor,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: PopupMenuButton(
                      icon: Icon(Icons.more_vert, color: whiteColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: darkCard,
                      itemBuilder: (context) {
                        return [
                          PopupMenuItem(
                            child: Row(
                              children: [
                                Icon(Icons.report_outlined, size: 20, color: Colors.white70),
                                const SizedBox(width: 12),
                                Text("Report", style: TextStyle(color: Colors.white)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            child: Row(
                              children: [
                                Icon(Icons.block_outlined, size: 20, color: Colors.white70),
                                const SizedBox(width: 12),
                                Text("Block", style: TextStyle(color: Colors.white)),
                              ],
                            ),
                          ),
                        ];
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start, // Important for alignment
      children: [
        // Profile Picture
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
              colors: [Colors.white12, Colors.white12],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(1),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 70,
              width: 70,
              child: CachedNetworkImage(
                imageUrl: profilePic,
                placeholder: (context, url) => Container(
                  color: darkCard,
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                  ),
                ),
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(
                  color: darkCard,
                  child: Icon(Icons.person, size: 40, color: Colors.grey[600]),
                ),
                memCacheWidth: 240,
                memCacheHeight: 240,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Username and Bio
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Username
              TextWidget(
                txt: userData?.name ?? "User Name",
                fontSize: FontSizeAndWidth.title,
                fontWeight: FontSizeAndWidth.bold,
                color: Colors.white,
              ),
              const SizedBox(height: 2),

              // Bio - Multi-line support
              Text(
                 "Mikk User",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.white70,
                  height: 1.4, // Line height for better readability
                ),
                maxLines: null, // Allow unlimited lines
                overflow: TextOverflow.visible, // Show all text
                softWrap: true, // Enable text wrapping
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Consumer<FollowerFollowingViewModel>(
      builder: (context, followerVM, child) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
               Colors.white12,Colors.white12
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                count: followerVM.followersList.length.toString(),
                label: "Followers",
                icon: Icons.people_outline,
              ),
              Container(height: 40, width: 1, color: Colors.white.withOpacity(0.2)),
              _buildStatItem(
                count: followerVM.followingList.length.toString(),
                label: "Following",
                icon: Icons.person_add_outlined,
              ),
              Container(height: 40, width: 1, color: Colors.white.withOpacity(0.2)),
              _buildStatItem(
                count: "0",
                label: "Posts",
                icon: Icons.grid_on_outlined,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem({
    required String count,
    required String label,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: primaryColor1, size: 26),
        const SizedBox(height: 6),
        TextWidget(
          txt: count,
          fontSize: 20,
          fontWeight: FontSizeAndWidth.bold,
          color: Colors.white,
        ),
        const SizedBox(height: 2),
        TextWidget(
          txt: label,
          fontSize: 12,
          fontWeight: FontSizeAndWidth.regular,
          color: Colors.white60,
        ),
      ],
    );
  }

  Widget _buildBioSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.info_outline, size: 18, color: primaryColor1),
            const SizedBox(width: 8),
            TextWidget(
              txt: "About",
              fontSize: FontSizeAndWidth.subTitle,
              fontWeight: FontSizeAndWidth.bold,
              color: Colors.white,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: darkCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: darkBorder),
          ),
          child: TextWidget(
            txt: userData?.bio ?? "Mikk User - No bio available",
            fontSize: FontSizeAndWidth.descriptionText,
            fontWeight: FontSizeAndWidth.regular,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    return Consumer<FollowerFollowingViewModel>(
      builder: (context, followerVM, child) {
        // Show Edit button for own profile
        if (followerVM.profileBtnStatus.isEmpty || widget.user == null) {
          return Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor2, primaryColor2],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),

            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  // Navigate to edit profile screen
                  CommonMethods.goToNext(context, const AvatarCreatorScreen());
                },
                borderRadius: BorderRadius.circular(12),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit, color: whiteColor, size: 20),
                      const SizedBox(width: 8),
                      TextWidget(
                        txt: "Edit Profile",
                        fontSize: FontSizeAndWidth.subTitle,
                        fontWeight: FontSizeAndWidth.semiBold,
                        color: whiteColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        // Show Follow/Unfollow button for other users
        return Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor2, primaryColor2],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),

          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                followerVM.profileBtnEvent(
                  context: context,
                  otherUserId: widget.user!.userId.toString(),
                  otherUser: widget.user,
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Center(
                child: TextWidget(
                  txt: followerVM.profileBtnStatus,
                  fontSize: FontSizeAndWidth.subTitle,
                  fontWeight: FontSizeAndWidth.semiBold,
                  color: whiteColor,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdditionalContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history, size: 18, color: primaryColor2),
            const SizedBox(width: 8),
            TextWidget(
              txt: "Recent Activity",
              fontSize: FontSizeAndWidth.subTitle,
              fontWeight: FontSizeAndWidth.bold,
              color: Colors.white,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: darkCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: darkBorder),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.circle, size: 8, color: Colors.green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextWidget(
                  txt: "No recent activity",
                  fontSize: FontSizeAndWidth.descriptionText,
                  fontWeight: FontSizeAndWidth.regular,
                  color: Colors.white60,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}*/





/*class Profile extends StatefulWidget {
  final UserNameModel? user;
  final bool? isRequestSent;

  const Profile({super.key, this.user, this.isRequestSent = false});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  double screenHeight = 0.0;
  double screenWidth = 0.0;

  // late final WebViewController _controller;
  final String postername = "your_poster_url_here";
  final String user = "https://models.readyplayer.me/6813614e7d3bdc863ca281a6.glb";
  bool isLightTheme = true;
  SignUpModel? userData;
  bool isLoading = true;
  bool isOldUI = false;

  // List<FollowerFollowingModel> followingList = [];

  String profileBtnStatus = "";

  String viewerUrl = "";

  String avatarUrl = "";
  String profilePic = "";
  UserProfileModel? userProfile;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fillData();
  }

  fillData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final followerVM = Provider.of<FollowerFollowingViewModel>(context, listen: false);
      followerVM.getFollowerData().then(
        (value) async {
          await context.read<FollowerFollowingViewModel>().getFollowingList();
          if (widget.user != null) {
            // profileBtnStatus =
            await context.read<FollowerFollowingViewModel>().getFollowStatus(widget.user!.userId.toString());
          }
          followerVM.setLoading(true);
          final personalInfoVM = Provider.of<PersonalInformationViewModel>(context, listen: false);
          userProfile = await personalInfoVM.getUserProfile(userId: widget.user != null ? widget.user!.userId.toString() : "");
          if (userProfile != null) {
            profilePic = userProfile!.profilePic.toString();
            avatarUrl = userProfile!.avatarUrl.toString();
          }
          viewerUrl = Uri.encodeFull(
            (userProfile != null && avatarUrl.isNotEmpty)
                ? 'https://optimus-prime-cd.github.io/readyplayerme-viewer/?modelUrl=$avatarUrl'
                : 'https://optimus-prime-cd.github.io/readyplayerme-viewer/?modelUrl=https://models.readyplayer.me/682e1240092177c0ba355fde.glb',
          );
          await personalInfoVM
              .getUserData(
            userId: widget.user != null ? widget.user!.userId.toString() : "",
          )
              .then(
            (value) {
              if (value.isNotEmpty) {
                userData = value.map((data) => SignUpModel.fromJson(data!)).first;
                followerVM.setLoading(false);
                // _showBottomSheet(context);
                setState(() {});
              }
            },
          );
          followerVM.setLoading(false);
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;
    return Consumer<FollowerFollowingViewModel>(builder: (context, followerVM, child) {
      return Scaffold(
          backgroundColor: blackColor,
          // backgroundColor: Colors.white,
          body: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  appBar(),
                  Consumer<PersonalInformationViewModel>(builder: (context, personalInfoVM, child) {
                    return Container(
                      height: screenHeight - 355, //(widget.user != null ? 250 : 200),
                      // child: (avatarUrl.isNotEmpty && viewerUrl.isNotEmpty)
                      color: blackColor,
                      child: (viewerUrl.isNotEmpty) ? AvatarViewerPage(viewerUrl: viewerUrl) : Container(color: blackColor),
                      // child: InAppWebView(
                      //   initialUrlRequest: URLRequest(url: WebUri(viewerUrl)),
                      //   initialOptions: InAppWebViewGroupOptions(
                      //     crossPlatform: InAppWebViewOptions(
                      //       javaScriptEnabled: true,
                      //       mediaPlaybackRequiresUserGesture: false,
                      //     ),
                      //   ),
                      // ),
                    );
                  }),
                  // Container(
                  //   height: widget.user != null ? 0 : 200,
                  //   color: Colors.green,
                  // ),
                  followerFollowingWidget(isUserDataFound: userData != null),
                ],
              ),
              followerVM.isLoader ? Loader() : Container()
            ],
          )
          // Stack(
          //   children: [
          // false //kIsWeb
          //     ? Container()
          //     : Container(
          //         height: screenHeight.h,
          //         width: screenWidth.w,
          //         child: const AvatarViewerPage(),
          //       ),

          // : AvatarView(
          //     color: Colors.white,
          //     loading: (isLoader) {
          //       setState(() {
          //         isLoading = isLoader;
          //         isLightTheme = !isLoader;
          //       });
          //     }),

          // Container(
          //   height: screenHeight,
          //   width: screenWidth,
          //   child: SingleChildScrollView(
          //     padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 10, 20, 50),
          //     child: Column(
          //       children: [
          //         appBar(),
          //         AvatarViewerPage()
          //       ],
          //     ),
          //   ),
          // ),
          // ],
          // ),
          );
    });
  }

  appBar() {
    return Container(
      padding: EdgeInsets.only(left: 20, right: 20, top: MediaQuery.of(context).padding.top + 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: Icon(Icons.arrow_back, color: whiteColor, size: 30.r),
                ),
              ),
              SizedBox(width: 10),
              TextWidget(
                txt: userData?.userName.toString() ?? "Profile",
                fontSize: FontSizeAndWidth.title,
                fontWeight: FontSizeAndWidth.medium,
                color: isLightTheme ? Colors.white : appBarTxtColor,
              ),
            ],
          ),
          Visibility(
            visible: widget.user == null,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const SizedBox(height: 5),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: CustomInkwell(
                    onTap: () {
                      CommonMethods.goToNext(context, const SettingsScreen());
                    },
                    childWidget: CommonMethods.assetImage(
                      img: ImageUrl.ic_menu,
                      height: 16.0.h,
                      width: 16.0.h,
                      color: isLightTheme ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: CustomInkwell(
                    onTap: () {
                      CommonMethods.goToNext(context, const AvatarCreatorScreen());
                    },
                    childWidget: CommonMethods.assetImage(
                      img: ImageUrl.ic_edit,
                      height: 20.0.h,
                      width: 20.0.w,
                      color: isLightTheme ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  popMenuItems({required String selectedFilter, String? title}) {
    return PopupMenuItem(
      onTap: () {},
      child: TextWidget(
        txt: title.toString(),
        fontSize: FontSizeAndWidth.descriptionText,
        fontWeight: FontSizeAndWidth.regular,
      ),
    );
  }

  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return followerFollowingWidget(isUserDataFound: userData != null);
      },
    );
  }


  followerFollowingWidget({required bool isUserDataFound}) {
    return Consumer<FollowerFollowingViewModel>(
      builder: (context, followerVM, child) {
        return GradientBorder(
          height: 250,
          width: screenWidth,
          borderRadiusTopLeft: 20.0,
          borderRadiusTopRight: 20.0,
          borderRadiusBottomLeft: 5.0,
          borderRadiusBottomRight: 5.0,
          borderWidth: 1.3,
          padding: const EdgeInsets.all(0),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(5),
                bottomRight: Radius.circular(5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Visibility(
                  visible: isOldUI,
                  child: Container(
                    height: 40,
                    alignment: Alignment.center,
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Consumer<PersonalInformationViewModel>(
                              builder: (context, personalInfoVM, child) {
                                return GradientBorder(
                                  height: 70,
                                  width: 70,
                                  margin: const EdgeInsets.fromLTRB(5, 5, 20, 5),
                                  padding: const EdgeInsets.all(0),
                                  borderRadiusTopLeft: 10,
                                  borderRadiusBottomRight: 10,
                                  borderWidth: 1,
                                  backgroundColor: greyColor,
                                  isBoxShadow: false,
                                  radius: 0,
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(10),
                                      bottomRight: Radius.circular(10),
                                    ),
                                    child: CachedNetworkImage(
                                      height: 70,
                                      width: 70,
                                      imageUrl: profilePic, // or personalInfoVM.profilePic
                                      placeholder: (context, url) => const CircularProgressIndicator(),
                                      fit: BoxFit.cover,
                                      errorWidget: (context, url, error) => Container(
                                        padding: const EdgeInsets.all(20),
                                        child: followerVM.isLoader
                                            ? const CircularProgressIndicator()
                                            : Container(),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      TextWidget(
                                        txt: isUserDataFound ? userData!.userName.toString() : "User Name",
                                        fontSize: FontSizeAndWidth.subTitle,
                                        fontWeight: FontSizeAndWidth.medium,
                                      ),
                                      PopupMenuButton(
                                        padding: const EdgeInsets.all(0),
                                        menuPadding: const EdgeInsets.all(0),
                                        itemBuilder: (context) {
                                          return <PopupMenuEntry>[
                                            popMenuItems(title: "Report", selectedFilter: ConstantLabels.report),
                                            popMenuItems(title: "Block", selectedFilter: ConstantLabels.report),
                                          ];
                                        },
                                        icon: const Icon(Icons.more_horiz_sharp),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            TextWidget(
                                              txt: followerVM.followersList.length.toString(),
                                              fontSize: FontSizeAndWidth.title,
                                              fontWeight: FontSizeAndWidth.bold,
                                            ),
                                            TextWidget(
                                              txt: "Follower",
                                              fontSize: FontSizeAndWidth.subTitle,
                                              fontWeight: FontSizeAndWidth.medium,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            TextWidget(
                                              txt: followerVM.followingList.length.toString(),
                                              fontSize: FontSizeAndWidth.title,
                                              fontWeight: FontSizeAndWidth.bold,
                                            ),
                                            TextWidget(
                                              txt: "Following",
                                              fontSize: FontSizeAndWidth.subTitle,
                                              fontWeight: FontSizeAndWidth.medium,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          child: TextWidget(
                            txt:  userData?.bio.toString() ?? "Mikk User" ,
                            fontSize: FontSizeAndWidth.subTitle,
                            fontWeight: FontSizeAndWidth.semiBold,
                          ),
                        ),
                        const Spacer(),
                        Visibility(
                          visible: followerVM.profileBtnStatus.isNotEmpty,
                          child: widget.user != null
                              ? Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: CustomInkwell(
                              onTap: () {
                                followerVM.profileBtnEvent(
                                  context: context,
                                  otherUserId: widget.user!.userId.toString(),
                                  otherUser: widget.user,
                                );
                              },
                              childWidget: Container(
                                width: double.infinity,
                                height: 45,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: primaryColor1,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: TextWidget(
                                  txt: followerVM.profileBtnStatus,
                                  fontSize: FontSizeAndWidth.descriptionText,
                                  fontWeight: FontSizeAndWidth.medium,
                                  color: whiteColor,
                                ),
                              ),
                            ),
                          )
                              : const SizedBox(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }



}*/

