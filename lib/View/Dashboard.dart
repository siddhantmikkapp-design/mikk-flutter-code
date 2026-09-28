


import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../Demo/AvatarUploadStatus.dart';
import '../Demo/MessageClass.dart';
import '../Model/SearchModel.dart';
import '../View_Model/Chat/FirestoreChatService.dart';
import '../View_Model/DashboardViewModel.dart';
import '../View_Model/ProfileViewModel.dart';
import '../resources/TextWidget.dart';
import '../services/local_storage_service.dart';
import '../utils/CommonMethods.dart';
import '../utils/LogHelper.dart';
import '../utils/SessionManager.dart';
import '../values/AppFontStyleAndSize.dart';
import '../values/Color.dart';
import '../values/StaticText.dart';
import 'Profile.dart';
import 'UnityChatScreen.dart';
import 'chat_screen.dart';


class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard>
    with SingleTickerProviderStateMixin {
  bool isSearch = false;
  String avatarUrl = "";
  double screenWidth = 0.0;
  double screenHeight = 0.0;

  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
    fillData();

    // ✅ Retry any pending avatar uploads when Dashboard loads
    AvatarUploadManager().retryPendingUploads();

    // ✅ Start listening for block status (both directions) as soon as
    // the dashboard is alive, so the message list can filter itself.
    Provider.of<FirestoreChatService>(context, listen: false)
        .listenToBlockedUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  fillData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FirestoreChatService>(context, listen: false)
          .getDashboardMessageData();
      getCurrentUserData();
    });
  }

  void getCurrentUserData() async {
    final profileVM = Provider.of<ProfileViewModel>(context, listen: false);

    // 1. Show cached avatar instantly, no waiting on Firestore
    final cachedURL = await LocalStorageService.getModelURL();
    if (cachedURL != null && cachedURL.isNotEmpty) {
      avatarUrl = cachedURL;
      if (mounted) setState(() {});
    }

    // 2. Still fetch profile (name etc.), and re-cache modelURL only if it changed
    await profileVM.getCurrentUserData();
    final freshURL = profileVM.currentUser!.modelURL.toString();

    if (freshURL != avatarUrl) {
      avatarUrl = freshURL;
      await LocalStorageService.saveModelURL(freshURL);
      if (mounted) setState(() {});
    }

    final chatService = Provider.of<FirestoreChatService>(context, listen: false);
    chatService.updateCurrentUserName(
      newCurrentUserName: profileVM.currentUser?.name ?? '',
    );
  }


  /// Get current user UID safely
  String? get _currentUid => FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    return Consumer<DashboardViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          backgroundColor: const Color(0xFF0A0A0A),
          body: Column(
            children: [
              _buildAppBar(viewModel: viewModel),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMessagesList(),
                    _buildRandomChatList(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBar({required DashboardViewModel viewModel}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0A0A0A),
            const Color(0xFF0A0A0A).withOpacity(0.95),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 12.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextWidget(
                txt: "MiKK",
                fontSize: 28,
                fontWeight: FontSizeAndWidth.bold,
                color: Colors.white,
                fontFamily: ConstantLabels.Montserrat,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.09),
              Colors.white.withOpacity(0.09)
            ],
          ),
          borderRadius: BorderRadius.circular(10.r),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        labelStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emergency_outlined, size: 18.r),
                SizedBox(width: 6.w),
                const Text('Express'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 18.r),
                SizedBox(width: 6.w),
                const Text('Quick'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return Consumer<FirestoreChatService>(
      builder: (context, chatService, child) {
        if (chatService.isLoader) {
          return Center(
            child: CircularProgressIndicator(color: primaryColor2),
          );
        }

        // ✅ Uses the filtered list so blocked conversations never render
        final list = chatService.visibleDashboardMessageList;

        if (list.isEmpty) {
          return _buildEmptyState(
            icon: Icons.emergency_outlined,
            title: "Search for friends Id",
            subtitle: "Chat using 3d Avatar",
          );
        }

        return ListView.builder(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
          physics: const BouncingScrollPhysics(),
          itemCount: list.length,
          itemBuilder: (context, index) {
            return _buildMessageItem(
              index: index,
              item: list[index],
              chatService: chatService,
            );
          },
        );
      },
    );
  }

  Widget _buildRandomChatList() {
    return Consumer<FirestoreChatService>(
      builder: (context, chatService, child) {
        if (chatService.isLoader) {
          return Center(
            child: CircularProgressIndicator(color: primaryColor2),
          );
        }

        // ✅ Uses the filtered list so blocked conversations never render
        final list = chatService.visibleDashboardMessageList;

        if (list.isEmpty) {
          return _buildEmptyState(
            icon: Icons.messenger_outline,
            title: "Search for friends Id",
            subtitle: "Start a conversation with them",
          );
        }

        return ListView.builder(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
          physics: const BouncingScrollPhysics(),
          itemCount: list.length,
          itemBuilder: (context, index) {
            return _buildNormalChatItem(
              index: index,
              item: list[index],
              chatService: chatService,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(40.r),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 80.r, color: Colors.white70),
          ),
          SizedBox(height: 24.h),
          TextWidget(
            txt: title,
            fontSize: 20,
            fontWeight: FontSizeAndWidth.bold,
            color: Colors.white70,
          ),
          SizedBox(height: 12.h),
          TextWidget(
            txt: subtitle,
            fontSize: 14,
            fontWeight: FontSizeAndWidth.regular,
            color: Colors.white70,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ═══════════════════════════════════════════════════════════════
  //          LONG-PRESS CHAT OPTIONS (View Profile / Delete)
  // ═══════════════════════════════════════════════════════════════
  // ═══════════════════════════════════════════════════════════════

  void _showChatOptions(MessageClass item, FirestoreChatService chatService) {
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 12.h),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 12.h),
              ListTile(
                leading:
                Icon(Icons.person_outline, color: Colors.white, size: 22.r),
                title: TextWidget(
                  txt: "View Profile",
                  fontSize: 15,
                  fontWeight: FontSizeAndWidth.medium,
                  color: Colors.white,
                ),
                onTap: () {
                  Navigator.pop(sheetContext); // close sheet first
                  CommonMethods.goToNext(
                    context,
                    Profile(
                      user: SearchModel(userId: item.otherUserId),
                      onBackToHome: () => Navigator.pop(context),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline,
                    color: Colors.redAccent, size: 22.r),
                title: TextWidget(
                  txt: "Delete Chat",
                  fontSize: 15,
                  fontWeight: FontSizeAndWidth.medium,
                  color: Colors.redAccent,
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _confirmDeleteChat(item, chatService);
                },
              ),
              SizedBox(height: 12.h),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteChat(MessageClass item, FirestoreChatService chatService) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: TextWidget(
          txt: "Delete Chat",
          fontSize: 18,
          fontWeight: FontSizeAndWidth.bold,
          color: Colors.white,
        ),
        content: TextWidget(
          txt:
          "This will remove the chat from your list. ${item.name ?? 'This user'} will still see it on their side.",
          fontSize: 14,
          fontWeight: FontSizeAndWidth.regular,
          color: Colors.white70,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: TextWidget(
              txt: "Cancel",
              fontSize: 14,
              fontWeight: FontSizeAndWidth.semiBold,
              color: Colors.white60,
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await chatService
                    .deleteConversation(item.otherUserId.toString());
                CommonMethods.showToast("Chat deleted");
              } catch (e) {
                CommonMethods.showToast("Failed to delete chat");
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: TextWidget(
              txt: "Delete",
              fontSize: 14,
              fontWeight: FontSizeAndWidth.semiBold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ═══════════════════════════════════════════════════════════════
  //                       CHAT LIST ITEMS
  // ═══════════════════════════════════════════════════════════════
  // ═══════════════════════════════════════════════════════════════

  Widget _buildMessageItem({
    required int index,
    required MessageClass item,
    required FirestoreChatService chatService,
  }) {
    return GestureDetector(
      onTap: () {
        chatService.updateReceiverUser(newReceiverUser: item).then((value) {
          CommonMethods.goToNext(
            context,
            UnityChatScreen(
              receiverUser: item,
              roomName: item.roomName.toString(),
              avatarUrl: avatarUrl,
              profilePicUrl: item.profilePic.toString(),
              name: item.name.toString(),
            ),
          );
        });
      },
      onLongPress: () => _showChatOptions(item, chatService),
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.08),
              Colors.white.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 0,
          ),
        ),
        child: Row(
          children: [
            // Profile Picture
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.white12, Colors.white12],
                    ),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  padding: EdgeInsets.all(2.r),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: SizedBox(
                      height: 56.h,
                      width: 56.h,
                      child: CachedNetworkImage(
                        imageUrl: item.profilePic.toString(),
                        placeholder: (context, url) => Container(
                          color: const Color(0xFF1E1E1E),
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Container(
                          color: const Color(0xFF1E1E1E),
                          child: Icon(Icons.person,
                              size: 30.r, color: Colors.white30),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 14.r,
                    height: 14.r,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF0A0A0A),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(width: 12.w),
            // Message Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: TextWidget(
                          txt: item.name.toString(),
                          fontSize: 16,
                          fontWeight: FontSizeAndWidth.semiBold,
                          color: Colors.white,
                          maxLines: 1,
                        ),
                      ),
                      TextWidget(
                        txt: item.getFormattedTime(),
                        fontSize: 11,
                        fontWeight: FontSizeAndWidth.regular,
                        color: Colors.white70,
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Expanded(
                        child: TextWidget(
                          txt: item.message.toString(),
                          fontSize: 13,
                          fontWeight: FontSizeAndWidth.regular,
                          color: item.isRead == true
                              ? Colors.white.withOpacity(0.6)
                              : Colors.blue,
                          maxLines: 1,
                        ),
                      ),
                      if ((item.unreadCount ?? 0) > 0)
                        Container(
                          margin: EdgeInsets.only(left: 8.w),
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.teal,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            item.unreadCount! > 99
                                ? '99+'
                                : item.unreadCount.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNormalChatItem({
    required int index,
    required MessageClass item,
    required FirestoreChatService chatService,
  }) {
    return GestureDetector(
      onTap: () {
        chatService.updateReceiverUser(newReceiverUser: item).then((value) {
          CommonMethods.goToNext(
            context,
            ChatScreen(
              receiverUser: item,
              roomName: item.roomName.toString(),
              profilePicUrl: item.profilePic.toString(),
              name: item.name.toString(),
            ),
          );
        });
      },
      onLongPress: () => _showChatOptions(item, chatService),
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.08),
              Colors.white.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 0,
          ),
        ),
        child: Row(
          children: [
            // Profile Picture
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.white12, Colors.white12],
                    ),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  padding: EdgeInsets.all(2.r),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: SizedBox(
                      height: 56.h,
                      width: 56.h,
                      child: CachedNetworkImage(
                        imageUrl: item.profilePic.toString(),
                        placeholder: (context, url) => Container(
                          color: const Color(0xFF1E1E1E),
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Container(
                          color: const Color(0xFF1E1E1E),
                          child: Icon(Icons.person,
                              size: 30.r, color: Colors.white30),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 14.r,
                    height: 14.r,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF0A0A0A),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(width: 12.w),
            // Message Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: TextWidget(
                          txt: item.name.toString(),
                          fontSize: 16,
                          fontWeight: FontSizeAndWidth.semiBold,
                          color: Colors.white,
                          maxLines: 1,
                        ),
                      ),
                      TextWidget(
                        txt: item.getFormattedTime(),
                        fontSize: 11,
                        fontWeight: FontSizeAndWidth.regular,
                        color: Colors.white70,
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Expanded(
                        child: TextWidget(
                          txt: item.message.toString(),
                          fontSize: 13,
                          fontWeight: FontSizeAndWidth.regular,
                          color: item.isRead == true
                              ? Colors.white.withOpacity(0.6)
                              : Colors.blue,
                          maxLines: 1,
                        ),
                      ),
                      if ((item.unreadCount ?? 0) > 0)
                        Container(
                          margin: EdgeInsets.only(left: 8.w),
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.teal,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            item.unreadCount! > 99
                                ? '99+'
                                : item.unreadCount.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  getUserData() async {
    String name =
    await SessionManager.getStringData(SessionManager.FORM_PHONE_NAME);
    LogHelper("name $name");
    String number =
    await SessionManager.getStringData(SessionManager.FORM_PHONE_NO);
    LogHelper("number $number");
    SessionManager.setStringData(SessionManager.FORM_PHONE_NO, "");
    SessionManager.setStringData(SessionManager.FORM_PHONE_NAME, "");
    setState(() {});
  }
}