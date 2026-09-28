

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../Model/GlobalListModel.dart';
import '../../View_Model/Chat/FirestoreChatService.dart';
import '../../View_Model/SettingsDetailViewModel/PrivacySecurityViewModel.dart';
import '../../resources/Custom_InkWell.dart';
import '../../resources/TextWidget.dart';
import '../../utils/CommonMethods.dart';
import '../../values/AppFontStyleAndSize.dart';
import '../../values/Color.dart';

class PrivacySecurity extends StatefulWidget {
  const PrivacySecurity({super.key});

  @override
  State<PrivacySecurity> createState() => _PrivacySecurityState();
}

class _PrivacySecurityState extends State<PrivacySecurity> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SettingsDetailViewModel>(context, listen: false)
          .getPrivacySecurityList();

      // Ensure the blocked-users listener is running even if the person
      // navigated here without passing through Dashboard first.
      Provider.of<FirestoreChatService>(context, listen: false)
          .listenToBlockedUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212), // Dark background
      body: Consumer<SettingsDetailViewModel>(
        builder: (context, viewModel, child) {
          return Column(
            children: [
              appBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 10.w,
                    right: 10.w,
                    top: 10.h,
                    bottom: 50.h,
                  ),
                  child: ListView.builder(
                    itemCount: viewModel.privacySecurityList.length,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.all(0.r),
                    itemBuilder: (context, index) {
                      return privacySecurityItem(
                        privacySecurityItem: viewModel.privacySecurityList[index],
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  appBar() {
    return Container(
      margin: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        top: MediaQuery.of(context).padding.top + 10.h,
        bottom: 15.h,
      ),
      color: Color(0xFF121212), // Dark background for app bar
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: Colors.white12,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 24.sp,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          TextWidget(
            txt: "Privacy & Safety",
            fontSize: FontSizeAndWidth.title,
            fontWeight: FontSizeAndWidth.semiBold,
            color: whiteColor,
          ),
        ],
      ),
    );
  }

  privacySecurityItem({required GlobalListModel privacySecurityItem}) {
    return CustomInkwell(
      onTap: () {
        // Check the title to determine which action to perform
        if (privacySecurityItem.title.toLowerCase().contains('blocked account')) {
          _showBlockedAccountsBottomSheet();
        } else if (privacySecurityItem.title.toLowerCase().contains('delete my account')) {
          _showDeleteAccountDialog();
        } else if (privacySecurityItem.onTap != null) {
          privacySecurityItem.onTap!();
        }
      },
      childWidget: Container(
        margin: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: Color(0xFF1E1E1E), // Dark card background
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(14.r),
          child: Row(
            children: [
              // Icon Circle (if icon exists)
              if (privacySecurityItem.icon != null)
                Container(
                  width: 48.w,
                  height: 48.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.white12,
                        Colors.white12,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Icon(
                    privacySecurityItem.icon,
                    color: whiteColor,
                    size: 24.r,
                  ),
                ),
              if (privacySecurityItem.icon != null) SizedBox(width: 12.w),
              // Title
              Expanded(
                child: TextWidget(
                  txt: privacySecurityItem.title,
                  fontSize: FontSizeAndWidth.descriptionText,
                  fontWeight: FontSizeAndWidth.medium,
                  color: whiteColor,
                ),
              ),
              // Arrow icon
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade600,
                size: 24.r,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ═══════════════════════════════════════════════════════════════
  //                    BLOCKED ACCOUNTS SHEET
  // ═══════════════════════════════════════════════════════════════
  // ═══════════════════════════════════════════════════════════════

  void _showBlockedAccountsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Color(0xFF1E1E1E),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24.r),
                  topRight: Radius.circular(24.r),
                ),
              ),
              child: Consumer<FirestoreChatService>(
                builder: (context, chatService, child) {
                  final blockedUsers = chatService.blockedUsersDetails;

                  return Column(
                    children: [
                      SizedBox(height: 12.h),
                      Container(
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade600,
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 20.h),
                        child: TextWidget(
                          txt: "Blocked Accounts",
                          fontSize: FontSizeAndWidth.title + 2,
                          fontWeight: FontSizeAndWidth.semiBold,
                          color: whiteColor,
                        ),
                      ),
                      Expanded(
                        child: blockedUsers.isEmpty
                            ? _buildEmptyBlockedState()
                            : ListView.builder(
                          controller: scrollController,
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          itemCount: blockedUsers.length,
                          itemBuilder: (context, index) {
                            return _buildBlockedUserTile(
                              blockedUsers[index],
                              chatService,
                            );
                          },
                        ),
                      ),
                      SizedBox(height: MediaQuery.of(context).padding.bottom + 16.h),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyBlockedState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80.w,
              height: 80.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(Icons.block, color: whiteColor, size: 40.r),
            ),
            SizedBox(height: 20.h),
            TextWidget(
              txt: "No blocked accounts yet",
              fontSize: FontSizeAndWidth.descriptionText,
              fontWeight: FontSizeAndWidth.regular,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 8.h),
            TextWidget(
              txt: "Accounts you block will appear here",
              fontSize: FontSizeAndWidth.descriptionText - 2,
              fontWeight: FontSizeAndWidth.regular,
              color: Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockedUserTile(
      Map<String, dynamic> user,
      FirestoreChatService chatService,
      ) {
    final String userId = user['userId'] ?? '';
    final String name = (user['name'] ?? '').toString().isNotEmpty
        ? user['name']
        : 'Unknown User';
    final String profilePic = user['profilePic'] ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: SizedBox(
              height: 48.h,
              width: 48.h,
              child: profilePic.isNotEmpty
                  ? CachedNetworkImage(
                imageUrl: profilePic,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: const Color(0xFF2A2A2A),
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: const Color(0xFF2A2A2A),
                  child: Icon(Icons.person, color: Colors.white30, size: 26.r),
                ),
              )
                  : Container(
                color: const Color(0xFF2A2A2A),
                child: Icon(Icons.person, color: Colors.white30, size: 26.r),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: TextWidget(
              txt: name,
              fontSize: FontSizeAndWidth.descriptionText,
              fontWeight: FontSizeAndWidth.medium,
              color: whiteColor,
            ),
          ),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: () => _confirmUnblock(userId, name, chatService),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: primaryColor2.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: primaryColor2.withOpacity(0.4)),
              ),
              child: TextWidget(
                txt: "Unblock",
                fontSize: FontSizeAndWidth.descriptionText - 2,
                fontWeight: FontSizeAndWidth.semiBold,
                color: primaryColor2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmUnblock(
      String userId,
      String name,
      FirestoreChatService chatService,
      ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: TextWidget(
          txt: "Unblock $name?",
          fontSize: FontSizeAndWidth.title,
          fontWeight: FontSizeAndWidth.bold,
          color: whiteColor,
        ),
        content: TextWidget(
          txt: "They will be able to see your profile and message you again.",
          fontSize: FontSizeAndWidth.descriptionText - 2,
          fontWeight: FontSizeAndWidth.regular,
          color: Colors.grey.shade400,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: TextWidget(
              txt: "Cancel",
              fontSize: FontSizeAndWidth.descriptionText - 2,
              fontWeight: FontSizeAndWidth.semiBold,
              color: Colors.grey.shade400,
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await chatService.unblockUser(userId);
                CommonMethods.showToast("$name unblocked");
              } catch (e) {
                CommonMethods.showToast("Failed to unblock user");
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            child: TextWidget(
              txt: "Unblock",
              fontSize: FontSizeAndWidth.descriptionText - 2,
              fontWeight: FontSizeAndWidth.semiBold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  offset: Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            padding: EdgeInsets.all(24.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Warning Icon
                Container(
                  width: 80.w,
                  height: 80.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.red.shade400,
                        Colors.red.shade700,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: whiteColor,
                    size: 40.r,
                  ),
                ),
                SizedBox(height: 24.h),
                // Title
                TextWidget(
                  txt: "Delete My Account",
                  fontSize: FontSizeAndWidth.title + 2,
                  fontWeight: FontSizeAndWidth.bold,
                  color: whiteColor,
                ),
                SizedBox(height: 12.h),
                // Message
                TextWidget(
                  txt: "Are you sure you want to delete your account?",
                  fontSize: FontSizeAndWidth.descriptionText,
                  fontWeight: FontSizeAndWidth.regular,
                  color: Colors.grey.shade400,
                ),
                SizedBox(height: 8.h),
                TextWidget(
                  txt: "This action cannot be undone. All your data will be permanently deleted.",
                  fontSize: FontSizeAndWidth.descriptionText - 2,
                  fontWeight: FontSizeAndWidth.regular,
                  color: Colors.grey.shade600,
                ),
                SizedBox(height: 32.h),
                // Buttons
                Row(
                  children: [
                    // Cancel button
                    Expanded(
                      child: Container(
                        height: 48.h,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: Colors.grey.shade700,
                            width: 1.5,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            borderRadius: BorderRadius.circular(12.r),
                            child: Center(
                              child: TextWidget(
                                txt: "Cancel",
                                fontSize: FontSizeAndWidth.descriptionText,
                                fontWeight: FontSizeAndWidth.semiBold,
                                color: Colors.grey.shade300,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    // Delete button
                    Expanded(
                      child: Container(
                        height: 48.h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.red.shade500,
                              Colors.red.shade700,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              // Handle delete account logic here
                              Navigator.pop(context);

                              DeleteAccount();
                              // Add your delete account logic
                              // AuthViewModel().deleteAccount();
                            },
                            borderRadius: BorderRadius.circular(12.r),
                            child: Center(
                              child: TextWidget(
                                txt: "Delete",
                                fontSize: FontSizeAndWidth.descriptionText,
                                fontWeight: FontSizeAndWidth.semiBold,
                                color: whiteColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> DeleteAccount() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Add to reports collection
      await FirebaseFirestore.instance.collection('DeletedAccount').add({
        'DeletedUserId': currentUser.uid,
        'reportedById': currentUser.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      CommonMethods.showToast("Your account will be deleted within 30 days");
    } catch (e) {
      CommonMethods.showToast("Failed to submit report");
    }
  }
}



