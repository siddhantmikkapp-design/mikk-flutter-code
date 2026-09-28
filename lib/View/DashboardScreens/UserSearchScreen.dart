import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mikk/Model/SearchModel.dart';
import 'package:mikk/Model/auth/UserNameModel.dart';
import 'package:mikk/View_Model/FollowerFollowingViewModel.dart';
import 'package:provider/provider.dart';

import '../../View_Model/DashboardViewModel.dart';
import '../../View_Model/SearchViewModel.dart';
import '../../resources/CustomTextField.dart';
import '../../resources/Custom_InkWell.dart';
import '../../resources/GradientBorder.dart';
import '../../resources/TextWidget.dart';
import '../../utils/CommonMethods.dart';
import '../../utils/LogHelper.dart';
import '../../values/AppFontStyleAndSize.dart';
import '../../values/Color.dart';
import '../Profile.dart';



class UserSearchScreen extends StatefulWidget {
  final VoidCallback? onBackToHome;
  const UserSearchScreen({super.key, this.onBackToHome});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Consumer<SearchViewModel>(
        builder: (context, searchVM, child) {
          return Column(
            children: [
              _buildHeader(searchVM: searchVM),
              Expanded(
                child: searchVM.isLoader
                    ? _buildLoader()
                    : searchVM.searchUsers.isEmpty
                    ? _buildEmptyState(searchVM)
                    : _buildSearchResults(searchVM: searchVM),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader({required SearchViewModel searchVM}) {
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
          child: Column(
            children: [
              Row(
                children: [
                  // Back Button
                  GestureDetector(
                    onTap: () {
                      widget.onBackToHome?.call();
                    },
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

                  // Search Field
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: Colors.white60, size: 20.r),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: TextField(
                              controller: searchVM.searchController,
                              autofocus: false,
                              maxLength: 5, // Limit to 5 characters
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                letterSpacing: 2, // Better spacing for ID
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter 5-digit ID',
                                hintStyle: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 14,
                                  letterSpacing: 0,
                                  fontWeight: FontWeight.w400,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                counterText: "", // Hide character counter
                              ),
                              onChanged: (value) {
                                LogHelper("Search input changed: '$value' (${value.length}/5)");
                                searchVM.fetchSearchUserById(searchTxt: value);
                              },
                            ),
                          ),
                          if (searchVM.searchController.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                searchVM.resetSearch(isClearController: true);
                              },
                              child: Icon(
                                Icons.close,
                                color: Colors.white60,
                                size: 20.r,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Character counter indicator
              SizedBox(height: 12.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  bool isFilled = searchVM.searchController.text.length > index;
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    width: 10.w,
                    height: 10.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled
                          ? primaryColor2
                          : Colors.white.withOpacity(0.2),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoader() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: primaryColor2,
            strokeWidth: 3,
          ),
          SizedBox(height: 16.h),
          TextWidget(
            txt: "Searching...",
            fontSize: 14,
            fontWeight: FontSizeAndWidth.medium,
            color: Colors.white60,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(SearchViewModel searchVM) {
    // Show different message based on input length
    bool hasInput = searchVM.searchController.text.isNotEmpty;
    bool isComplete = searchVM.searchController.text.length == 5;

    String mainText = hasInput
        ? (isComplete ? "No User Found" : "Keep typing...")
        : "Type your friends ID";

    String subText = hasInput
        ? (isComplete ? "No user exists with this ID" : "${5 - searchVM.searchController.text.length} more characters")
        : "Enter exactly 5 characters to find a user";

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
            child: Icon(
              hasInput && isComplete ? Icons.person_off : Icons.search,
              size: 80.r,
              color: Colors.white70,
            ),
          ),
          SizedBox(height: 24.h),
          TextWidget(
            txt: mainText,
            fontSize: 20,
            fontWeight: FontSizeAndWidth.bold,
            color: Colors.white70,
          ),
          SizedBox(height: 12.h),
          TextWidget(
            txt: subText,
            fontSize: 14,
            fontWeight: FontSizeAndWidth.regular,
            color: Colors.white60,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults({required SearchViewModel searchVM}) {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 100.h),
      physics: const BouncingScrollPhysics(),
      itemCount: searchVM.searchUsers.length,
      itemBuilder: (context, index) {
        return _buildSearchedUserItem(
          searchedUser: searchVM.searchUsers[index],
        );
      },
    );
  }

  Widget _buildSearchedUserItem({
    required SearchModel searchedUser,
  }) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        // Navigate to profile or detail screen
         CommonMethods.goToNext(context, Profile(user: searchedUser));
        LogHelper("Tapped on user: ${searchedUser.name}");
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
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Profile Picture
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor2, primaryColor2],
                ),
                borderRadius: BorderRadius.circular(14.r),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor2.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: EdgeInsets.all(2.r),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: SizedBox(
                  height: 60.h,
                  width: 60.h,
                  child: searchedUser.profilePic != null &&
                      searchedUser.profilePic!.isNotEmpty
                      ? CachedNetworkImage(
                    imageUrl: searchedUser.profilePic!,
                    placeholder: (context, url) => Container(
                      color: const Color(0xFF1E1E1E),
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Container(
                      color: const Color(0xFF1E1E1E),
                      child: Icon(
                        Icons.person,
                        size: 32.r,
                        color: Colors.white30,
                      ),
                    ),
                  )
                      : Container(
                    color: const Color(0xFF1E1E1E),
                    child: Icon(
                      Icons.person,
                      size: 32.r,
                      color: Colors.white30,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(width: 16.w),

            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextWidget(
                    txt: searchedUser.name ?? "Unknown",
                    fontSize: 17,
                    fontWeight: FontSizeAndWidth.semiBold,
                    color: Colors.white,
                    maxLines: 1,
                  ),
                  SizedBox(height: 6.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
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
                          size: 14.r,
                        ),
                        SizedBox(width: 4.w),
                        TextWidget(
                          txt: searchedUser.id ?? 'N/A',
                          fontSize: 13,
                          fontWeight: FontSizeAndWidth.semiBold,
                          color: primaryColor2,

                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Chevron Icon
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
}


/*class UserSearchScreen extends StatefulWidget {

  final VoidCallback? onBackToHome;
  const UserSearchScreen({super.key, this.onBackToHome});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardViewModel>(context, listen: false).fetchAllUserName();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Consumer<DashboardViewModel>(
        builder: (context, dashboardVM, child) {
          return Column(
            children: [
              _buildHeader(dashboardVM: dashboardVM),
              Expanded(
                child: dashboardVM.searchUsers.isEmpty
                    ? _buildEmptyState()
                    : _buildSearchResults(dashboardVM: dashboardVM),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader({required DashboardViewModel dashboardVM}) {
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
          child: Column(
            children: [
              Row(
                children: [
                  // Back Button
                  GestureDetector(
                    onTap: () {
                      // Call the callback to navigate to home
                      widget.onBackToHome?.call();
                    },
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

                  // Search Field
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: Colors.white60, size: 20.r),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: TextField(
                              controller: dashboardVM.searchController,
                              autofocus: false,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search users...',
                                hintStyle: TextStyle(color: Colors.white70),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (value) {
                                if (value.length > 2) {
                                  dashboardVM.fetchSearchUserName(searchTxt: value);
                                } else {
                                  dashboardVM.resetSearch();
                                }
                              },
                            ),
                          ),
                          if (dashboardVM.searchController.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                dashboardVM.resetSearch(isClearController: true);
                              },
                              child: Icon(
                                Icons.close,
                                color: Colors.white60,
                                size: 20.r,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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
            child: Icon(
              Icons.search,
              size: 80.r,
              color: Colors.white70,
            ),
          ),
          SizedBox(height: 24.h),
          TextWidget(
            txt: "Type your friends ID here",
            fontSize: 20,
            fontWeight: FontSizeAndWidth.bold,
            color: Colors.white70,
          ),
          SizedBox(height: 12.h),
          TextWidget(
            txt: "Type at least 5 characters to search ID",
            fontSize: 14,
            fontWeight: FontSizeAndWidth.regular,
            color: Colors.white70,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults({required DashboardViewModel dashboardVM}) {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 100.h),
      physics: const BouncingScrollPhysics(),
      itemCount: dashboardVM.searchUsers.length,
      itemBuilder: (context, index) {
        return _buildSearchedUserItem(
          searchedUser: dashboardVM.searchUsers[index],
          dashboardVM: dashboardVM,
        );
      },
    );
  }

  Widget _buildSearchedUserItem({
    required UserNameModel searchedUser,
    required DashboardViewModel dashboardVM,
  }) {
    return Consumer<FollowerFollowingViewModel>(
      builder: (context, followerVM, child) {
        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            CommonMethods.goToNext(
              context,
              Profile(
                user: searchedUser,
                isRequestSent: searchedUser.isRequestSent,
              ),
            );
          },
          child: Container(
            margin: EdgeInsets.only(bottom: 8.h),
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
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Profile Picture
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor2, primaryColor2],
                    ),
                    borderRadius: BorderRadius.circular(14.r),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor1.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(2.r),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: SizedBox(
                      height: 56.h,
                      width: 56.h,
                      child: CachedNetworkImage(
                        imageUrl: searchedUser.profilePic.toString(),
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
                          child: Icon(
                            Icons.person,
                            size: 30.r,
                            color: Colors.white30,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 12.w),

                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextWidget(
                        txt: searchedUser.name ?? "Unknown",
                        fontSize: 16,
                        fontWeight: FontSizeAndWidth.semiBold,
                        color: Colors.white,
                        maxLines: 1,
                      ),
                      SizedBox(height: 4.h),
                      TextWidget(
                        txt: "@${searchedUser.userName ?? ''}",
                        fontSize: 13,
                        fontWeight: FontSizeAndWidth.regular,
                        color: Colors.white60,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),

                // Follow Button (Hidden as per original code)
                *//*
                GestureDetector(
                  onTap: () {
                    if (!(searchedUser.isRequestSent ?? false)) {
                      followerVM.setLoading(true);
                      followerVM.addFollowerDataFirebase(
                        context,
                        searchedUser: searchedUser,
                      ).then((value) {
                        followerVM.setLoading(false);
                      });
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      gradient: (searchedUser.isRequestSent ?? false)
                          ? null
                          : const LinearGradient(
                              colors: [primaryColor1, primaryColor2],
                            ),
                      color: (searchedUser.isRequestSent ?? false)
                          ? Colors.white.withOpacity(0.1)
                          : null,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: (searchedUser.isRequestSent ?? false)
                            ? Colors.white.withOpacity(0.2)
                            : Colors.transparent,
                      ),
                    ),
                    child: TextWidget(
                      txt: (searchedUser.isRequestSent ?? false) ? "Sent" : "Follow",
                      fontSize: 13,
                      fontWeight: FontSizeAndWidth.semiBold,
                      color: Colors.white,
                    ),
                  ),
                ),
                *//*

                // Chevron Icon
                Icon(
                  Icons.chevron_right,
                  color: Colors.white70,
                  size: 24.r,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}*/





























/*
class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardViewModel>(context, listen: false).fetchAllUserName();
      // Provider.of<DashboardViewModel>(context, listen: false).fetchSearchUserName(searchTxt: "");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<DashboardViewModel>(
        builder: (context, dashboardVM, child) {
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(10.w, MediaQuery.of(context).padding.top + 10.h, 20.w, 0.h),
            child: Column(
              children: [
                searchField(dashboardVM: dashboardVM),
                ListView.builder(
                  itemCount: dashboardVM.searchUsers.length,
                  shrinkWrap: true,
                  padding: EdgeInsets.only(right: 10),
                  itemBuilder: (context, index) {
                    return searchedUserItem(searchedUser: dashboardVM.searchUsers[index] , dashboardVM:dashboardVM);
                  },
                )
              ],
            ),
          );
        },
      ),
    );
  }

  searchField({required DashboardViewModel dashboardVM}) {
    return Row(
      children: [
        CustomInkwell(
          onTap: () {
            Navigator.pop(context);
          },
          childWidget: Container(
            margin: EdgeInsets.only(left: 5, right: 10),
            child: Icon(
              Icons.arrow_back,
              size: 20.sp,
            ),
          ),
        ),
        Expanded(
          child: CustomTextField(
            controller: dashboardVM.searchController,
            hintText: 'Search here...',
            fieldColor: Colors.white12,
            showBorder: false,
            textFieldInputColor: textFieldTxtColor,
            borderColor: Colors.transparent,
            suffixIcon: dashboardVM.searchController.text.isNotEmpty ? Icon(Icons.close, size: 25.r) : null,
            padding: const EdgeInsets.all(5),
            onChanged: (value) {
              if (value.toString().length > 2) {
                dashboardVM.fetchSearchUserName(searchTxt: value);
              } else {
                dashboardVM.resetSearch();
              }
            },
            onSuffix: () {
              dashboardVM.resetSearch(isClearController: true);
            },
          ),
        ),
      ],
    );
  }

  Widget searchedUserItem({required UserNameModel searchedUser, required DashboardViewModel dashboardVM}) {
    return Consumer<FollowerFollowingViewModel>(
      builder: (context, followerVM, child) {
        return CustomInkwell(
            onTap: (){
              FocusScope.of(context).unfocus();
              CommonMethods.goToNext(context, Profile(user:searchedUser,isRequestSent  : searchedUser.isRequestSent));
            },
            childWidget: Container(
            margin: EdgeInsets.all(2.r),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    GradientBorder(
                      height: 50.h,
                      width: 50.h,
                      margin: EdgeInsets.fromLTRB(5.w, 5.h, 10.w, 5.h),
                      padding: EdgeInsets.all(0),
                      /// padding: EdgeInsets.all(5.r),
                      borderRadiusTopLeft: 10.r,
                      // borderRadiusTopRight : 10,
                      // borderRadiusBottomLeft : 10,
                      borderRadiusBottomRight: 10.r,
                      backgroundColor: greyColor,
                      isBoxShadow: false,
                      radius: 0,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(10),
                          bottomRight: Radius.circular(10),
                        ),
                        child: CachedNetworkImage(
                          height: 50.h,
                          width: 50.h,
                          imageUrl: searchedUser.profilePic.toString(),
                          // imageUrl: searchedUser.userProfile != null ? searchedUser.userProfile!.profilePic.toString() : "",
                          placeholder: (context, url) => const CircularProgressIndicator(),
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Container(
                            padding: const EdgeInsets.all(10),
                            child: (dashboardVM.isLoader || followerVM.isLoader) ? const CircularProgressIndicator() : const Icon(Icons.error,size: 0),
                          ),
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextWidget(
                          txt: "${searchedUser.name}",
                          fontSize: FontSizeAndWidth.subTitle,
                          fontWeight: FontSizeAndWidth.bold,
                          color: senderListNameColor,
                        ),
                        TextWidget(
                          txt: "${searchedUser.userName}",
                          fontSize: FontSizeAndWidth.smallText,
                          fontWeight: FontSizeAndWidth.regular,
                          color: senderListNameColor,
                        )
                      ],
                    )
                  ],
                ),
                CustomInkwell(
                  onTap: () {
                    if(!(searchedUser.isRequestSent ?? false)) {
                      followerVM.setLoading(true);
                      followerVM.addFollowerDataFirebase(context, searchedUser: searchedUser).then((value) {
                        followerVM.setLoading(false);
                      },);
                    }
                  },
                  childWidget: Visibility(
                    visible: false,
                    child: Container(
                      padding: EdgeInsets.fromLTRB(10.w, 5.h, 10.w, 5.h),
                      decoration: BoxDecoration(
                        color: (searchedUser.isRequestSent ?? false) ? Colors.grey.shade300 : primaryColor1,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextWidget(
                        txt: searchedUser.isRequestSent ?? false ? "send" : "Follow",
                        fontSize: FontSizeAndWidth.tinyText,
                        fontWeight: FontSizeAndWidth.medium,
                        color: whiteColor,
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}*/
