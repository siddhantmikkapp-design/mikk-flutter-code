import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:mikk/Model/UserProfileModel.dart';
import 'package:mikk/Model/auth/SignUpModel.dart';
import 'package:mikk/utils/CommonMethods.dart';
import 'package:mikk/utils/LogHelper.dart';
import 'package:mikk/values/StaticText.dart';

import '../../Model/ConnectWithUsers.dart';
import '../../Model/auth/UserNameModel.dart';
import '../../utils/SessionManager.dart';

class PersonalInformationViewModel extends ChangeNotifier {
  TextEditingController userNameController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController dobController = TextEditingController();
  TextEditingController mobileController = TextEditingController();
  List<SignUpModel> userData = [];

  // String avatarUrl = "";
  // String profilePic = "";
  bool isLoader = false;

  List<ConnectWithUsers> allUsersData = [];

  updateController({
    String data = "",
    bool isUserName = false,
    bool isName = false,
    bool isMobileName = false,
    bool isEmailName = false,
    bool isDob = false,
  }) {
    if (data.isEmpty) {
      LogHelper("data isEmpty $data");
    } else if (isUserName) {
      userNameController.text = data;
    } else if (isName) {
      nameController.text = data;
    } else if (isMobileName) {
      mobileController.text = data;
    } else if (isEmailName) {
      emailController.text = data;
    } else if (isDob) {
      dobController.text = CommonMethods.parseDateFormat(DateTime.now().toString(), "", "dd-MMM-yyyy");
    }
    notifyListeners();
  }

  setCurrentUserData() async {
    setLoading(true);
    List<Map<String, dynamic>?> data = await getUserData();
    if (data.isNotEmpty) {
      userData = data.map((data) => SignUpModel.fromJson(data!)).toList();
      // List<SignUpModel> userData =  data.map((e) => SignUpModel.fromJson(jsonEncode(e))).toList();
    }
    SignUpModel user = userData.first;
    userNameController.text = user.userName.toString();
    nameController.text = user.name.toString();
    dobController.text = CommonMethods.parseDateFormat(DateTime.now().toString(), "", "dd-MMM-yyyy");
    // dobController.text = user.name.toString();
    mobileController.text = user.number.toString();
    emailController.text = user.email.toString();

    SessionManager.setStringData(SessionManager.USER_ID, user.userId.toString());
    SessionManager.setStringData(SessionManager.FULL_NAME, user.name.toString());
    SessionManager.setStringData(SessionManager.MOBILE, user.number.toString());
    SessionManager.setStringData(SessionManager.EMAIL, user.email.toString());
    SessionManager.setStringData(SessionManager.USER_NAME, user.userName.toString());
    SessionManager.setBooleanData(SessionManager.IS_EMAIL_VERIFIED, user.isEmailVerified ?? false);
    SessionManager.setBooleanData(SessionManager.IS_PHONE_VERIFIED, user.isPhoneVerified ?? false);
    setLoading(false);

    notifyListeners();
  }

