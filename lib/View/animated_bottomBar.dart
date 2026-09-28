import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:mikk/values/Color.dart';

import 'Dashboard.dart';

class AnimatedBottomBar extends StatefulWidget {
  const AnimatedBottomBar({super.key});

  @override
  _AnimatedBottomBarState createState() => _AnimatedBottomBarState();
}

class _AnimatedBottomBarState extends State<AnimatedBottomBar> {
  int _page = 0;
  GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();
  List<Widget> screenList = [
    const Dashboard(),
    // ChatScreen(),
    // ChatScreen(),
    // ChatScreen(),
    // ChatScreen(),
  ];
  DateTime? _lastBackPressTime;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          final now = DateTime.now();
          if (_lastBackPressTime == null ||
              now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
            _lastBackPressTime = now;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Press back again to exit"),
                duration: Duration(seconds: 2),
              ),
            );
            return false;
          }
          return true; // Exit the app
        },
        child: Scaffold(
          body: screenList[_page],
          bottomNavigationBar: CurvedNavigationBar(
            key: _bottomNavigationKey,
            index: 0,
            items: const <Widget>[
              Icon(Icons.home, size: 30, color: whiteColor),
              Icon(Icons.chat, size: 30, color: whiteColor),
              Icon(Icons.compare_arrows, size: 30, color: whiteColor),
              Icon(Icons.call_split, size: 30, color: whiteColor),
              Icon(
                Icons.perm_identity,
                size: 30,
                color: whiteColor,
              ),
            ],
            color: Colors.blueAccent,
            buttonBackgroundColor: Colors.blueAccent,
            backgroundColor: Colors.blueAccent,
            animationCurve: Curves.easeInOut,
            animationDuration: const Duration(milliseconds: 600),
            onTap: (index) {
              setState(() {
                _page = index;
              });
            },
            letIndexChange: (index) => true,
          ),
        ));
  }
}
