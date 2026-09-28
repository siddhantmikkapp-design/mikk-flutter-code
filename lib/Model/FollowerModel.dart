class FollowerFollowingModel {
  String? userName, name, userId;
  String? frId;
  String? roomName;
  bool? isBlocked;

  FollowerFollowingModel({
    this.userName,
    this.name,
    this.userId,
    this.isBlocked,
    this.roomName,
    this.frId
  });

  FollowerFollowingModel.fromJson(Map<String, dynamic> json) {
    userName = json['UserName'] ?? "";
    name = json['Name'] ?? "";
    userId = json['UserId'] ?? "";
    frId = json['FrId'] ?? "";
    roomName = json['roomName'] ?? "";
    isBlocked = json['IsBlocked'] ?? false;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['UserName'] = this.userName;
    data['Name'] = this.name;
    data['UserId'] = this.userId;
    data['FrId'] = this.frId;
    data['roomName'] = this.roomName;
    data['IsBlocked'] = this.isBlocked;
    return data;
  }
}
