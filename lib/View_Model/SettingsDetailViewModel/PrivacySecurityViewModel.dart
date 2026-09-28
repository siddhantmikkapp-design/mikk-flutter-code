import 'package:flutter/material.dart';

import '../../Model/GlobalListModel.dart';
import '../../values/ImageUrl.dart';

class SettingsDetailViewModel with ChangeNotifier {
  List<GlobalListModel> privacySecurityList = [];
  List<GlobalListModel> notificationList = [];
  bool status = false;
  bool requestNotification = false;
  bool michNotification = false;

  void getPrivacySecurityList() {
    privacySecurityList = [];
    privacySecurityList.add(GlobalListModel(
        icon: status ? Icons.toggle_on : Icons.toggle_off_outlined,
        title: "Status ${status ? "Active" : "InActive"}",
        onTap: () {
          status = !status;
          getPrivacySecurityList();
        }));
    privacySecurityList.add(GlobalListModel(title: "Blocked account"));
    privacySecurityList.add(GlobalListModel(title: "Delete my account"));
    notifyListeners();
  }

  void getNotificationList() {
    notificationList = [];
    notificationList.add(GlobalListModel(
        icon: requestNotification ? Icons.toggle_on : Icons.toggle_off_outlined,
        title: "Request Notification",
        onTap: () {
          requestNotification = !requestNotification;
          getNotificationList();
        }));
    notificationList.add(GlobalListModel(
        icon: michNotification ? Icons.toggle_on : Icons.toggle_off_outlined,
        title: "Mute Notification",
        onTap: () {
          michNotification = !michNotification;
          getNotificationList();
        }));
    notifyListeners();
  }

  updateStatus({bool newStatus = false}) {
    status = newStatus;
    notifyListeners();
  }
}
