class Conversation {
  final String id;
  final List<String> participants;
  final String? lastMessageText;
  final String? lastMessageSenderId;
  final int lastMessageTimestamp;
  final int updatedAt;

  Conversation({
    required this.id,
    required this.participants,
    this.lastMessageText,
    this.lastMessageSenderId,
    required this.lastMessageTimestamp,
    required this.updatedAt,
  });

  factory Conversation.fromJson(String id, Map<String, dynamic> json) {
    return Conversation(
      id: id,
      participants: List<String>.from(json['participants']?.keys ?? []),
      lastMessageText: json['lastMessage']?['text'],
      lastMessageSenderId: json['lastMessage']?['senderId'],
      lastMessageTimestamp: json['lastMessage']?['timestamp'] ?? 0,
      updatedAt: json['updatedAt'] ?? 0,
    );
  }

  String getOtherUserId(String currentUserId) {
    return participants.firstWhere((id) => id != currentUserId, orElse: () => '');
  }
}
