import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:another_flushbar/flushbar.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../resources/CustomRaisedButton.dart';
import '../resources/CustomTextField.dart';
import '../values/AppFontStyleAndSize.dart';
import '../values/Color.dart';
import '../values/ImageUrl.dart';
import '../values/StaticText.dart';
import 'LogHelper.dart';
import 'SessionManager.dart';

class CommonMethods {
  // typedef onPressed_ = void Function();

  //check internet connection
  static Future<bool> isInternetConnected() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi) {
      return true;
    }
    return false;
  }

  /// import shared preference

  static logOut(BuildContext context) async {
    await SessionManager.clearSession();
    // Navigator.pushAndRemoveUntil<dynamic>(
    //   context,
    //   MaterialPageRoute<dynamic>(
    //     builder: (BuildContext context) => const SignIn(resetAppState : true),
    //   ),
    //   (route) => false,
    // );
  }

  // static getPackageInfo() async {
  //   PackageInfo? packageInfo = await PackageInfo.fromPlatform();
  //   String appName = packageInfo!.appName;
  //   String packageName = packageInfo!.packageName;
  //   String version = packageInfo!.version;
  //   String buildNumber = packageInfo!.buildNumber;
  //   LogHelper(
  //       "App Name : $appName, App Package Name: $packageName,App Version: $version, App build Number: $buildNumber");
  //   return packageInfo;
  // }

  static String replaceString(
      {String? originalString, String? replaceTo, String? replaceWith}) {
    final original = originalString!.toLowerCase();
    final find = replaceTo;
    final replaced = replaceWith;
    final newString = original.replaceAll(find!, replaced!);
    LogHelper("newString : $newString");
    return newString;
  }

  static String stringResource(
      {required String key,
      required String alternativeString,
      required List<dynamic> stringResourceList,
      String suffix = ""}) {
    // {required String key, required String alternativeString,required List<Model> stringResourceList,String suffix = ""}) {
    var matched =
        stringResourceList!.where((element) => element.key == key).firstOrNull;
    String str = stringResourceList!.isEmpty
        ? alternativeString
        : matched != null
            ? matched.value!
            : alternativeString;
    // LogHelper("str + suffix ::: ${str + suffix}");
    return str + suffix;
  }

  static String capitalize(String s) {
    return s[0].toUpperCase() + s.substring(1);
  }

  static bool isEmpty(String value) {
    return value.length < 1 || value.toLowerCase() == "null";
  }

  // extension AadharNumberValidator on String {
  static bool isValidAadharNumber(String aadharNumber) {
    if (isEmpty(aadharNumber)) return false;
    return RegExp(r'^[2-9]{1}[0-9]{3}\\s[0-9]{4}\\s[0-9]{4}$')
        .hasMatch(aadharNumber);
  }

  // }

  // extension PanCardValidator on String {
  static bool isValidPanCardNo(String panNumber) {
    if (isEmpty(panNumber)) return false;
    return RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(panNumber);
  }

  // }

  // extension DrivingLicense Validator on String {
  static bool isValidLicenseNo(String number) {
    if (isEmpty(number)) return false;
    return RegExp(
            r'^(([A-Z]{2}[0-9]{2})( )|([A-Z]{2}-[0-9]{2}))((19|20)[0-9][0-9])[0-9]{7}$')
        .hasMatch(number);
  }

  // }

  static bool isNumeric({String? text}) {
    if (text == null) {
      return false;
    }
    return double.tryParse(text) != null;
  }

  static bool isValidEmail(String email) {
    if (isEmpty(email)) return false;
    RegExp regExp = new RegExp(_emailRegex);
    return regExp.hasMatch(email);
  }

  static String _emailRegex = r"[a-zA-Z0-9\\+\\.\\_\\%\\-\\+]{1,256}" +
      "\\@" +
      "[a-zA-Z0-9][a-zA-Z0-9\\-]{0,64}" +
      "(" +
      "\\." +
      "[a-zA-Z0-9][a-zA-Z0-9\\-]{0,25}" +
      ")+";

  /*validate email id or mobile no
  * @param text - input text value
  * */
  static bool validateEmailMobile(String text) {
    if (text == null) {
      return false;
    } else {
      if (isNumeric(text: text)) {
        return validateMobile(text);
      } else {
        return validateEmail(text);
      }
    }
  }

  /* check validation for email
  * @param text - input text value
  * */
  static bool validateEmail(String text) {
    Pattern pattern =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    RegExp regex = RegExp(pattern.toString());
    if (!regex.hasMatch(text))
      return false;
    else
      return true;
  }

  /* check validation for mobile number
  * @param text - input text value
  * */
  static bool validateMobile(String text) {
    return text.length == 10;
  }

  /* change status bar color
  *
  * */
  static void changeStatusBarColor(
      {Color statusBarColor = blackColor,
      Color systemNavigationBarColor = primaryColor,
      Brightness iconBrightness = Brightness.light}) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: /*Colors.black.withOpacity(0),*/ statusBarColor,
      //status top color
      statusBarIconBrightness: iconBrightness, //top bar icons
    ));
  }

  /* get device type
  * @param context
  * */
  static String getDeviceType(BuildContext context) {
    return Theme.of(context).platform == TargetPlatform.iOS ? "iOS" : "Android";
  }

  /* get device id or token
  * @param context
  * */
  static Future<String> getDeviceToken(BuildContext context) async {
    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    if (Theme.of(context).platform == TargetPlatform.android) {
      return await deviceInfoPlugin.androidInfo
          .then((deviceInfo) => deviceInfo.id.toString());
    } else if (Theme.of(context).platform == TargetPlatform.iOS) {
      return await deviceInfoPlugin.iosInfo
          .then((ss) => ss.identifierForVendor.toString());
    } else {
      return "";
    }
  }

  static int getRandomNumber() {
    var num = Random();
    return num.nextInt(2);
  }

  static String parseDateFormat(String date, String oldFormat, String newFormat) {
    if (date.isEmpty || date.toString() == "null") {
      return "";
    } else {
      LogHelper("date $date");
      return DateFormat(newFormat).format(DateTime.tryParse(date)!);
    }
  }

  static String dateFormater(
      String dateFromJSON, String expectedFormat, String oldFormat) {
    DateFormat dateFormat = new DateFormat(oldFormat);
    DateTime? date;
    String? convertedDate;
    try {
      date = dateFormat.parse(dateFromJSON);
      DateFormat simpleDateFormat = DateFormat(expectedFormat);
      convertedDate = simpleDateFormat.format(date);
    } catch (e) {
      LogHelper("Exception -> ${e.toString()}");
    }

    return convertedDate!;
  }

  static void goToNext(BuildContext context, Widget widget,
      {bool isReplace = false}) {
    if (isReplace) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => widget));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (context) => widget));
    }
  }

  static void goToNextWithRemoveUntil(BuildContext context, Widget widget) {
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => widget),
        (Route<dynamic> route) => false);
  }

  static TextStyle setTextStyle(double fontSize, FontWeight fontWeight,
      {Color color = blackColor,
      String fontFamily = ConstantLabels.Poppins,
      double? height,
      TextDecoration decoration = TextDecoration.none}) {
    return TextStyle(
        fontFamily: fontFamily,
        color: color,
        height: height,
        decoration: decoration,
        fontWeight: fontWeight,
        fontSize: fontSize);
  }

  // static String parseHtmlString(String htmlString) {
  //   final document = parse(htmlString);
  //   final String parsedString = parse(document.body!.text).documentElement!.text;
  //   return parsedString;
  // }

  // static String parseHtmlStringWithPoints(String htmlString) {
  //   final document = parse(htmlString);
  //   String parsedString = parse(document.body!.text).documentElement!.text;
  //   var newParsedString = parsedString.split(".");
  //   // var readLines = ['Test1', 'Test2', 'Test3'];
  //   // String getNewLineString() {
  //   StringBuffer sb = StringBuffer();
  //   for (String line in newParsedString) {
  //     sb.write("$line\n\n");
  //   }
  //   return sb.toString();
  //   // }
  //   // return parsedString;
  // }

  static InputDecoration textFieldInputDecoration(String hintText,
      {String? labelText}) {
    return InputDecoration(
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(32.0),
            borderSide: const BorderSide(color: greyColor)),
        contentPadding: const EdgeInsets.only(
            left: 24.0, right: 24.0, top: 12.0, bottom: 12.0),
        counterText: '',
        hintText: hintText,
        labelText: labelText,
        hintStyle: CommonMethods.setTextStyle(
            FontSizeAndWidth.subTitle, FontSizeAndWidth.regular,
            color: greyColor));
  }

  static getValueFromtxt(Text txt) {
    var value = txt.data;
    return value;
  }

  static getMyText(String title) {
    Text myText = Text(title,
        style: CommonMethods.setTextStyle(
            FontSizeAndWidth.subTitle, FontSizeAndWidth.bold,
            color: whiteColor));
    return getValueFromtxt(myText).toString();
  }

  static showToast(String msg) {
    Fluttertoast.showToast(
        msg: msg,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        timeInSecForIosWeb: 3,
        backgroundColor: Colors.green,
        textColor: Colors.white);
  }

  static List<Widget> getActionIcons(
      int size, List<String>? actionIcon, List<Function>? onActionTap) {
    List<Widget> wids = [];
    for (int i = 0; i < size; i++) {
      wids.add(
          /*Container(
          padding: const EdgeInsets.only(right: 5.0),
          child: */
          IconButton(
              alignment: size > 1
                  ? i == 0
                      ? Alignment.centerRight
                      : Alignment.centerLeft
                  : Alignment.centerLeft,
              // icon: Icon(Icons.delete, color: whiteColor),
              icon: // actionIcon[i].contains('Icons') ?
                  Image.asset(actionIcon![i],
                      width: 25, height: 25, color: primaryColor1),
              //  : (actionIcon[i], color: whiteColor),// width: 24, height: 24,
              onPressed: () => onActionTap![i]()));
    }
    return wids;
  }

  /* show snack bar
  * @param scaffoldKey - key
  * @param msg - text message
  * */
  static showError(BuildContext context, String msg,
      {GlobalKey<ScaffoldState>? scaffoldKey, int? duration}) {
    // scaffoldKey.currentState!.showSnackBar(SnackBar(
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Container(
          margin: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.all(Radius.circular(10.0))),
          child: Row(
            children: <Widget>[
              const Icon(
                Icons.error,
                color: whiteColor,
                size: 16.0,
              ),
              const SizedBox(
                width: 8.0,
              ),
              Flexible(
                  child: Text(
                msg,
                style: setTextStyle(
                    FontSizeAndWidth.descriptionText, FontSizeAndWidth.medium,
                    color: whiteColor),
              )),
            ],
          )),
      duration: duration != null
          ? Duration(seconds: duration)
          : const Duration(seconds: 2),
      backgroundColor: Colors.red,
    ));
  }

  static showFlushBar(BuildContext context,
      {String? title_,
      String? msg_,
      IconData? icon_,
      String? status_,
      int? duration}) {
    Flushbar(
      backgroundColor: status_ == "done" ? Colors.green : Colors.red,
      borderRadius: const BorderRadius.all(Radius.circular(10)),
      /*  backgroundGradient: LinearGradient(
        colors: [redColor, blackColor],
      ), */
      icon: Icon(icon_, color: whiteColor),
      /* titleText: Text.rich(TextSpan(
          text: '$title_',
          style: CommonMethods.setTextStyle(
              FontSizeAndWidth.subTitle, FontSizeAndWidth.bold,
              color: whiteColor))),
      titleColor: whiteColor,
      messageColor: whiteColor,
     */
      flushbarStyle: FlushbarStyle.FLOATING,
      flushbarPosition: FlushbarPosition.TOP,
      messageText: Text.rich(TextSpan(
          text: '$msg_',
          style: CommonMethods.setTextStyle(
              FontSizeAndWidth.smallText, FontSizeAndWidth.bold,
              color: whiteColor))),
      // message:"Item Added to Cart Successfully",
      reverseAnimationCurve: Curves.decelerate,
      forwardAnimationCurve: Curves.elasticInOut,
      margin: const EdgeInsets.all(10.0),
      duration: Duration(seconds: duration ?? 3),
      // duration: Duration(seconds: duration != null ? duration : 3),
    ).show(context);
  }

  static titleText(String text) {
    /* Text text_ = Text.rich(
        TextSpan(
        text: '$text'));*/
    TextEditingController textController = TextEditingController();
    textController.text = text;

    TextField myStyleText = TextField(
        controller: textController,
        style: setTextStyle(FontSizeAndWidth.subTitle, FontSizeAndWidth.bold,
            color: whiteColor));
    return myStyleText.controller!.text.toString();
  }

  static title_text(String text) {
    text != null
        ? Text.rich(
            TextSpan(
              text: text,
              style: CommonMethods.setTextStyle(
                  FontSizeAndWidth.subTitle, FontSizeAndWidth.bold,
                  color:
                      whiteColor), // default text style //fontWeight: FontWeight.bold,
              /* children: <TextSpan>[
          TextSpan(text: '$text2', style: TextStyle(color: Colors.orange, fontSize: 12)), //fontStyle: FontStyle.italic, // const Color(0xff555555)
          TextSpan(text: '$text3', style: TextStyle(fontSize: 12)), //fontWeight: FontWeight.bold,
        ],*/
            ),
          )
        /*;
    Text(
            text,
            style: CommonMethods.setTextStyle(
                FontSizeAndWidth.subTitle, FontSizeAndWidth.bold,
                color: whiteColor),
          )*/
        : "";
    return text;
  }

  static bool isBannerTestAd() {
    bool result = true;
    Random r = Random();
    result = r.nextDouble() <= 0.5;
    LogHelper("isBannerTestAd : $result");
    return result; // true;
  }

  static bool isNativeTestAd() {
    bool result = true;
    Random r = Random();
    result = r.nextDouble() <= 0.5;
    LogHelper("isNativeTestAd : $result");
    return result; // true;
  }

  static msgText(String? text) {
    text != null
        ? Text(
            text,
            style: CommonMethods.setTextStyle(
                FontSizeAndWidth.descriptionText, FontSizeAndWidth.medium,
                color: whiteColor),
          )
        : "";
    return text;
  }

  static void showAlertDialog(
      BuildContext context, String title, String message,
      {Function? onPositiveTap, Function? onNegativeTap}) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(title,
                  style: CommonMethods.setTextStyle(
                      FontSizeAndWidth.title, FontSizeAndWidth.bold,
                      fontFamily: ConstantLabels.Poppins)),
              content: Text(message,
                  style: CommonMethods.setTextStyle(
                      FontSizeAndWidth.subTitle, FontSizeAndWidth.medium,
                      fontFamily: ConstantLabels.Poppins)),
              actions: <Widget>[
                TextButton(
                    child: Text("No",
                        style: CommonMethods.setTextStyle(
                            FontSizeAndWidth.descriptionText,
                            FontSizeAndWidth.bold,
                            fontFamily: ConstantLabels.Poppins,
                            color: Colors.red)),
                    // icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      if (onNegativeTap != null) {
                        onNegativeTap();
                      } else {
                        Navigator.pop(context);
                      }
                    }),
                TextButton(
                    child: Text("Yes",
                        style: CommonMethods.setTextStyle(
                            FontSizeAndWidth.descriptionText,
                            FontSizeAndWidth.bold,
                            fontFamily: ConstantLabels.Poppins,
                            color: Colors.green)),
                    // icon: const Icon(Icons.done, color: Colors.green),
                    onPressed: () {
                      if (onPositiveTap != null) {
                        onPositiveTap();
                      } else {
                        Navigator.pop(context);
                      }
                    })
              ],
            ));
  }

  static void showCallAlertDialog(
      BuildContext context, String title, String message,
      {Function? onTap}) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(title,
                  style: CommonMethods.setTextStyle(
                      FontSizeAndWidth.subTitle, FontSizeAndWidth.bold)),
              content: Text(message,
                  style: CommonMethods.setTextStyle(
                      FontSizeAndWidth.descriptionText,
                      FontSizeAndWidth.medium)),
              actions: <Widget>[
                InkWell(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      margin: const EdgeInsets.all(5),
                      child: Text("Cancel",
                          style: CommonMethods.setTextStyle(
                              FontSizeAndWidth.descriptionText,
                              FontSizeAndWidth.bold,
                              color: textColor)
                          // icon: Icon(Icons.close, color: Colors.red),
                          ),
                    )),
                InkWell(
                    onTap: () {
                      onTap!();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      margin: const EdgeInsets.all(5),
                      child: Text("Call",
                          style: CommonMethods.setTextStyle(
                              FontSizeAndWidth.descriptionText,
                              FontSizeAndWidth.bold,
                              color: Colors.green)
                          // icon: Icon(Icons.done, color: Colors.green),
                          ),
                    )),
              ],
            ));
  }

  static void showAlertDialogWithImage(
      {BuildContext? context,
      String? title,
      String? message,
      String? dynamicImage,
      String? buttonText,
      Function? onTap}) {
    showDialog(
        context: context!,
        builder: (context) => AlertDialog(
              title: Text(title!,
                  style: CommonMethods.setTextStyle(
                      FontSizeAndWidth.subTitle, FontSizeAndWidth.bold)),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Text(message!,
                        style: CommonMethods.setTextStyle(
                            FontSizeAndWidth.descriptionText,
                            FontSizeAndWidth.medium)),
                    const SizedBox(height: 20),
                    Image.asset(dynamicImage!)
                  ],
                ),
              ),
              actions: <Widget>[
                /* IconButton(
                    icon: Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      Navigator.pop(context);
                    }),*/
                CustomRaisedButton(
                    width: 100,
                    height: 40,
                    colors: const [textColor, textColor],
                    child: Text(buttonText!,
                        style: CommonMethods.setTextStyle(
                            FontSizeAndWidth.descriptionText,
                            FontSizeAndWidth.bold,
                            color: whiteColor)),
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Navigator.pop(context);
                      onTap!();
                    })
              ],
            ));
  }

  static void showAlertDialogWithDynamicImage(
      {BuildContext? context,
      String? title,
      String? message,
      String? dynamicImage,
      String? positiveButtonText,
      Function? onPositiveTap,
      String? negativeButtonText,
      Function? onNegativeTap}) {
    showDialog(
        context: context!,
        builder: (context) => AlertDialog(
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20.0))),
              title: Text(title!,
                  style: CommonMethods.setTextStyle(
                      FontSizeAndWidth.subTitle, FontSizeAndWidth.bold)),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Visibility(
                      visible: dynamicImage!.isNotEmpty,
                      child: ClipRRect(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(0.0)),
                        child: Image.asset(dynamicImage, fit: BoxFit.fill),
/*                              CachedNetworkImage(
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.width,
                            imageUrl: dynamicImage ?? ImageUrl.ic_launcher,
                            // fit: BoxFit.fill,
                            progressIndicatorBuilder:
                                (context, url, downloadProgress) => Center(
                                    child: CircularProgressIndicator(
                                        value: downloadProgress.progress)),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error),
                          )*/
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(message!,
                        style: CommonMethods.setTextStyle(
                            FontSizeAndWidth.descriptionText,
                            FontSizeAndWidth.medium)),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
              actions: <Widget>[
                /* IconButton(
                    icon: Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      Navigator.pop(context);
                    }),*/
                // Center(child:
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    CustomRaisedButton(
                        width: MediaQuery.of(context).size.width / 3,
                        height: 40,
                        colors: const [Colors.white, Colors.white],
                        child: Text(negativeButtonText!,
                            style: CommonMethods.setTextStyle(
                                FontSizeAndWidth.descriptionText,
                                FontSizeAndWidth.bold,
                                color: primaryColor1)),
                        onPressed: () {
                          Navigator.of(context).pop();
                          // Navigator.pop(context);
                          onNegativeTap!();
                        }),
                    CustomRaisedButton(
                        width: MediaQuery.of(context).size.width / 3,
                        height: 40,
                        child: Text(positiveButtonText!,
                            style: CommonMethods.setTextStyle(
                                FontSizeAndWidth.descriptionText,
                                FontSizeAndWidth.bold,
                                color: whiteColor)),
                        onPressed: () {
                          Navigator.of(context).pop();
                          // Navigator.pop(context);
                          onPositiveTap!();
                        }),
                  ],
                ),
                // )
              ],
            ));
  }


