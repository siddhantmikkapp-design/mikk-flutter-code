import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mikk/View/ConnectWithUserScreen.dart';
import 'package:mikk/values/ImageUrl.dart';
import '../utils/CommonMethods.dart';
import '../values/Color.dart';
import 'Dashboard.dart';
import 'DashboardScreens/UserSearchScreen.dart';
import 'Notification.dart';
import 'Profile.dart';

class CustomBottomNavigationBar extends StatefulWidget {
  const CustomBottomNavigationBar({
    super.key,
  });

  @override
  State<CustomBottomNavigationBar> createState() => _CustomBottomNavigationBarState();
}

class _CustomBottomNavigationBarState extends State<CustomBottomNavigationBar> {
  int _currentIndex = 0;

  // Method to navigate to home
  void _navigateToHome() {
    setState(() {
      _currentIndex = 0;
    });
  }

  // List of screens for each tab with callbacks
  List<Widget> get _screens => [
    const Dashboard(),
    UserSearchScreen(
      onBackToHome: _navigateToHome, // Pass callback
    ),
  /*  const ConnectWithUserScreen(),
     NotificationScreen(
      onBackToHome: _navigateToHome,
    ),*/
    Profile(
      onBackToHome: _navigateToHome,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border(
            top: BorderSide(
              color: Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            backgroundColor: Colors.transparent,
            selectedItemColor: whiteColor,
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            items: [
              BottomNavigationBarItem(
                icon: SvgPicture.asset(
                  'assets/icons/homein.svg',
                  width: 25,
                  height: 25,
                  colorFilter: ColorFilter.mode(
                    Colors.grey,
                    BlendMode.srcIn,
                  ),
                ),
                activeIcon: SvgPicture.asset(
                  'assets/icons/homeout.svg',
                  width: 25,
                  height: 25,
                  colorFilter: ColorFilter.mode(
                    whiteColor,
                    BlendMode.srcIn,
                  ),
                ),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: SvgPicture.asset(
                  'assets/icons/ic_search.svg',
                  width: 25,
                  height: 25,
                  colorFilter: ColorFilter.mode(
                    Colors.grey,
                    BlendMode.srcIn,
                  ),
                ),
                activeIcon: SvgPicture.asset(
                  'assets/icons/ic_search.svg',
                  width: 25,
                  height: 25,
                  colorFilter: ColorFilter.mode(
                    whiteColor,
                    BlendMode.srcIn,
                  ),
                ),
                label: '',
              ),
           /*   BottomNavigationBarItem(
                icon: SvgPicture.asset(
                  'assets/icons/addd.svg',
                  width: 25,
                  height: 25,
                  colorFilter: ColorFilter.mode(
                    Colors.grey,
                    BlendMode.srcIn,
                  ),
                ),
                activeIcon: SvgPicture.asset(
                  'assets/icons/addout.svg',
                  width: 25,
                  height: 25,
                  colorFilter: ColorFilter.mode(
                    whiteColor,
                    BlendMode.srcIn,
                  ),
                ),
                label: '',
              ),*/
            /*  BottomNavigationBarItem(
                icon: SvgPicture.asset(
                  'assets/icons/notification_in.svg',
                  width: 25,
                  height: 25,
                  colorFilter: ColorFilter.mode(
                    Colors.grey,
                    BlendMode.srcIn,
                  ),
                ),
                activeIcon: SvgPicture.asset(
                  'assets/icons/notification_out.svg',
                  width: 25,
                  height: 25,
                  colorFilter: ColorFilter.mode(
                    whiteColor,
                    BlendMode.srcIn,
                  ),
                ),
                label: '',
              ),*/
              BottomNavigationBarItem(
                icon: SvgPicture.asset(
                  'assets/icons/ic_profilein.svg',
                  width: 26,
                  height: 26,
                  colorFilter: ColorFilter.mode(
                    Colors.grey,
                    BlendMode.srcIn,
                  ),
                ),
                activeIcon: SvgPicture.asset(
                  'assets/icons/ic_profilee.svg',
                  width: 26,
                  height: 26,
                  colorFilter: ColorFilter.mode(
                    whiteColor,
                    BlendMode.srcIn,
                  ),
                ),
                label: '',
              ),
            ],
          ),
        ),
      ),
    );
  }
}





