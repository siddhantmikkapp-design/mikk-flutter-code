import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mikk/View_Model/SettingsViewModel.dart';
import 'package:mikk/resources/Custom_InkWell.dart';
import 'package:mikk/utils/CommonMethods.dart';
import 'package:provider/provider.dart';

import '../Model/SettingsModel.dart';
import '../resources/CustomAppBar.dart';
import '../resources/TextWidget.dart';
import '../values/AppFontStyleAndSize.dart';
import '../values/Color.dart';
import '../values/StaticText.dart';


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  SettingViewModel settingViewModel = SettingViewModel();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SettingViewModel>(context, listen: false).getSettingsList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Consumer<SettingViewModel>(
        builder: (context, viewModel, child) {
          return Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 100.h),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      _buildSettingsList(viewModel),
                      SizedBox(height: 40.h),
                      _buildBottomWidget(),
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

  Widget _buildAppBar() {
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
          padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 16.h),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 20.r,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextWidget(
                    txt: "Settings",
                    fontSize: 24,
                    fontWeight: FontSizeAndWidth.bold,
                    color: Colors.white,
                  ),
                  TextWidget(
                    txt: "Manage your account",
                    fontSize: 12,
                    fontWeight: FontSizeAndWidth.regular,
                    color: Colors.white60,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsList(SettingViewModel viewModel) {
    return ListView.builder(
      itemCount: viewModel.settingsList.length,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return _buildSettingItem(
          settingsItem: viewModel.settingsList[index],
          viewModel: viewModel,
          index: index,
        );
      },
    );
  }

  Widget _buildSettingItem({
    required SettingsModel settingsItem,
    required SettingViewModel viewModel,
    required int index,
  }) {
    return GestureDetector(
      onTap: () {
        if (settingsItem.image.isNotEmpty) {
          viewModel.moveToNext(context, moveToNext: settingsItem.redirectTo,url:settingsItem.url,share: settingsItem.share);
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.r),
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
            // Icon Container
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white12,
                    Colors.white12
                  ],
                ),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: settingsItem.image.isNotEmpty
                  ? CommonMethods.assetImage(
                height: 24.r,
                width: 24.r,
                img: settingsItem.image,
                isSvg: true,
                color: Colors.white,
              )
                  : Icon(
                settingsItem.icon,
                color: Colors.white,
                size: 24.r,
              ),
            ),
            SizedBox(width: 16.w),

            // Text
            Expanded(
              child: TextWidget(
                txt: settingsItem.txt,
                fontSize: 16,
                fontWeight: FontSizeAndWidth.medium,
                color: Colors.white,
              ),
            ),

            // Arrow Icon
            Icon(
              Icons.chevron_right,
              color: Colors.white70,
              size: 24.r,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomWidget() {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.05),
            Colors.white.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildHelpButton(),
          Container(
            width: 1,
            height: 40.h,
            color: Colors.white.withOpacity(0.2),
          ),
          _buildVersionInfo(),
        ],
      ),
    );
  }

  Widget _buildHelpButton() {
    return InkWell(
      onTap: () {
        _showHelpCenterBottomSheet();
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: primaryColor2,
                width: 2,
              ),
            ),
            child: Icon(
              Icons.help_outline,
              color: primaryColor2,
              size: 18.r,
            ),
          ),
          SizedBox(width: 8.w),
          TextWidget(
            txt: "Help Center",
            fontSize: 15,
            fontWeight: FontSizeAndWidth.semiBold,
            color: primaryColor2,
          ),
        ],
      ),
    );
  }


  void _showHelpCenterBottomSheet() {
    final TextEditingController problemController = TextEditingController();
    final TextEditingController emailController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (BuildContext bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Color(0xFF1E1E1E),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24.r),
                topRight: Radius.circular(24.r),
              ),
            ),
            padding: EdgeInsets.all(24.r),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade600,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  // Header
                  Row(
                    children: [
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
                          Icons.support_agent,
                          color: whiteColor,
                          size: 24.r,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextWidget(
                              txt: "Help Center",
                              fontSize: FontSizeAndWidth.title + 2,
                              fontWeight: FontSizeAndWidth.semiBold,
                              color: whiteColor,
                            ),
                            SizedBox(height: 4.h),
                            TextWidget(
                              txt: "We're here to help you",
                              fontSize: FontSizeAndWidth.descriptionText - 2,
                              fontWeight: FontSizeAndWidth.regular,
                              color: Colors.grey.shade600,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),
                  // Email Field
                  TextWidget(
                    txt: "Email Address",
                    fontSize: FontSizeAndWidth.descriptionText,
                    fontWeight: FontSizeAndWidth.medium,
                    color: Colors.grey.shade400,
                  ),
                  SizedBox(height: 8.h),
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
                    child: TextField(
                      controller: emailController,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: FontSizeAndWidth.descriptionText,
                      ),
                      decoration: InputDecoration(
                        hintText: "Enter your email",
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: FontSizeAndWidth.descriptionText,
                        ),
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: Colors.white.withOpacity(0.7),
                          size: 22.r,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 16.h,
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // Problem Description Field
                  TextWidget(
                    txt: "Describe Your Problem",
                    fontSize: FontSizeAndWidth.descriptionText,
                    fontWeight: FontSizeAndWidth.medium,
                    color: Colors.grey.shade400,
                  ),
                  SizedBox(height: 8.h),
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
                    child: TextField(
                      controller: problemController,
                      maxLines: 5,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: FontSizeAndWidth.descriptionText,
                      ),
                      decoration: InputDecoration(
                        hintText: "Tell us what's wrong...",
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: FontSizeAndWidth.descriptionText,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  // Submit Button
                  Container(
                    width: double.infinity,
                    height: 52.h,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.shade500,
                          Colors.blue.shade700,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          // Validate inputs
                          if (emailController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Please enter your email'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          if (problemController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Please describe your problem'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          // Store values before closing
                          String email = emailController.text;
                          String problem = problemController.text;

                          // Handle submit logic here
                          // viewModel.submitHelpRequest(
                          //   email: email,
                          //   problem: problem,
                          // );

                          // Close bottom sheet first
                          Navigator.pop(bottomSheetContext);

                          // Wait for bottom sheet to close completely
                          await Future.delayed(Duration(milliseconds: 300));

                          // Now dispose controllers
                          emailController.dispose();
                          problemController.dispose();

                          // Show success message
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Your request has been submitted'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(12.r),
                        child: Center(
                          child: TextWidget(
                            txt: "Submit",
                            fontSize: FontSizeAndWidth.descriptionText,
                            fontWeight: FontSizeAndWidth.semiBold,
                            color: whiteColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                ],
              ),
            ),
          ),
        );
      },
    );
  }




  Widget _buildVersionInfo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: primaryColor2,
              width: 2,
            ),
          ),
          child: TextWidget(
            txt: "V",
            fontSize: 14,
            fontWeight: FontSizeAndWidth.bold,
            color: primaryColor2,
          ),
        ),
        SizedBox(width: 8.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextWidget(
              txt: "Version",
              fontSize: 11,
              fontWeight: FontSizeAndWidth.regular,
              color: Colors.white60,
            ),
            TextWidget(
              txt: "0.01",
              fontSize: 15,
              fontWeight: FontSizeAndWidth.semiBold,
              color: primaryColor2,
            ),
          ],
        ),
      ],
    );
  }
}


















