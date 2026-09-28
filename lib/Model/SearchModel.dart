class SearchModel {
  String? userId;
  String? name;
  String? profilePic;
  String? id;
  String ? gender;
  String ? avatarFileName;
  String ? modelURL;

  SearchModel({
    this.userId,
    this.name,
    this.profilePic,
    this.id,
    this.gender,
    this.avatarFileName,
    this.modelURL
  });

  factory SearchModel.fromJson(Map<String, dynamic> json, String docId) {
    return SearchModel(
      userId: json['uid'] ?? docId, // Use document ID as fallback
      name: json['name'] ?? '',
      profilePic: json['profilePic'] ?? '',
      id: json['id'] ?? '',
      gender: json['gender'] ?? '',
      avatarFileName: json['avatarFileName'] ?? '' ,
      modelURL: json['modelURL'] ?? ''
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': userId,
      'name': name,
      'profilePic': profilePic,
      'id': id,
      'gender' : gender,
      'avatarFileName': avatarFileName,
      'modelURL' : modelURL
    };
  }
}