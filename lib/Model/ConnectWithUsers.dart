class ConnectWithUsers {
  String? userName, name, number, password, email, userId;
  String? gender, bio, doB, fcm;
  String? avatarUrl, profilePic;
  String? btnStatus;
  bool? isPhoneVerified;
  bool? isEmailVerified;
  bool? isVip;

  ConnectWithUsers({
    this.userName,
    this.name,
    this.number,
    // this.city,
    this.password,
    this.email,
    this.isEmailVerified,
    this.isPhoneVerified,
    this.userId,
    this.avatarUrl,
    this.gender,
    this.profilePic,
    this.bio,
    this.doB,
    this.fcm,
    this.isVip,
    this.btnStatus
  });

  ConnectWithUsers.fromJson(Map<String, dynamic> json) {
    userName = json['UserName'];
    name = json['Name'];
    number = json['Number'];
    // city = json['City'];
    password = json['Password'];
    email = json['Email'];
    userId = json['userId'];
    avatarUrl = json['AvatarUrl'] ?? "";
    gender = json['Gender'] ?? "";
    profilePic = json['ProfilePic'] ?? "";
    bio = json['Bio'] ?? "";
    doB = json['DoB'] ?? "";
    fcm = json['Fcm'] ?? "";

    isEmailVerified = json['IsEmailVerified'] ?? false;
    isPhoneVerified = json['IsPhoneVerified'] ?? false;
    isVip = json['IsVip'] ?? false;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['UserName'] = this.userName;
    data['Name'] = this.name;
    data['Number'] = this.number;
    // data['City'] = this.city;
    data['Password'] = this.password;
    data['Email'] = this.email;
    data['userId'] = this.userId;
    data['AvatarUrl'] = this.avatarUrl;
    data['Gender'] = this.gender;
    data['ProfilePic'] = this.profilePic;
    data['Bio'] = this.bio;
    data['DoB'] = this.doB;
    data['Fcm'] = this.fcm;
    data['IsEmailVerified'] = this.isEmailVerified;
    data['IsPhoneVerified'] = this.isPhoneVerified;
    data['IsVip'] = this.isVip;
    return data;
  }
}
