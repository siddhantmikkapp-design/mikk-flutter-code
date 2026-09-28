import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:mikk/Model/UserProfileModel.dart';
import 'package:mikk/Model/auth/UserNameModel.dart';
import 'package:mikk/View_Model/SettingsDetailViewModel/PersonalInformationViewModel.dart';
import 'package:mikk/utils/LogHelper.dart';

import '../values/StaticText.dart';
import 'FollowerFollowingViewModel.dart';

class DashboardViewModel extends ChangeNotifier {
  TextEditingController searchController = TextEditingController();
  List<UserNameModel> allUsers = [];
  List<UserNameModel> searchUsers = [];

  bool isLoader = false;

  fetchSearchUserName({required String searchTxt}) async {
    final user = FirebaseAuth.instance.currentUser;
    setLoading(true);
    if (allUsers.isEmpty) {
      await fetchAllUserName();
    }
    searchUsers = allUsers;
    notifyListeners();
    if (user != null) {
      searchUsers.removeWhere((element) => element.userId == user.uid);
      notifyListeners();
    }
    searchUsers = searchUsers.where((element) => element.userName.toString().toLowerCase().contains(searchTxt) || element.name.toString().toLowerCase().contains(searchTxt)).toList();
    notifyListeners();
    if(user != null && user.uid.isNotEmpty) {
      setLoading(true);
      searchUsers.forEach(
      (element) async {
        UserProfileModel? userProfile = await PersonalInformationViewModel().getUserProfile(userId: element.userId.toString());
        if(userProfile != null) {
          element.profilePic = userProfile.profilePic;
          notifyListeners();
        }
        await FollowerFollowingViewModel().getFollowerData(
          searchedUserId: element.userId.toString(),
          currentUserId: user!.uid,
        ).then((value) {
              element.isRequestSent = value != null;
              setLoading(false);
            },
          );
          LogHelper("searchUsers:----- ${element.name} - ${element.userName}");
        notifyListeners();
      },
    );
    }else{
      LogHelper("userId Not Found fetchSearchUserName");
      setLoading(false);
    }
    notifyListeners();
  }

  fetchAllUserName() async {
    setLoading(true);
    final snapshot = await FirebaseFirestore.instance.collection(ConstantLabels.userNameTable).get();

    List<Map<String, dynamic>> allUsersData = snapshot.docs.map((doc) => doc.data()).toList();
    for (var doc in allUsersData) {
      LogHelper("User: ${doc['Name']} - ${doc['UserName']}");
    }
    allUsers = allUsersData.map((data) => UserNameModel.fromJson(data)).toList();
    LogHelper("allUsers ${allUsers.length}");
    setLoading(false);
    notifyListeners();
  }

  resetSearch({bool isClearController = false}){
    setLoading(true);
    if(isClearController) {
      searchController.clear();
    }
    searchUsers = [];
    setLoading(false);
    notifyListeners();
  }

  setLoading(bool value) {
    isLoader = value;
    notifyListeners();
  }

}