/*
  static String? extractPayload(String payload) {
    try {
      String strPwd = ConstantLabels.ext_payload_k;
      String strIv = ConstantLabels.ext_payload_i;
      var iv = CryptoPack.sha512
          .convert(ConvertPack.utf8.encode(strIv))
          .toString()
          .substring(0, 16); // Consider the first 16 bytes of all 64 bytes
      var key = CryptoPack.sha512
          .convert(ConvertPack.utf8.encode(strPwd))
          .toString()
          .substring(0, 32); // Consider the first 32 bytes of all 64 bytes
      EncryptPack.IV ivObj = EncryptPack.IV.fromUtf8(iv);
      EncryptPack.Key keyObj = EncryptPack.Key.fromUtf8(key);
      final encrypter = EncryptPack.Encrypter(EncryptPack.AES(keyObj,
          mode: EncryptPack.AESMode.cbc)); // Apply CBC mode
      final encrypted = encrypter.encrypt(payload, iv: ivObj);
      final decrypted = encrypter.decrypt(encrypted, iv: ivObj);
      // String firstBase64Decoding = new String.fromCharCodes(ConvertPack.base64.decode(payload));              // First Base64 decoding
      // LogHelper("payload firstBase64Decoding : $firstBase64Decoding");
      // final decrypted = encrypter.decrypt(EncryptPack.Encrypted.fromBase64(firstBase64Decoding), iv: ivObj);  // Second Base64 decoding (during decryption)
      // final decrypted = encrypter.decrypt(EncryptPack.Encrypted.fromBase64(encrypted), iv: ivObj);  // Second Base64 decoding (during decryption)
      // ---
      // LogHelper("payload original : $payload");
      // LogHelper("payload encrypted : $encrypted");
      // LogHelper("payload encrypted.base64 : ${encrypted.base64}");
      LogHelper("payload decrypted : $decrypted");
      return encrypted.base64.toString();
    } catch (Exception) {
      LogHelper("Exception : $Exception");
    }
  }

  static String? deExtractPayload(final encrypted) {
    try {
      String strPwd = ConstantLabels.ext_payload_k;
      String strIv = ConstantLabels.ext_payload_i;
      var iv = CryptoPack.sha512
          .convert(ConvertPack.utf8.encode(strIv))
          .toString()
          .substring(0, 16); // Consider the first 16 bytes of all 64 bytes
      var key = CryptoPack.sha512
          .convert(ConvertPack.utf8.encode(strPwd))
          .toString()
          .substring(0, 32); // Consider the first 32 bytes of all 64 bytes
      EncryptPack.IV ivObj = EncryptPack.IV.fromUtf8(iv);
      EncryptPack.Key keyObj = EncryptPack.Key.fromUtf8(key);
      final encrypter = EncryptPack.Encrypter(EncryptPack.AES(keyObj,
          mode: EncryptPack.AESMode.cbc)); // Apply CBC mode
      // encrypted = encrypter.encrypt(payload, iv: ivObj);
      final decrypted = encrypter.decrypt(encrypted, iv: ivObj);
      // String firstBase64Decoding = new String.fromCharCodes(ConvertPack.base64.decode(payload));              // First Base64 decoding
      // LogHelper("payload firstBase64Decoding : $firstBase64Decoding");
      // final decrypted = encrypter.decrypt(EncryptPack.Encrypted.fromBase64(firstBase64Decoding), iv: ivObj);  // Second Base64 decoding (during decryption)
      // final decrypted = encrypter.decrypt(EncryptPack.Encrypted.fromBase64(encrypted), iv: ivObj);  // Second Base64 decoding (during decryption)
      // LogHelper("link encrypted : $encrypted");
      // LogHelper("link decrypted : $decrypted");
      return decrypted.toString();
    } catch (Exception) {
      LogHelper("Exception : $Exception");
    }
  }
*/

  static decimalPlaces(String amount, {int? decimals}) {
    return double.parse(amount).toStringAsFixed(decimals ?? 2);
    // .toStringAsFixed(decimals != null ? decimals : 2);
  }

  static bool getTime(TimeOfDay startTime, TimeOfDay endTime) {
    bool result = false;
    int startTimeInt = (startTime.hour * 60 + startTime.minute) * 60;
    int endTimeInt = (endTime.hour * 60 + endTime.minute) * 60;
    int dif = endTimeInt - startTimeInt;

    if (endTimeInt > startTimeInt) {
      result = true;
    } else {
      result = false;
    }
    return result;
  }

  /*
  static getCurrentLocation({Function? onTap, Function? latitude, Function? longitude,  Function? onLocationOff, Function? newLocation }) async {
    TextEditingController locationController = TextEditingController();
    TextEditingController AddLocationController = TextEditingController();
    Position? _currentPosition;
    String? _currentAddress;
    String? _newCurrentAddress;
    LocationPermission? permission;
    permission != null && permission != LocationPermission.denied
        ? LogHelper("permission $permission")
        : permission = await Geolocator.requestPermission();

    Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
    // Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best, forceAndroidLocationManager: true)
        .then((Position position) async {
      // setState(() {
      //   LogHelper("position $position");
      //   LogHelper("latitude ${position.latitude}");
      //   LogHelper("longitude ${position.longitude}");

        // var latitude,longitude;
        latitude!(position.latitude);
        longitude!(position.longitude);
        // onPressed!(latitude : position.latitude, longitude: position.longitude);
        _currentPosition = position;
        // LogHelper("_currentPosition ${_currentPosition}");


        try {
          List<Placemark> placemarks =
              await placemarkFromCoordinates(_currentPosition!.latitude, _currentPosition!.longitude);

          Placemark place = placemarks[0];

          // setState(() {
            LogHelper("place $place");
          //   LogHelper("name ${place.name} subLocality ${place.subLocality}");
            _currentAddress = "${place.name},${place.subLocality},${place.locality},${place.administrativeArea},${place.country},${place.postalCode}";
            _newCurrentAddress = "${place.locality} - ${place.name}";
          // {name = 2GR4+FH, subLocality = Bodakdev, locality = Ahmedabad, administrativeArea = Gujarat, country = India, postalCode = 380054}
            // LogHelper("_currentAddress $_currentAddress");
          locationController.text = _currentAddress.toString();
          AddLocationController.text = _newCurrentAddress.toString();

            // Navigator.of(context).pop();
          onTap!(locationController.text);
          if(newLocation != null) {
            newLocation!(AddLocationController.text);
          }
          // });
        } catch (e) {
          if(!(await Permission.locationWhenInUse.serviceStatus.isEnabled)){
            LogHelper("Location Disable ${await Permission.locationWhenInUse.serviceStatus.isDisabled}");
            if(onLocationOff != null ) {
              onLocationOff!();
            }else{
            }
          }
          print("catch $e");
        }
      // });
    }).catchError((e) async {
      LogHelper("catchError");
      if(!(await Permission.locationWhenInUse.serviceStatus.isEnabled)){
        LogHelper("Location Disable ${await Permission.locationWhenInUse.serviceStatus.isDisabled}");
        if(onLocationOff != null ) {
          onLocationOff!();
        }else{
        }
      }
      print("catchError $e");
    });
  }
*/

  static bool isAlphabetsOnly({required String txt}) {
    final RegExp letterRegExp = RegExp(r'^[a-zA-Z]+$');
    return letterRegExp.hasMatch(txt);
  }

  static bool isDigitOnly({required String txt}) {
    final RegExp letterRegExp = RegExp(r'^\d+$');
    return letterRegExp.hasMatch(txt);
  }

  static String greeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    }
    if (hour < 17) {
      return 'Good Afternoon';
    }
    return 'Good Evening';
  }

  static launchURL({String link = ""}) async {
    final Uri url = Uri.parse(link);
    if (!await launchUrl(url, mode: LaunchMode.platformDefault)) {
      // if (!await launchUrl(url, mode: LaunchMode.inAppWebView)) {
      throw Exception('Could not launch $url');
    }
  }

  static String getRoomId({required String firstUID, required String otherUserId}) {
    if (firstUID.length > 5 && otherUserId.length > 5) {
      return (firstUID.substring(0, 3) + otherUserId.substring(0, 3));
    } else {
      LogHelper("firstUID $firstUID - otherUserId $otherUserId");
      return "";
    }
  }

  static assetImage({required String img,double height = 50.0 , width = 50.0,bool isSvg = true, Color color = Colors.transparent, BoxFit fit = BoxFit.contain}) {
    return isSvg ? SvgPicture.asset(
      img,
      height: height,
      width: width,color: color,fit: fit,
    ) : Image.asset(
      img,
      height: height,
      width: width,fit: fit,
    );
  }

}
