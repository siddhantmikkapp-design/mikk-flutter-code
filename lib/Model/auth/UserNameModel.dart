import 'package:mikk/Model/UserProfileModel.dart';

class UserNameModel {
  String? userName, name, userId;
  bool? isRequestSent;
  String? profilePic;
  String? avatarUrl;

  // UserProfileModel? userProfile;

  UserNameModel({
    this.userName,
    this.name,
    this.userId,
  });

  UserNameModel.fromJson(Map<String, dynamic> json) {
    userName = json['UserName'] ?? "";
    name = json['Name'] ?? "";
    userId = json['UserId'] ?? "";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['UserName'] = this.userName;
    data['Name'] = this.name;
    data['UserId'] = this.userId;
    return data;
  }
}
