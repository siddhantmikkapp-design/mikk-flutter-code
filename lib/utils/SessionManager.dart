import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'LogHelper.dart';


class SessionManager {

  static const String USER_TYPE = 'userType';
  static const String PRIMARY_THEME_COLOR = 'PrimaryThemeColor';

  static const String USER_ID = 'userId';
  static const String USER_NAME = 'userName';
  static const String FULL_NAME = 'name';
  static const String FIRST_NAME = 'firstName';
  static const String LAST_NAME = 'lastName';
  static const String EMAIL = 'email';
  static const String MOBILE = 'mobileNo';

  static const String ADDRESS = 'address';
  static const String CITY = 'city';
  static const String STATE = 'state';
  static const String COUNTRY = 'country';
  static const String LATITUDE = 'latitude';
  static const String LONGITUDE = 'longitude';

  static const String FCM_TKN = 'fcmToken';
  static const String TKN_CHNG = 'isFcmTokenChange';
  static const String IS_SECURITY = 'isSecurity';
  static const String IS_EMAIL_VERIFIED = 'isEmailVerified';
  static const String IS_PHONE_VERIFIED = 'IsPhoneVerified';
  static const String FORM_PHONE_NO = 'formPhoneNo';
  static const String FORM_PHONE_NAME = 'formPhoneName';


  static void setStringData(String key, String val) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(key, val);
  }

  static Future<String> getStringData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key) ?? "";
  }

  static void setIntData(String key, int val) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt(key, val);
  }

  static Future<int> getIntData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key) ?? 0;
  }

  static void setBooleanData(String key, bool val) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(key, val);
  }

  static Future<bool> getBooleanData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? false;
  }

  static void setListDynamicData(String key, String val) async {
    LogHelper("val : $val");
    final prefs = await SharedPreferences.getInstance();
    // LogHelper("beforeSaveShared..." + prefs.getStringList(key).length.toString());
    prefs.setString(key, json.encode(val));
    LogHelper("afterSavedShared..." + prefs.getStringList(key)!.length.toString());
  }

  static Future<String> getListDynamicData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    LogHelper("getSavedShared..." + json.decode(prefs.getString(key)!));
    return json.decode(prefs.getString(key)!);
  }

  static void setUserData(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(key, json.encode(value));
  }

  static Future<String> getUserData(String? key) async {
    final prefs = await SharedPreferences.getInstance();
    return json.decode(prefs.getString(key!)!);
  }

  static void setStringListData(String key, String stringList) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(key, json.encode(stringList));
  }

  static Future<String> getStringListData(String? key) async {
    final prefs = await SharedPreferences.getInstance();
    return json.decode(prefs.getString(key!)!);
  }

  static Future<bool> removeString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.remove(key); // ?? false;
  }

  static Future<bool> clearSession() async {
    var prefs = await SharedPreferences.getInstance();
    return prefs.clear();// ?? false;
  }

  static read(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return json.decode(prefs.getString(key)!);
  }

  static save(String key, value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(key, json.encode(value));
  }

  remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove(key);
  }

}
