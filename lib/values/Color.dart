import 'package:flutter/material.dart';

import '../utils/SessionManager.dart';
import 'StaticText.dart';
const primaryColor = const Color(0xFFF4F3EE);

Color primaryColor1 = const Color(0xFF407BFF);
Color primaryColor2 = const Color(0xFF26B2FD);

Color borderColor1 = const Color(0xFF8EC5FC);
Color borderColor2 = const Color(0xFFE0C3FC);

// ✅ DARK THEME COLORS
Color bgColor = const Color(0xFF121212); // Changed from white to dark
Color appBarTxtColor = const Color(0xFFFFFFFF); // Changed from black to white
Color appBarColor = const Color(0xFF121212); // Changed from white to dark
Color appBarIconColor = const Color(0xFFFFFFFF); // Changed from black to white
Color senderListNameColor = const Color(0xFFFFFFFF); // Changed from black to white
Color senderListMsgColor = const Color(0xFFB0B0B0); // Lighter grey for better contrast
Color senderListColor = const Color(0xFF1E1E1E); // Dark card background
Color textFieldTxtColor = const Color(0xFFFFFFFF); // Changed from black to white
Color textFieldBorderColor = const Color(0xFF404040); // Darker grey border
Color acceptColor = const Color(0xFF26B2FD);
Color settingsIconColor = const Color(0xFFFFFFFF); // Changed from black to white
Color settingsTextColor = const Color(0xFFFFFFFF); // Changed from black to white
Color settingsBgColor = const Color(0xFF121212); // Changed from white to dark
Color connectUserCardColor = const Color(0xFF1E1E1E); // Dark card background

const blackColor = const Color(0xff000000);
const whiteColor = const Color(0xFFFFFFFF);
const greyColor = const Color(0xFFC4C4C4);

const lightGreyColor = const Color(0xFF404040); // Darker for dark theme
const popupBackgroundColor = const Color(0xFF1E1E1E); // Dark popup background
const textColor = const Color(0xFFFFFFFF); // White text
const lightTextColor = const Color(0xFFB0B0B0); // Light grey text
const popUpColor = const Color(0xFF1E1E1E); // Dark popup

const colorDarkBlue = Color.fromRGBO(4, 48, 123, 1.0);

var colors = [
  Colors.red.withOpacity(0.3),
  Colors.blue.withOpacity(0.3),
  Colors.green.withOpacity(0.3),
  Colors.brown.withOpacity(0.3),
  Colors.pink.withOpacity(0.3),
  Colors.indigoAccent.withOpacity(0.3),
  Colors.cyan.withOpacity(0.3),
];

var liteColors = [
  Colors.red.withOpacity(0.2),
  Colors.blue.withOpacity(0.2),
  Colors.green.withOpacity(0.2),
  Colors.brown.withOpacity(0.3),
  Colors.pink.withOpacity(0.2),
  Colors.indigoAccent.withOpacity(0.3),
  Colors.cyan.withOpacity(0.2),
];

getThemeColor() async {
  var getPrimaryColor = await SessionManager.getStringData(SessionManager.PRIMARY_THEME_COLOR);
  bool isAPI = false;
  if (isAPI) {
    primaryColor1 = getPrimaryColor.isNotEmpty ? hexToColor(getPrimaryColor) : primaryColor;
    primaryColor2 = getPrimaryColor.isNotEmpty ? hexToColor(getPrimaryColor) : primaryColor;
    appBarColor = getPrimaryColor.isNotEmpty ? hexToColor(getPrimaryColor) : primaryColor;
    appBarTxtColor = getPrimaryColor.isNotEmpty ? hexToColor(getPrimaryColor) : primaryColor;
    appBarIconColor = getPrimaryColor.isNotEmpty ? hexToColor(getPrimaryColor) : primaryColor;
    senderListNameColor = getPrimaryColor.isNotEmpty ? hexToColor(getPrimaryColor) : primaryColor;
    senderListNameColor = getPrimaryColor.isNotEmpty ? hexToColor(getPrimaryColor) : primaryColor;
    senderListColor = getPrimaryColor.isNotEmpty ? hexToColor(getPrimaryColor) : primaryColor;
    textFieldTxtColor = getPrimaryColor.isNotEmpty ? hexToColor(getPrimaryColor) : primaryColor;
    textFieldBorderColor = getPrimaryColor.isNotEmpty ? hexToColor(getPrimaryColor) : primaryColor;
    acceptColor = getPrimaryColor.isNotEmpty ? hexToColor(getPrimaryColor) : primaryColor;
    settingsIconColor = getPrimaryColor.isNotEmpty ? hexToColor(getPrimaryColor) : primaryColor;
  } else {
    // primaryColor1 = ConstantLabels.isDarkTheme ? hexToColor(getPrimaryColor) : primaryColor;
    // primaryColor2 = ConstantLabels.isDarkTheme ? hexToColor(getPrimaryColor) : primaryColor;
    // appBarColor = ConstantLabels.isDarkTheme ? hexToColor(getPrimaryColor) : primaryColor;
    // appBarTxtColor = ConstantLabels.isDarkTheme ? hexToColor(getPrimaryColor) : primaryColor;
    // appBarIconColor = ConstantLabels.isDarkTheme ? hexToColor(getPrimaryColor) : primaryColor;
    // senderListNameColor = ConstantLabels.isDarkTheme ? hexToColor(getPrimaryColor) : primaryColor;
    // senderListMsgColor = ConstantLabels.isDarkTheme ? hexToColor(getPrimaryColor) : primaryColor;
    // senderListColor = ConstantLabels.isDarkTheme ? hexToColor(getPrimaryColor) : primaryColor;
    // textFieldTxtColor = ConstantLabels.isDarkTheme ? hexToColor(getPrimaryColor) : primaryColor;
    // textFieldBorderColor = ConstantLabels.isDarkTheme ? hexToColor(getPrimaryColor) : primaryColor;
    // acceptColor = ConstantLabels.isDarkTheme ? hexToColor(getPrimaryColor) : primaryColor;
    // settingsIconColor = ConstantLabels.isDarkTheme ? hexToColor(getPrimaryColor) : primaryColor;
  }
}

Color hexToColor(String code) {
  Color color = const Color(0xFF000000);
  if (code.isNotEmpty) {
    color = Color(int.parse(code.substring(1, 7), radix: 16) + 0xFF000000);
  }
  return color;
}
