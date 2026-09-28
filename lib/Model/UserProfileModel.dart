class UserProfileModel {
  String? profilePic;
  String? avatarUrl;

  UserProfileModel({this.profilePic, this.avatarUrl});

  UserProfileModel.fromJson(Map<String, dynamic> json) {
    profilePic = json['ProfilePic'] ?? "";
    avatarUrl = json['AvatarUrl'] ?? "";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['ProfilePic'] = this.profilePic;
    data['AvatarUrl'] = this.avatarUrl;
    return data;
  }
}
