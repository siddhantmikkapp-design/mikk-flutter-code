import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mikk/Model/SearchModel.dart';

import '../utils/LogHelper.dart';

class ProfileViewModel extends ChangeNotifier {
  SearchModel? profileUser; // The profile being viewed
  SearchModel? currentUser; // Your own data
  bool isLoading = false;
  bool isOwnProfile = false;


  // Get current user's data
  Future<void> getCurrentUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        LogHelper("No authenticated user found");
        return;
      }

      LogHelper("Loading current user data for: ${user.uid}");

      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        currentUser = SearchModel(
          userId: data['uid'] ?? doc.id,
          name: data['name'],
          profilePic: data['profilePic'],
          id: data['id'],
          gender: data['gender'],
          avatarFileName: data['avatarFileName'],
          modelURL: data['modelURL']
        );

        LogHelper("Current user loaded: ${currentUser?.name} - ID: ${currentUser?.id}");
        notifyListeners();
      } else {
        LogHelper("Current user document not found");
      }
    } catch (e) {
      LogHelper("Error loading current user: $e");
    }
  }

  // Get user profile data
  Future<void> getUserProfile({required String userId}) async {
    setLoading(true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      // ALWAYS load current user data first
      if (user != null) {
        await getCurrentUserData();
      }

      // Check if it's own profile
      isOwnProfile = user != null && user.uid == userId;

      // If viewing own profile, use currentUser data
      if (isOwnProfile && currentUser != null) {
        profileUser = currentUser;
        LogHelper("Viewing own profile");
        setLoading(false);
        notifyListeners();
        return;
      }

      // Fetch other user's data from Firestore
      LogHelper("Fetching profile for userId: $userId");
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        profileUser = SearchModel(
          userId: data['uid'] ?? doc.id,
          name: data['name'],
          profilePic: data['profilePic'],
          id: data['id'],
          gender: data['gender'],
            modelURL: data['modelURL']
        );

        LogHelper("Profile loaded: ${profileUser?.name} - ID: ${profileUser?.id}");
      } else {
        LogHelper("User document not found for: $userId");
      }
    } catch (e) {
      LogHelper("Error loading profile: $e");
    }

    setLoading(false);
    notifyListeners();
  }

  // Set loading state
  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  // Clear profile data
  void clearProfile() {
    profileUser = null;
    isOwnProfile = false;
    notifyListeners();
  }

  @override
  void dispose() {
    clearProfile();
    super.dispose();
  }
}