/*class CustomBottomNavigationBar extends StatefulWidget {
  CustomBottomNavigationBar({
    super.key,
  });

  @override
  State<CustomBottomNavigationBar> createState() => _CustomBottomNavigationBarState();
}

class _CustomBottomNavigationBarState extends State<CustomBottomNavigationBar> {
  bool isLoading = false;
  double screenWidth = 0.0;
  double screenHeight = 0.0;
  int step = 0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    screenHeight = MediaQuery
        .of(context)
        .size
        .height;
    return Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: false,
        body: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            step == 0
                ? const Dashboard()
                : step == 1
                ? const ConnectWithUserScreen()
                : const NotificationScreen(),
            bottomBarCustom(context),
            // isLoading ? Loader() : Container()
          ],
        ));
  }

  Widget bottomBarCustom(BuildContext context) {
    return Container(
      // height: screenHeight,
      // height: 100,//screenHeight,
      color: Colors.transparent,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Visibility(
            visible: false,
            child: Container(
              height: 100,
              // color: Colors.blue,
              margin: EdgeInsets.only(
                  left: screenWidth / 4, right: screenWidth / 4, bottom: 65),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                    sittingTypeUI(icon: Icons.computer_rounded),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                        sittingTypeUI(icon: Icons.people_outline_sharp),
                        sittingTypeUI(icon: Icons.groups_outlined),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 25),
            padding: const EdgeInsets.all(20),
            alignment: Alignment.bottomCenter,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: const BorderRadius.all(
                Radius.circular(10),
              ),
              boxShadow: [
                BoxShadow(
                  color: greyColor.withOpacity(0.4),
                  blurRadius: 10.0,
                  spreadRadius: 1.0,
                  offset: const Offset(
                    0.0,
                    -5.0,
                  ),
                )
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            // mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              bottomButton(
                index: 0,
                icon1: Icons.language,
                icon2: Icons.language,
              ),
              bottomButton(
                index: 1,
                icon1: Icons.add,
                icon2: Icons.add_box,
              ),
              // Container(),
              bottomButton(
                  index: 2,
                  // icon1: Icons.person, icon2: Icons.person_2_outlined,
                  image: ImageUrl.ic_notification),
            ],
          ),
          // floatingButton(context),
        ],
      ),
    );
  }

  bottomButton({
    IconData? icon1,
    IconData? icon2,
    int index = 0,
    String image = "",
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          // checkRole();
          step = index;
        });
      },
      child: Container(
          height: index == step ? 70 : 50,
          width: index == step ? 70 : 50,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.all(
              Radius.circular(50.0),
            ),
            boxShadow: [
              index == step
                  ? BoxShadow(
                color: greyColor.withOpacity(0.2),
                blurRadius: 5.0,
                // spreadRadius: 2,
                offset: const Offset(0.0, -10.0),
              )
                  : BoxShadow(
                color: greyColor.withOpacity(0),
                blurRadius: 0,
              )
            ],
          ),
          margin: EdgeInsets.only(
              bottom: index == step ? 20.0 : 0, top: index == step ? 0 : 25),
          padding: const EdgeInsets.all(10.0),
          child: Container(
            padding: EdgeInsets.all(
                (image.isNotEmpty && index == step) ? 10 : 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              color: index == step ? primaryColor1 : Colors.transparent,
              gradient: LinearGradient(
                colors: [
                  borderColor1.withOpacity(1),
                  borderColor2.withOpacity(1)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: image.isNotEmpty
                ? CommonMethods.assetImage(
              img: ImageUrl.ic_notification,
              isSvg: true,
              height: 20.0.h,
              width: 20.0.w,
              color: index == step ? whiteColor : Colors.black,
            )
                : Icon(
              index == step ? icon1 : icon2,
              color: index == step ? whiteColor : Colors.black,
              size: index == step ? 40 : 30,
            ),
          )),
    );
  }
}
  sittingTypeUI({required IconData icon}) {
    return Column(
      children: [
        Container(
          height: 45,
          width: 45,
          margin: const EdgeInsets.only(bottom: 5),
          decoration: const BoxDecoration(shape: BoxShape.rectangle, color: Colors.black),
          child: Icon(
            icon,
            size: 30,
            color: primaryColor1,
          ),
        ),
      ],
    );
  }*/

