import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mikk/Model/NotificationModel.dart';
import 'package:mikk/View_Model/NotificationViewModel.dart';
import 'package:mikk/resources/Custom_InkWell.dart';
import 'package:mikk/utils/LogHelper.dart';
import 'package:mikk/utils/StringCasingExtension.dart';
import 'package:provider/provider.dart';

import '../Model/auth/UserNameModel.dart';
import '../View_Model/SettingsViewModel.dart';
import '../resources/TextWidget.dart';
import '../utils/CommonMethods.dart';
import '../values/AppFontStyleAndSize.dart';
import '../values/Color.dart';
import 'Profile.dart';


class NotificationScreen extends StatefulWidget {
  final VoidCallback? onBackToHome;
  const NotificationScreen({super.key, this.onBackToHome});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationViewModel>(context, listen: false).getNotificationData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212), // Dark background
      body: Consumer<NotificationViewModel>(
        builder: (context, viewModel, child) {
          return Column(
            children: [
              appBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(left: 10.w, right: 10.w, top: 10.h, bottom: 100.h),
                  child: ListView.builder(
                    padding: EdgeInsets.all(0.r),
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: viewModel.notificationList.length,
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      return notificationItem(
                        viewModel: viewModel,
                        notificationItem: viewModel.notificationList[index],
                        index: index,
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

  Widget notificationItem({
    required NotificationViewModel viewModel,
    required NotificationModel notificationItem,
    required int index,
  }) {
    return Container(
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
            // Avatar Circle
            Container(
              width: 48.w,
              height: 48.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade400,
                    Colors.blue.shade700,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),

              ),
              child: Center(
                child: TextWidget(
                  txt: notificationItem.userName.toString()[0].toUpperCase(),
                  fontSize: FontSizeAndWidth.title,
                  fontWeight: FontSizeAndWidth.semiBold,
                  color: whiteColor,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: CustomInkwell(
                          onTap: () {
                            UserNameModel user = UserNameModel(
                              userName: notificationItem.userName,
                              name: notificationItem.name,
                              userId: notificationItem.senderUserId,
                            );
                            LogHelper("user data ${jsonEncode(user)}");
                           // CommonMethods.goToNext(context, Profile(user: user));
                          },
                          childWidget: RichText(
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: notificationItem.isFollowing!
                                      ? "You"
                                      : notificationItem.userName.toString().toCapitalized(),
                                  style: TextStyle(
                                    fontSize: FontSizeAndWidth.descriptionText,
                                    fontWeight: FontSizeAndWidth.semiBold,
                                    color: Colors.white,
                                  ),
                                ),
                                TextSpan(
                                  text: " started following ",
                                  style: TextStyle(
                                    fontSize: FontSizeAndWidth.descriptionText,
                                    fontWeight: FontSizeAndWidth.regular,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                                TextSpan(
                                  text: notificationItem.isFollowing!
                                      ? notificationItem.userName.toString().toCapitalized()
                                      : "you",
                                  style: TextStyle(
                                    fontSize: FontSizeAndWidth.descriptionText,
                                    fontWeight: FontSizeAndWidth.semiBold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      followBackBtn(
                        txt: "Follow back",
                        notificationItem: notificationItem,
                        viewModel: viewModel,
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  // Time stamp
                  TextWidget(
                    txt: "Just now", // Replace with actual time
                    fontSize: FontSizeAndWidth.descriptionText - 2,
                    fontWeight: FontSizeAndWidth.regular,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ],
        ),
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
              // Call the callback to navigate to home
              widget.onBackToHome?.call();
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
            txt: "Notifications",
            fontSize: FontSizeAndWidth.title,
            fontWeight: FontSizeAndWidth.semiBold,
            color: whiteColor,
          ),
        ],
      ),
    );
  }

  followBackBtn({
    String txt = "",
    required NotificationModel notificationItem,
    required NotificationViewModel viewModel,
  }) {
    return Visibility(
      visible: !(notificationItem.isFollowing!),
      child: CustomInkwell(
        onTap: () {
          viewModel.followBack(context, followBackUser: notificationItem);
        },
        childWidget: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            gradient: LinearGradient(
              colors: [
                Colors.blue.shade500,
                Colors.blue.shade700,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),

          ),
          child: TextWidget(
            txt: txt,
            fontSize: FontSizeAndWidth.descriptionText,
            fontWeight: FontSizeAndWidth.medium,
            color: whiteColor,
          ),
        ),
      ),
    );
  }

  actionBtn({required bool isAccept}) {
    return Container(
      alignment: Alignment.center,
      margin: EdgeInsets.only(right: isAccept ? 10.w : 0.w, bottom: 3.h),
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        gradient: isAccept
            ? LinearGradient(
          colors: [Colors.grey.shade800, Colors.grey.shade900],
        )
            : null,
        color: isAccept ? null : Colors.transparent,
        border: Border.all(
          color: isAccept ? Colors.transparent : Colors.grey.shade700,
          width: 1.5,
        ),
      ),
      child: TextWidget(
        txt: isAccept ? "Accept" : "Decline",
        fontSize: FontSizeAndWidth.descriptionText,
        fontWeight: FontSizeAndWidth.medium,
        color: isAccept ? whiteColor : Colors.grey.shade300,
      ),
    );
  }
}
