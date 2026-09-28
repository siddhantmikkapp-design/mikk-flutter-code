import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../View_Model/SettingsDetailViewModel/PrivacySecurityViewModel.dart';
import '../../resources/TextWidget.dart';
import '../../values/AppFontStyleAndSize.dart';
import '../../values/Color.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool isPushNotificationEnabled = true; // Default state

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SettingsDetailViewModel>(context, listen: false).getNotificationList();
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
                  child: Column(
                    children: [
                      // Push Notification Toggle
                      pushNotificationItem(),
                      SizedBox(height: 20.h),
                      // Other notification items
                      /*ListView.builder(
                        itemCount: viewModel.notificationList.length,
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.all(0.r),
                        itemBuilder: (context, index) {
                          return notificationItem(
                            notificationItem: viewModel.notificationList[index],
                          );
                        },
                      ),*/
                    ],
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
            txt: "Notification Settings",
            fontSize: FontSizeAndWidth.title,
            fontWeight: FontSizeAndWidth.semiBold,
            color: whiteColor,
          ),
        ],
      ),
    );
  }

  Widget pushNotificationItem() {
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
            // Icon Circle
            Container(
              width: 48.w,
              height: 48.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isPushNotificationEnabled
                      ? [
                    Colors.blue.shade400,
                    Colors.blue.shade700,
                  ]
                      : [
                    Colors.grey.shade700,
                    Colors.grey.shade900,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(
                Icons.notifications_active,
                color: whiteColor,
                size: 24.r,
              ),
            ),
            SizedBox(width: 12.w),
            // Title and Description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextWidget(
                    txt: "Push Notifications",
                    fontSize: FontSizeAndWidth.descriptionText,
                    fontWeight: FontSizeAndWidth.medium,
                    color: whiteColor,
                  ),
                  SizedBox(height: 4.h),
                  TextWidget(
                    txt: isPushNotificationEnabled
                        ? "Receive notifications about your activity"
                        : "Notifications are turned off",
                    fontSize: FontSizeAndWidth.descriptionText - 2,
                    fontWeight: FontSizeAndWidth.regular,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
            // Toggle Switch
            Switch(
              value: isPushNotificationEnabled,
              onChanged: (value) {
                setState(() {
                  isPushNotificationEnabled = value;
                });
                // Add your logic here to save the preference
                // viewModel.updatePushNotificationSetting(value);
              },
              activeColor: Colors.blue.shade400,
              activeTrackColor: Colors.blue.shade700.withOpacity(0.5),
              inactiveThumbColor: Colors.grey.shade600,
              inactiveTrackColor: Colors.grey.shade800,
            ),
          ],
        ),
      ),
    );
  }
/*
  notificationItem({required GlobalListModel notificationItem}) {
    return CustomInkwell(
      onTap: () {
        if (notificationItem.onTap != null) {
          notificationItem.onTap!();
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
              if (notificationItem.icon != null)
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
                  child: Icon(
                    notificationItem.icon,
                    color: whiteColor,
                    size: 24.r,
                  ),
                ),
              if (notificationItem.icon != null) SizedBox(width: 12.w),
              // Title
              Expanded(
                child: TextWidget(
                  txt: notificationItem.title,
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
  }*/
}