/*

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  SettingViewModel settingViewModel = SettingViewModel();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SettingViewModel>(context, listen: false).getSettingsList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: appBar(),
      backgroundColor: settingsBgColor,
      body: Consumer<SettingViewModel>(
        builder: (context, viewModel, child) {
          return Container(
            color: settingsBgColor,
            child: Column(children: [
              CustomAppBar(
                showLeading: true,
                title: "Settings",
                isLightTheme: settingsTextColor != whiteColor,
                margin: EdgeInsets.fromLTRB(15.w, MediaQuery.of(context).padding.top + 20.h, 20.w, 3.h),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(10.r),
                  child: Column(
                    children: [
                      ListView.builder(
                        itemCount: viewModel.settingsList.length,
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(0),
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          return notificationItem(settingsItem: viewModel.settingsList[index], viewModel: viewModel, index: index);
                        },
                      ),
                      bottomWidget()
                    ],
                  ),
                ),
              )
            ]),
          );
        },
      ),
    );
  }

  // appBar() {
  //   return AppBar(
  //     title: TextWidget(
  //       txt: "Settings",
  //       fontSize: FontSizeAndWidth.title,
  //       fontWeight: FontSizeAndWidth.medium,
  //       color: appBarTxtColor,
  //     ),
  //     centerTitle: false,
  //     backgroundColor: appBarColor,
  //   );
  // }

  Widget notificationItem({required SettingsModel settingsItem, required SettingViewModel viewModel, required int index}) {
    return CustomInkwell(
      onTap: () {
        if (settingsItem.image.isNotEmpty) {
          viewModel.moveToNext(context, moveToNext: settingsItem.redirectTo);
        }
      },
      childWidget: Container(
        height: 40.h,
        margin: EdgeInsets.only(top: 10.r, bottom: 10.r, right: 10.r),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40.w,
              alignment: Alignment.center,
              margin: EdgeInsets.only(right: 10.w),
              child: settingsItem.image.isNotEmpty
                  ? CommonMethods.assetImage(
                      height: settingsItem.size,
                      width: settingsItem.size,
                      img: settingsItem.image,
                      isSvg: true,
                      color: settingsIconColor,
                    )
                  : Icon(
                      settingsItem.icon,
                      color: settingsIconColor,
                      size: settingsItem.size,
                    ),
            ),
            Expanded(
              child: Container(
                height: 40.h,
                alignment: Alignment.centerLeft,
                child: TextWidget(
                  txt: settingsItem.txt,
                  fontSize: FontSizeAndWidth.title,
                  fontWeight: FontSizeAndWidth.regular,
                  color: settingsTextColor,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  bottomWidget() {
    return Container(
      margin: EdgeInsets.only(top: 50.h, bottom: 50),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          help(),
          version(),
        ],
      ),
    );
  }

  help() {
    return InkWell(
      onTap: () {},
      child: Container(
        // margin: const EdgeInsets.only(top: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(2.r),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: primaryColor1, width: 2.r),
              ),
              child: Icon(
                Icons.question_mark,
                color: primaryColor1,
                size: 17.r,
              ),
            ),
            SizedBox(
              width: 5.w,
              // width: 10,
            ),
            TextWidget(
              txt: "Help",
              fontSize: FontSizeAndWidth.subTitle,
              fontWeight: FontSizeAndWidth.medium,
              color: primaryColor1,
            ),
          ],
        ),
      ),
    );
  }

  version() {
    return Container(
      // margin: const EdgeInsets.only(top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(3.r),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: primaryColor1, width: 2.r),
            ),
            child: TextWidget(
              txt: "V",
              fontSize: FontSizeAndWidth.smallText,
              fontWeight: FontSizeAndWidth.bold,
              color: primaryColor1,
            ),
          ),
          SizedBox(
            width: 5.w,
          ),
          TextWidget(
            txt: "0.01",
            fontSize: FontSizeAndWidth.subTitle,
            fontWeight: FontSizeAndWidth.medium,
            color: primaryColor1,
          ),
        ],
      ),
    );
  }
}*/
