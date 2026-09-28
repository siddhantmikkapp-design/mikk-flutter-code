import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mikk/Demo/MessageClass.dart';
import 'package:mikk/View/Profile.dart';
import 'package:mikk/View_Model/Chat/DatabaseService.dart';
import 'package:mikk/View_Model/NotificationViewModel.dart';
import 'package:mikk/View_Model/ProfileViewModel.dart';
import 'package:provider/provider.dart';

import '../Model/FollowerModel.dart';
import '../Model/NotificationModel.dart';
import '../Model/UserProfileModel.dart';
import '../Model/auth/SignUpModel.dart';
import '../Model/auth/UserNameModel.dart';
import '../View/chat_screen.dart';
import '../utils/CommonMethods.dart';
import '../utils/LogHelper.dart';
import '../values/StaticText.dart';
import 'SettingsDetailViewModel/PersonalInformationViewModel.dart';

class FollowerFollowingViewModel extends ChangeNotifier {
  bool isLoader = false;
  List<FollowerFollowingModel> followersList = [];
  List<FollowerFollowingModel> followingList = [];
  String profileBtnStatus = "";
  String myAvatarurl = "";
  Future<void> addFollowerDataFirebase(BuildContext context, {UserNameModel? searchedUser, String userId = ""}) async {
    setLoading(true);
    try {
      SignUpModel? userData;

      LogHelper("lol $userId");
      // final user = FirebaseAuth.instance.currentUser;
      List<Map<String, dynamic>?> data = await PersonalInformationViewModel().getUserData();
      if (data.isNotEmpty) {
        // userData = data.map((data) => SignUpModel.fromJson(data!)).toList();
        userData = data.map((data) => SignUpModel.fromJson(data!)).first;
        notifyListeners();
      }
      // final mainDocId = userData!.userId;
      final mainDocId;
      if(searchedUser != null){
        mainDocId = searchedUser.userId;
      }else{
        mainDocId = userId;
      }
      notifyListeners();

      final subCollectionRef = FirebaseFirestore.instance
          .collection(ConstantLabels.followerTable)
          .doc(mainDocId)
          .collection(ConstantLabels.friendsSubTable);

      FollowerFollowingModel model = FollowerFollowingModel(
        // userId: searchedUser.userId,
        userId: userData!.userId,
        // name: searchedUser.name,
        name: userData!.name,
        // userName: searchedUser.userName,
        userName: userData!.userName,
          frId: userData!.userId,
        isBlocked: false
      );

      await subCollectionRef.doc(userData!.userId).set(model.toJson());
      // await subCollectionRef.doc(searchedUser.userId).set(model.toJson());
      LogHelper("Follow Request Send successfully");
      if(searchedUser != null) {
        await addFollowingDataFirebase(context,searchedUser: searchedUser);
        await NotificationViewModel().addNotificationDataFirebase(context,searchedUser: searchedUser,userData:userData);
        searchedUser.isRequestSent = true;
      }
    } catch (e) {
      LogHelper('Error adding document: $e');
      CommonMethods.showFlushBar(context, msg_: "Follow Request Server Issue", icon_: Icons.error, status_: "error");
    }
    setLoading(false);
  }

  Future<FollowerFollowingModel?> getFollowerData({String? searchedUserId, String? currentUserId}) async {
    /// searchedUserId is finding that person Follower
    /// currentUserId is finding specific person is connected/Request Send
    setLoading(true);
    if(searchedUserId == null){
      final user = FirebaseAuth.instance.currentUser;
      searchedUserId = user!.uid;
    }
    try {
      final docRef = FirebaseFirestore.instance
          .collection(ConstantLabels.followerTable)
          .doc(searchedUserId)
          .collection(ConstantLabels.friendsSubTable);
          // .doc(currentUserId);

      if (currentUserId == null) {
        final querySnapshot = await docRef.get();
        followersList = querySnapshot.docs.map((doc) => FollowerFollowingModel.fromJson(doc.data())).toList();
        setLoading(false);
        return null;
      } else {
        final docSnapshot = await docRef.doc(currentUserId).get();

        if (docSnapshot.exists) {
          LogHelper('Follower found: ${docSnapshot.data()}');
          return FollowerFollowingModel.fromJson(docSnapshot.data()!);
        } else {
          LogHelper('Follower not found.');
          return null;
        }
      }
    } catch (e) {
      LogHelper('Error fetching follower: $e');
      return null;
    }
  }


