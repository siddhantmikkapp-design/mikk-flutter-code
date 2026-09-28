import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mikk/Model/SearchModel.dart';
import '../utils/LogHelper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SearchViewModel extends ChangeNotifier {
  TextEditingController searchController = TextEditingController();
  List<SearchModel> searchUsers = [];

  bool isLoader = false;
  static const int REQUIRED_ID_LENGTH = 5; // ID must be exactly 5 characters

  // Search users by exact ID (5 characters)
  Future<void> fetchSearchUserById({required String searchTxt}) async {
    // Reset if less than 5 characters
    if (searchTxt.length < REQUIRED_ID_LENGTH) {
      resetSearch();
      return;
    }

    // Only search when exactly 5 characters
    if (searchTxt.length != REQUIRED_ID_LENGTH) {
      return;
    }

    LogHelper("=== SEARCH STARTED ===");
    LogHelper("Search text: '$searchTxt' (${searchTxt.length} chars)");

    final user = FirebaseAuth.instance.currentUser;

    setLoading(true);

    try {
      // Exact match query - only fetches users with this exact ID
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('id', isEqualTo: searchTxt) // Exact match
          .get();

      LogHelper("Query returned ${snapshot.docs.length} documents");

      searchUsers.clear();

      for (var doc in snapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data();

          String? uid = data['uid'] ?? doc.id;
          String? name = data['name'];
          String? profilePic = data['profilePic'];
          String? id = data['id'];
          String? gender = data['gender'];
          // Skip current user
          if (user != null && uid == user.uid) {
            LogHelper("Skipping current user");
            continue;
          }

          if (id != null && id.isNotEmpty) {
            SearchModel userModel = SearchModel(
              userId: uid,
              name: name,
              profilePic: profilePic,
              id: id,
              gender: gender,
            );

            searchUsers.add(userModel);
            LogHelper("✓ User found: $name - ID: $id");
          }
        } catch (e) {
          LogHelper("Error parsing user doc ${doc.id}: $e");
          continue;
        }
      }

      if (searchUsers.isEmpty) {
        LogHelper("No user found with ID: $searchTxt");
      }

      LogHelper("Final searchUsers count: ${searchUsers.length}");
      LogHelper("=== SEARCH ENDED ===");

    } catch (e) {
      LogHelper("Error searching users: $e");
    }

    setLoading(false);
    notifyListeners();
  }

  // Reset search
  void resetSearch({bool isClearController = false}) {
    if (isClearController) {
      searchController.clear();
    }
    searchUsers = [];
    notifyListeners();
  }

  // Set loading state
  void setLoading(bool value) {
    isLoader = value;
    notifyListeners();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}