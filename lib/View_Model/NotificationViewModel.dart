import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mikk/utils/CommonMethods.dart';

import '../Model/FollowerModel.dart';
import '../Model/NotificationModel.dart';
import '../Model/auth/SignUpModel.dart';
import '../Model/auth/UserNameModel.dart';
import '../utils/LogHelper.dart';
import '../values/StaticText.dart';
import 'FollowerFollowingViewModel.dart';
import 'SettingsDetailViewModel/PersonalInformationViewModel.dart';

class NotificationViewModel extends ChangeNotifier{
  bool isLoader = false;
  SignUpModel? userData;
  List<NotificationModel> notificationList = [];

  Future<void> addNotificationDataFirebase(
    BuildContext context, {
    required UserNameModel searchedUser,
    SignUpModel? userData,
    bool isFollowing = false,
  }) async {
    setLoading(true);
    try {
      if(userData == null) {
        List<Map<String, dynamic>?> data = await PersonalInformationViewModel().getUserData();
        if (data.isNotEmpty) {
          // userData = data.map((data) => SignUpModel.fromJson(data!)).toList();
          userData = data.map((data) => SignUpModel.fromJson(data!)).first;
        }
      }
      final mainDocId = searchedUser.userId;

      final subCollectionRef = FirebaseFirestore.instance
          .collection(ConstantLabels.notificationTable)
          .doc(mainDocId)
          .collection(ConstantLabels.notifySubTable);

      NotificationModel model = NotificationModel(
        receiverUserId: searchedUser.userId,
        name: userData!.name,
        userName: userData.userName,
        senderUserId: userData.userId,
        isRead: false,
        isFollower: true,
        isFollowing: isFollowing,
        timeStamp: CommonMethods.parseDateFormat(DateTime.now().toString(), "", "dd MMMM yyyy hh:mm a"),
      );

      // await subCollectionRef.doc(searchedUser.userId).set(model.toJson());
      await subCollectionRef.doc(userData!.userId).set(model.toJson());
      // searchedUser.isRequestSent = true;
      LogHelper("Notification Send successfully");
    } catch (e) {
      LogHelper('Error adding document: $e');
      CommonMethods.showFlushBar(context, msg_: "Notification Server Issue", icon_: Icons.error, status_: "error");
    }
    setLoading(false);
  }


  Future<NotificationModel?> getNotificationData({String? currentUserId, String? searchedUserId}) async {
    setLoading(true);

    try {
      currentUserId ??= await FirebaseAuth.instance.currentUser?.uid;

      final docRef = FirebaseFirestore.instance
          .collection(ConstantLabels.notificationTable)
          .doc(currentUserId)
          .collection(ConstantLabels.notifySubTable);

      if (searchedUserId == null) {
        final querySnapshot = await docRef.get();
        notificationList = querySnapshot.docs
            .map((doc) => NotificationModel.fromJson(doc.data()))
            .toList();
        LogHelper("Fetched ${notificationList.length} notifications");
        setLoading(false);
        return null;
      }

      final docSnapshot = await docRef.doc(searchedUserId).get();

      if (docSnapshot.exists) {
        LogHelper('Notification found: ${docSnapshot.data()}');
        return NotificationModel.fromJson(docSnapshot.data()!);
      } else {
        LogHelper('Notification not found.');
        return null;
      }
    } catch (e) {
      LogHelper('Error fetching notification: $e');
      return null;
    } finally {
      setLoading(false);
    }
  }

  followBack(BuildContext context, {required NotificationModel followBackUser}) async {
    setLoading(true);
    try {

      await FollowerFollowingViewModel().addFollowingDataFirebase(context, followBackUser: followBackUser);
      addNotificationRoomName(context, searchedUser: followBackUser);
    } catch (e) {
      LogHelper('Error fetching notification: $e');
      return null;
    } finally {
      setLoading(false);
    }
  }


  Future<void> addNotificationRoomName(
      BuildContext context, {
        required NotificationModel searchedUser,
        SignUpModel? userData,
      }) async {
    setLoading(true);
    try {

      final mainDocId = searchedUser.receiverUserId;
      final docRefForMyself = FirebaseFirestore.instance
          .collection(ConstantLabels.notificationTable)
          .doc(mainDocId)
          .collection(ConstantLabels.notifySubTable)
          .doc(searchedUser!.senderUserId);

      String roomName = CommonMethods.getRoomId(firstUID: searchedUser.receiverUserId.toString(), otherUserId: searchedUser.senderUserId.toString());

      if(roomName.isNotEmpty) {
        LogHelper("roomName $roomName");
        await docRefForMyself.update({
        'roomName': roomName,
      });
        LogHelper("roomName updated successfully");
      }


      final mainDocIdForOther = searchedUser!.senderUserId;
      final docRefForOther = FirebaseFirestore.instance
          .collection(ConstantLabels.notificationTable)
          .doc(mainDocIdForOther)
          .collection(ConstantLabels.notifySubTable)
          .doc(searchedUser.receiverUserId);

      if(roomName.isNotEmpty) {
        LogHelper("roomName $roomName");
        await docRefForOther.update({
          'roomName': roomName,
        });
        LogHelper("roomName updated for Other");
      }

      FollowerFollowingViewModel().updateFollowingRoomName(
        roomName: roomName,
        userId: searchedUser.receiverUserId.toString(),
        otherUserId: searchedUser.senderUserId.toString(),
      );

      FollowerFollowingViewModel().updateFollowingRoomName(
        roomName: roomName,
        userId: searchedUser.senderUserId.toString(),
        otherUserId: searchedUser.receiverUserId.toString(),
      );

      FollowerFollowingViewModel().updateFollowerRoomName(
        roomName: roomName,
        userId: searchedUser.senderUserId.toString(),
        otherUserId: searchedUser.receiverUserId.toString(),
      );

      FollowerFollowingViewModel().updateFollowerRoomName(
        roomName: roomName,
        userId: searchedUser.receiverUserId.toString(),
        otherUserId: searchedUser.senderUserId.toString(),
      );

    } catch (e) {
      LogHelper('Error updating roomName: $e');
      CommonMethods.showFlushBar(
        context,
        msg_: "Could not update room name",
        icon_: Icons.error,
        status_: "error",
      );
    }
    setLoading(false);
  }


  setLoading(bool value) {
    isLoader = value;
    notifyListeners();
  }

}