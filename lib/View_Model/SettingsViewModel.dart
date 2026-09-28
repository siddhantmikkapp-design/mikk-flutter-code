import 'package:flutter/material.dart';
import 'package:mikk/Demo/AvatarDashBoard.dart';
import 'package:mikk/View/SettingsDetailScreen/NotificationSettingsScreen.dart';
import 'package:mikk/View/SettingsDetailScreen/PrivacySecurity.dart';
import 'package:mikk/utils/CommonMethods.dart';
import 'package:mikk/utils/LogHelper.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Model/SettingsModel.dart';
import '../View/DetailScreens/PersonalInformation.dart';
import '../View/SettingsScreen.dart';
import '../values/ImageUrl.dart';
import '../values/Color.dart';
import '../values/StaticText.dart';
import 'DashboardViewModel.dart';

class SettingViewModel with ChangeNotifier {
  List<SettingsModel> settingsList = [];
  bool isDarkTheme = false;

  moveToNext(BuildContext context, {Widget? moveToNext,String? url,String? share}){
    if(moveToNext != null) {
      CommonMethods.goToNext(context, moveToNext);
    }else if (url != null && url.isNotEmpty) {
      _launchURL(url);
    } else if (share != null && share.isNotEmpty) {
      inviteFriends();
    }

  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> inviteFriends() async {
    try {
      const String appLink = 'https://play.google.com/store/apps/details?id=com.mikklabs.mikk'; // Replace with your app link
      const String message = '''
Hey! 👋

I've been using this amazing app and thought you might like it too!

Check it out here: $appLink

Download now and join me! 🚀
      ''';

      await Share.share(message);
    } catch (e) {
      print('Error sharing: $e');
    }
  }





 /* Future<void>updateAppTheme(BuildContext context) async {
    isDarkTheme = !isDarkTheme;
    bgColor = isDarkTheme  ? blackColor : whiteColor;
    settingsIconColor = isDarkTheme ? whiteColor : blackColor;
    settingsTextColor = isDarkTheme ? whiteColor : blackColor;
    settingsBgColor = isDarkTheme ? blackColor : whiteColor;

    appBarColor = isDarkTheme ? blackColor : whiteColor;
    appBarTxtColor = isDarkTheme ?  whiteColor : blackColor;
    appBarIconColor = isDarkTheme ?  whiteColor : blackColor;
    senderListNameColor = isDarkTheme ?  whiteColor : blackColor;
    connectUserCardColor = isDarkTheme ?  lightGreyColor : Color(0xFFF5F6FA);

    if(settingsList.isNotEmpty) {
      settingsList.where((element) => element.image.isEmpty).first.icon = isDarkTheme ? Icons.toggle_on : Icons.toggle_off_outlined;
    }
    Provider.of<DashboardViewModel>(context, listen: false).setLoading(false);

    notifyListeners();
  }*/

  void getSettingsList() {
    settingsList = [];
    LogHelper("settingsList ${settingsList.length}");
    settingsList.add(SettingsModel(icon: Icons.book_sharp, txt: "Account Information", image: ImageUrl.ic_personal_info, size: 40,redirectTo:PersonalInformation()));
    settingsList.add(SettingsModel(icon: Icons.lock, txt: "Privacy & Safety", image: ImageUrl.ic_lock,redirectTo: PrivacySecurity(),));
    settingsList.add(SettingsModel(icon: Icons.notifications, txt: "Notification", image: ImageUrl.ic_notification,redirectTo: NotificationSettingsScreen()));
    settingsList.add(SettingsModel(icon: Icons.note_sharp, txt: "Term & Privacy Policy", image: ImageUrl.ic_info, size: 40,url: "https://mikk.live/terms-of-service/"));
    settingsList.add(SettingsModel(icon: Icons.favorite, txt: "Invite Friends", image: ImageUrl.ic_Invite, size: 40, share: "hshsh"));


    // settingsList.add(SettingsModel(icon: Icons.headphones, txt: "Help Center", image: ImageUrl.ic_help));
    LogHelper("settingsList ${settingsList.length}");
    notifyListeners();
  }
}
