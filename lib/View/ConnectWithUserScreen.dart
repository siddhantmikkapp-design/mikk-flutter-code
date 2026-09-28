import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mikk/Model/ConnectWithUsers.dart';
import 'package:mikk/Model/auth/UserNameModel.dart';
import 'package:mikk/View/Profile.dart';
import 'package:mikk/resources/Custom_InkWell.dart';
import 'package:mikk/resources/GradientBorder.dart';
import 'package:mikk/resources/TextWidget.dart';
import 'package:mikk/utils/CommonMethods.dart';
import 'package:mikk/values/AppFontStyleAndSize.dart';
import 'package:provider/provider.dart';
import '../View_Model/SettingsDetailViewModel/PersonalInformationViewModel.dart';
import '../View_Model/SettingsViewModel.dart';
import '../utils/LogHelper.dart';
import '../values/Color.dart';

class ConnectWithUserScreen extends StatefulWidget {
  const ConnectWithUserScreen({super.key});

  @override
  State<ConnectWithUserScreen> createState() => _ConnectWithUserScreenState();
}

class _ConnectWithUserScreenState extends State<ConnectWithUserScreen> {
  double screenHeight = 0.0;
  double screenWidth = 0.0;

  @override
  void initState() {
    super.initState();
    fillData();
  }

  fillData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PersonalInformationViewModel>(context, listen: false).getAllUserData();
    });
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.sizeOf(context).height;
    screenWidth = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Consumer<PersonalInformationViewModel>(
              builder: (context, personalInfoVM, child) {
                if (personalInfoVM.allUsersData.isEmpty) {
                  return _buildEmptyState();
                }

                return GridView.builder(
                  padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 100.h),
                  itemCount: personalInfoVM.allUsersData.length,
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16.h,
                    crossAxisSpacing: 16.w,
                    childAspectRatio: 0.75,
                  ),
                  itemBuilder: (context, index) {
                    return _buildUserCard(
                      userItem: personalInfoVM.allUsersData[index],
                      personalInfoVM: personalInfoVM,
                      index: index,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20.w,
        MediaQuery.of(context).padding.top + 16.h,
        20.w,
        16.h,
      ),
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
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white12, Colors.white12],
              ),
              shape: BoxShape.circle

            ),
            child: Icon(
              Icons.people_outline,
              color: Colors.white,
              size: 20.r,
            ),
          ),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextWidget(
                txt: "Connect",
                fontSize: 24,
                fontWeight: FontSizeAndWidth.bold,
                color: Colors.white,
              ),
              TextWidget(
                txt: "Discover new people",
                fontSize: 12,
                fontWeight: FontSizeAndWidth.regular,
                color: Colors.white60,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(32.r),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_outline,
              size: 64.r,
              color: Colors.white30,
            ),
          ),
          SizedBox(height: 24.h),
          TextWidget(
            txt: "No users found",
            fontSize: 18,
            fontWeight: FontSizeAndWidth.semiBold,
            color: Colors.white70,
          ),
          SizedBox(height: 8.h),
          TextWidget(
            txt: "Check back later for new connections",
            fontSize: 14,
            fontWeight: FontSizeAndWidth.regular,
            color: Colors.white70,
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard({
    required ConnectWithUsers userItem,
    required PersonalInformationViewModel personalInfoVM,
    required int index,
  }) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 300 + (index * 50)),
      tween: Tween<double>(begin: 0, end: 1),
      curve: Curves.easeOutCubic,
      builder: (context, double value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          UserNameModel user = UserNameModel(
            userId: userItem.userId.toString(),
            name: userItem.name,
            userName: userItem.userName,
          );
        //  CommonMethods.goToNext(context, Profile(user: user));
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Image
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor2, primaryColor2],
                      ),
                    ),
                    child: CachedNetworkImage(
                      width: double.infinity,
                      height: double.infinity,
                      imageUrl: userItem.profilePic.toString(),
                      placeholder: (context, url) => Container(
                        color: Colors.grey[900],
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[900],
                        child: Icon(
                          Icons.person,
                          size: 40.r,
                          color: Colors.white30,
                        ),
                      ),
                    ),
                  ),
                ),

                // User Info
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: EdgeInsets.all(12.r),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Username
                        TextWidget(
                          txt: userItem.userName.toString(),
                          fontSize: FontSizeAndWidth.descriptionText,
                          fontWeight: FontSizeAndWidth.bold,
                          color: Colors.white,
                          maxLines: 1,
                        ),
                        SizedBox(height: 4.h),
                        // Name
                        TextWidget(
                          txt: userItem.name.toString(),
                          fontSize: 11,
                          fontWeight: FontSizeAndWidth.regular,
                          color: Colors.white60,
                          maxLines: 1,
                        ),
                      ],
                    ),
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