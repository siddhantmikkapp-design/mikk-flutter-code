class NotificationModel {
  String? userName, name, receiverUserId,senderUserId;
  bool? isRead,isFollower,isFollowing;
  // bool? isAccepted,isRejected;
  String? timeStamp;
  String? roomName;

  NotificationModel({
    this.userName,
    this.name,
    this.receiverUserId,
    this.senderUserId,
    this.timeStamp,
    this.isRead,
    this.isFollower,
    this.isFollowing,
    this.roomName,
    // this.isAccepted,
    // this.isRejected,
  });

  NotificationModel.fromJson(Map<String, dynamic> json) {
    userName = json['UserName'] ?? "";
    name = json['Name'] ?? "";
    receiverUserId  = json['UserId'] ?? "";
    senderUserId = json['SenderId'] ?? "";
    timeStamp = json['timeStamp'] ?? "";
    roomName = json['roomName'] ?? "";
    isRead = json['isRead'] ?? false;
    isFollower = json['isFollower'] ?? false;
    isFollowing = json['isFollowing'] ?? false;
    // isAccepted = json['isAccepted'] ?? false;
    // isRejected = json['isRejected'] ?? false;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['UserName'] = this.userName;
    data['Name'] = this.name;
    data['UserId'] = this.receiverUserId;
    data['SenderId'] = this.senderUserId;
    data['timeStamp'] = this.timeStamp;
    if (roomName != null) {
      data['roomName'] = this.roomName;
    }
    data['isRead'] = this.isRead;
    data['isFollower'] = this.isFollower;
    data['isFollowing'] = this.isFollowing;
    // data['isAccepted'] = this.isAccepted;
    // data['isRejected'] = this.isRejected;

    return data;
  }
}