  Future<void> addFollowingDataFirebase(
      BuildContext context, {
    NotificationModel? followBackUser,
    UserNameModel? searchedUser,
  }) async {
    SignUpModel? userData;
    setLoading(true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception("No user logged in");
      }

      // Fetch current user data
      List<Map<String, dynamic>?> data =
      await PersonalInformationViewModel().getUserData();
      if (data.isNotEmpty) {
        userData = data.map((e) => SignUpModel.fromJson(e!)).first;
      }

      final mainDocId = currentUser.uid;

      final subCollectionRef = FirebaseFirestore.instance
          .collection(ConstantLabels.followingTable)
          .doc(mainDocId)
          .collection(ConstantLabels.friendsSubTable);

      FollowerFollowingModel? model;
      if (followBackUser != null) {
        // model = FollowerFollowingModel(
        //     /// receiverUserId is Current User ID
        //     userId: userData!.userId,
        //     name: userData!.name,
        //     userName: userData!.userName,
        //     isBlocked: false,
        //     frId: followBackUser.senderUserId);
        model = FollowerFollowingModel(
            /// receiverUserId is Current User ID
            userId: followBackUser.receiverUserId,
            name: followBackUser.name,
            userName: followBackUser.userName,
            isBlocked: false,
            frId: userData!.userId);
        await subCollectionRef.doc(followBackUser.senderUserId).set(model.toJson());
      } else {
        model = FollowerFollowingModel(

            /// receiverUserId is Current User ID
            userId: searchedUser!.userId,
            name: searchedUser.name,
            userName: searchedUser.userName,
            isBlocked: false,
            frId: userData!.userId);
        await subCollectionRef.doc(searchedUser.userId).set(model.toJson());
      }

      // await subCollectionRef.doc(followBackUser.senderUserId).set(model.toJson());

      if(followBackUser != null) {
        String? id = followBackUser.receiverUserId;
        followBackUser.receiverUserId = followBackUser.senderUserId;
        followBackUser.senderUserId = id;
        notifyListeners();
        LogHelper("Follow request sent successfully");
        await PersonalInformationViewModel().getUserData().then(
          (value) async {
            if (value.isNotEmpty) {
              notifyListeners();
              await addFollowerDataFirebase(context, userId : followBackUser.receiverUserId.toString());
              await NotificationViewModel().addNotificationDataFirebase(context,
                  searchedUser: UserNameModel.fromJson(followBackUser.toJson()),
                  userData: userData,
                  isFollowing: true);
              followBackUser.isFollowing = true;
            }
          },
        );

        //     await PersonalInformationViewModel().getUserData(userId: followBackUser.senderUserId.toString()).then(
        //   (value) async {
        //     if (value.isNotEmpty) {
        //       notifyListeners();
        //       await NotificationViewModel().addNotificationDataFirebase(context,
        //           searchedUser: UserNameModel.fromJson(followBackUser.toJson()),
        //           userData: value.map((e) => SignUpModel.fromJson(e!)).first,
        //           isFollowing: true);
        //       followBackUser.isFollowing = true;
        //     }
        //   },
        // );
      }
    } catch (e) {
      LogHelper('Error adding document: $e');
      CommonMethods.showFlushBar(
        context,
        msg_: "Follow Request Server Issue",
        icon_: Icons.error,
        status_: "error",
      );
    }
    setLoading(false);
  }

  Future<List<FollowerFollowingModel>> getFollowingList() async {
    try {
      setLoading(true);
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setLoading(false);
        throw Exception("No user logged in");
      }

      final subCollectionRef = FirebaseFirestore.instance
          .collection(ConstantLabels.followingTable)
          .doc(currentUser.uid)
          .collection(ConstantLabels.friendsSubTable);

      final querySnapshot = await subCollectionRef.get();

      followingList = querySnapshot.docs
          .map((doc) => FollowerFollowingModel.fromJson(doc.data()))
          .toList();
      notifyListeners();

      LogHelper("Following list fetched: ${followingList.length} users");

    } catch (e) {
      LogHelper("Error fetching following list: $e");
    }
    setLoading(false);
    return followingList;
  }

  sendMessageFromProfile(BuildContext context, {UserNameModel? otherUser}) async {

    final dbService = Provider.of<DatabaseService>(context, listen: false);
    SignUpModel? userData;

    List<Map<String, dynamic>?> data = await PersonalInformationViewModel().getUserData();
    if (data.isNotEmpty) {
      userData = data.map((data) => SignUpModel.fromJson(data!)).first;
      notifyListeners();
    }
    NotificationModel? notificationData = await NotificationViewModel().getNotificationData(searchedUserId: otherUser?.userId ?? "");

    final personalInfoVM = Provider.of<ProfileViewModel>(context, listen: false);
    myAvatarurl = personalInfoVM.currentUser!.id.toString();


    MessageClass senderModel = MessageClass(
      otherUserId: otherUser!.userId.toString(),
      name: otherUser.name,
      roomName: notificationData?.roomName
    );


    MessageClass receiverModel = MessageClass(
      otherUserId: userData!.userId,
      name: userData!.name,
      roomName: notificationData?.roomName
    );

    dbService.updateCurrentUserName(newCurrentUserName: userData!.name.toString());
    dbService.updateReceiverUser(newReceiverUser: senderModel).then(
          (value) async {
        final refUserRoomReceiver = dbService.baseRef.child("UserRooms").child(senderModel.otherUserId.toString()).child(userData!.userId.toString());
        final refUserRoomSender = dbService.baseRef.child("UserRooms").child(userData!.userId.toString()).child(senderModel!.otherUserId.toString());

        await refUserRoomReceiver.update(receiverModel.toJson());
        await refUserRoomSender.update(senderModel.toJson());
     //   CommonMethods.goToNext(context, ChatScreen(receiverUser: senderModel, roomName: notificationData!.roomName.toString(),avatarUrl: myAvatarurl,));
      },
    );
  }

  Future<void> profileBtnEvent({required BuildContext context, String otherUserId = "", UserNameModel? otherUser}) async {
    setLoading(true);
    if (profileBtnStatus == "follow") {
      // FollowerFollowingViewModel().
      addFollowerDataFirebase(context, searchedUser: otherUser).then((value) {
        getFollowStatus(otherUserId);
        notifyListeners();
      },);
    } else if (profileBtnStatus == "follow back") {
      // FollowerFollowingModel(
      //     userId: followBackUser.receiverUserId,
      //     name: followBackUser.name,
      //     userName: followBackUser.userName,
      //     isBlocked: false,
      //     frId: userData!.userId);
      SignUpModel? userData;

      List<Map<String, dynamic>?> data = await PersonalInformationViewModel().getUserData();
      if (data.isNotEmpty) {
        userData = data.map((data) => SignUpModel.fromJson(data!)).first;
        notifyListeners();
      }
      /// receiverUserId is Current User ID
      NotificationModel followBackUser  = NotificationModel(
        receiverUserId: userData!.userId,
        name: otherUser!.name,
        userName: otherUser!.userName,
        senderUserId: otherUser.userId
      );
      addFollowingDataFirebase(context, followBackUser: followBackUser).then((value) {
        getFollowStatus(otherUserId);
        notifyListeners();
      },);
    } else if (profileBtnStatus == "Send Message") {
      sendMessageFromProfile(context,otherUser:otherUser);
    }
    setLoading(false);
  }

  Future<String> getFollowStatus(String otherUserId) async {
    setLoading(true);
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setLoading(false);
      throw Exception("No logged in user");
    }

    final currentUserId = currentUser.uid;

    try {
      // Check if currentUser follows otherUser
      final followingDoc = await FirebaseFirestore.instance
          .collection(ConstantLabels.followingTable)
          .doc(currentUserId)
          .collection(ConstantLabels.friendsSubTable)
          .doc(otherUserId)
          .get();

      // Check if otherUser follows currentUser
      final followerDoc = await FirebaseFirestore.instance
          .collection(ConstantLabels.followerTable)
          .doc(currentUserId)
          .collection(ConstantLabels.friendsSubTable)
          .doc(otherUserId)
          .get();

      final isFollowing = followingDoc.exists;
      final isFollowedBy = followerDoc.exists;
      notifyListeners();

      LogHelper("lol $isFollowing && $isFollowedBy");
      if (isFollowing && isFollowedBy) {
        profileBtnStatus =  "Send Message";
        notifyListeners();
      } else if (isFollowing) {
        profileBtnStatus =  "following";
        notifyListeners();
      } else if (isFollowedBy) {
        profileBtnStatus =  "follow back";
        notifyListeners();
      } else {
        profileBtnStatus =  "follow";
        notifyListeners();
      }
      notifyListeners();
      return profileBtnStatus;
    } catch (e) {
      LogHelper("Error checking follow status: $e");
      setLoading(false);
       profileBtnStatus =  "follow";
      notifyListeners();
    }
    setLoading(false);
    return profileBtnStatus;
  }

  updateFollowingRoomName({required String roomName, required String userId, required String otherUserId}) async {

    final subCollectionRef = FirebaseFirestore.instance
        .collection(ConstantLabels.followingTable)
        .doc(userId)
        .collection(ConstantLabels.friendsSubTable);

    if (otherUserId.isNotEmpty) {
      try {
        await subCollectionRef.doc(otherUserId).set(
          {'roomName': roomName},
          SetOptions(merge: true),
        );
        LogHelper("roomName updated successfully in following table");

      } catch (e) {
        LogHelper("Error updating roomName: $e");
      }
    } else {
      LogHelper("Document ID is missing; cannot update roomName.");
    }
  }

  updateFollowerRoomName({required String roomName, required String userId, required String otherUserId}) async {

    final subCollectionRef = FirebaseFirestore.instance
        .collection(ConstantLabels.followerTable)
        .doc(userId)
        .collection(ConstantLabels.friendsSubTable);

      try {
        await subCollectionRef.doc(otherUserId).set(
          {'roomName': roomName},
          SetOptions(merge: true),
        );
        LogHelper("roomName updated successfully in Follower table");

      } catch (e) {
        LogHelper("Error updating roomName Follower table: $e");
      }

  }

  setLoading(bool value) {
    isLoader = value;
    notifyListeners();
  }
}
