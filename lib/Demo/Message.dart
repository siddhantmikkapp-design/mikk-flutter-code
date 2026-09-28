import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';


class Message {
  final String id;
  final String text;
  final String senderId;
  final int timestamp;
  final String type;

  Message({
    required this.id,
    required this.text,
    required this.senderId,
    required this.timestamp,
    this.type = 'text',
  });

  factory Message.fromJson(String id, Map<String, dynamic> json) {
    return Message(
      id: id,
      text: json['text'] ?? '',
      senderId: json['senderId'] ?? '',
      timestamp: json['timestamp'] ?? 0,
      type: json['type'] ?? 'text',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'senderId': senderId,
      'timestamp': timestamp,
      'type': type,
    };
  }

  bool get isMe => senderId == FirebaseAuth.instance.currentUser?.uid;

  String get formattedTime {
    if (timestamp == 0) return "";
    // ✅ Use positive timestamp directly
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('HH:mm').format(dateTime);
  }
}