  Future<List<Map<String, dynamic>?>> getUserData({String userId = ""}) async {
    try {
      setLoading(true);

      /// if Searched user is null then current login User fetch
      if (userId.isEmpty) {
        User? user = await FirebaseAuth.instance.currentUser;
        userId = user != null ? user.uid : "";
      }

      if (userId.isEmpty) {
        LogHelper('No user is signed in.');
        return [];
      }

      LogHelper("Fetching data for user ID: $userId");

      final querySnapshot = await FirebaseFirestore.instance.collection(ConstantLabels.signUpTable).where("userId", isEqualTo: userId).get();

      setLoading(false);

      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs
            .map(
              (e) => e.data(),
            )
            .toList();
        LogHelper("User Data: ${jsonEncode(userData)}");
        return userData;
      } else {
        LogHelper('User document not found.');
        return [];
      }
    } catch (e) {
      setLoading(false);
      LogHelper('Error fetching user data: $e');
      return [];
    }
  }

  Future<UserProfileModel?> getUserProfile({String userId = ""}) async {
    try {
      setLoading(true);

      // If no userId is passed, get the current user
      if (userId.isEmpty) {
        User? user = FirebaseAuth.instance.currentUser;
        userId = user?.uid ?? "";
      }

      if (userId.isEmpty) {
        LogHelper('No user is signed in.');
        return null;
      }

      LogHelper("User ID: $userId");

      // Fetch the specific user document
      final docSnapshot = await FirebaseFirestore.instance
          .collection(ConstantLabels.profileTable)
          .doc(userId)
          .get();

      setLoading(false);

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null) {
          // UserProfileModel(
          //   profilePic: data['AvatarUrl'],
          //   avatarUrl: data['ProfilePic'],
          // );
          LogHelper("User ProfilePic & AvatarUrl : ${jsonEncode(data)}");

          // avatarUrl = data['AvatarUrl'];
          // profilePic = data['ProfilePic'];
          return UserProfileModel.fromJson(data);
        }
      } else {
        LogHelper('User document not found.');
        return null;
      }
    } catch (e) {
      setLoading(false);
      LogHelper('Error fetching user data: $e');
      return null;
    }
    return null;
  }

  Future<void> updateUserProfile({
    String userId = "",
    String? profilePic,
    String? avatarUrl,
  }) async {
    try {
      setLoading(true);
      if (userId.isEmpty) {
        User? user = FirebaseAuth.instance.currentUser;
        userId = user?.uid ?? "";
        notifyListeners();
      }

      if (userId.isEmpty) {
        LogHelper('No user is signed in.');
        return;
      }

      if (profilePic != null && avatarUrl != null) {
        UserProfileModel updateData = UserProfileModel(profilePic: profilePic, avatarUrl: avatarUrl);

        await FirebaseFirestore.instance.collection(ConstantLabels.profileTable).doc(userId).update(updateData.toJson());
        LogHelper("User profile updated successfully: $updateData");
      }else{
        LogHelper("User profile ");
      }
      setLoading(false);
    } catch (e) {
      setLoading(false);
      LogHelper('Error updating user profile: $e');
    }
  }

  Future<List<ConnectWithUsers>> getAllUserData() async {
    try {
      setLoading(true);

      LogHelper("Fetching all user data");

      final querySnapshot = await FirebaseFirestore.instance.collection(ConstantLabels.signUpTable).get();

      setLoading(false);

      allUsersData = querySnapshot.docs.map((e) => ConnectWithUsers.fromJson(e.data())).toList();
      LogHelper("All User Data: ${allUsersData.length}");

      User? user = await FirebaseAuth.instance.currentUser;
      String userId = user != null ? user.uid : "";

      allUsersData.removeWhere((element) => element.userId  == userId);
      allUsersData.forEach(
        (element) async {
          UserProfileModel? userProfile;
          userProfile = await getUserProfile(userId: element.userId.toString());
          notifyListeners();
          if (userProfile != null) {
            element.avatarUrl = userProfile.avatarUrl;
            element.profilePic = userProfile.profilePic;
            notifyListeners();
          }
        },
      );
      notifyListeners();
      return allUsersData;
    } catch (e) {
      setLoading(false);
      LogHelper('Error fetching user data: $e');
      return [];
    }
  }

  Future<void> updateUserData({
    String userId = "",
    required Map<String, dynamic> updatedFields,
  }) async {
    try {
      updatedFields.removeWhere((key, value) => value == null);
      LogHelper("updatedFields ${updatedFields}");
      if (userId.isEmpty) {
        User? user = FirebaseAuth.instance.currentUser;
        userId = user?.uid ?? "";
      }

      if (userId.isEmpty) {
        LogHelper('No user is signed in.');
        return;
      }

      // Query to find the document with matching userId
      final querySnapshot = await FirebaseFirestore.instance
          .collection(ConstantLabels.signUpTable)
          .where("userId", isEqualTo: userId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final docId = querySnapshot.docs.first.id;

        await FirebaseFirestore.instance
            .collection(ConstantLabels.signUpTable)
            .doc(docId)
            .update(updatedFields);

        LogHelper("User data updated: $updatedFields");
      } else {
        LogHelper('No matching user document found to update.');
      }
    } catch (e) {
      LogHelper('Error updating user data: $e');
    }
  }

  setLoading(bool value) {
    isLoader = value;
    notifyListeners();
  }
}
