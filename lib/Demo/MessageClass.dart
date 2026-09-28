import 'package:intl/intl.dart';


// message_class.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// message_class.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MessageClass {
  String? userId;
  String? otherUserId;
  String? messageId;
  String? message;
  String? roomName;
  String? name;
  int? timeStamp;
  bool? isRead;
  bool isMe = true;
  String? profilePic;
  String? avatarUrl;
  int? unreadCount;

  // ═══════════════════════════════════════════════════════════════
  // REPLY FIELDS (NEW)
  // ═══════════════════════════════════════════════════════════════
  String? replyToMessageId;
  String? replyToMessage;
  String? replyToSenderId;
  String? replyToSenderName;

  MessageClass({
    this.userId,
    this.message,
    this.timeStamp,
    this.roomName,
    this.name,
    this.otherUserId,
    this.messageId,
    this.isRead,
    this.profilePic,
    this.avatarUrl,
    this.unreadCount,
    this.replyToMessageId,
    this.replyToMessage,
    this.replyToSenderId,
    this.replyToSenderName,
  });

  // ═══════════════════════════════════════════════════════════════
  // HELPER: Check if this is a reply
  // ═══════════════════════════════════════════════════════════════
  bool get isReply => replyToMessageId != null && replyToMessageId!.isNotEmpty;

  // ═══════════════════════════════════════════════════════════════
  // FIRESTORE FACTORIES
  // ═══════════════════════════════════════════════════════════════

  factory MessageClass.fromFirestoreDashboard(
      Map<String, dynamic> json,
      String docId,
      ) {
    return MessageClass(
      otherUserId: json['otherUserId'] ?? '',
      name: json['otherUserName'] ?? '',
      message: json['lastMessage'] ?? '',
      timeStamp: _parseTimestamp(json['lastMessageTime']),
      isRead: json['isRead'] ?? false,
      profilePic: json['otherUserProfilePic'] ?? '',
      avatarUrl: json['otherUserAvatarUrl'] ?? '',
      unreadCount: json['unreadCount'] ?? 0,
      roomName: json['roomName'] ?? '',

    );
  }

  factory MessageClass.fromFirestoreMessage(
      Map<String, dynamic> json,
      String docId,
      ) {
    return MessageClass(
      messageId: docId,
      userId: json['senderId'] ?? '',
      message: json['text'] ?? '',
      timeStamp: _parseTimestamp(json['timestamp']),
      isRead: json['isRead'] ?? false,
      roomName: json['roomName'] ?? '',
      // Reply fields
      replyToMessageId: json['replyToMessageId'],
      replyToMessage: json['replyToMessage'],
      replyToSenderId: json['replyToSenderId'],
      replyToSenderName: json['replyToSenderName'],
    );
  }

  static int? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is Timestamp) {
      return timestamp.millisecondsSinceEpoch;
    }
    if (timestamp is int) {
      return timestamp.abs();
    }
    return null;
  }

  MessageClass.fromJson(Map<String, dynamic> json) {
    userId = json['UserId'] ?? "";
    message = json['Message'] ?? "";
    timeStamp = (json['TimeStamp'] as int?)?.abs() ?? 0;
    roomName = json['RoomName'] ?? "";
    name = json['Name'] ?? "";
    otherUserId = json['OtherUserId'] ?? "";
    isRead = json['isRead'] ?? false;
    profilePic = json['profilePic'] ?? "";
  }

  Map<String, dynamic> toJson() {
    return {
      'UserId': userId,
      'Message': message,
      'TimeStamp': timeStamp,
      'RoomName': roomName,
      'Name': name,
      'OtherUserId': otherUserId,
      'isRead': isRead,
      'profilePic': profilePic,
    };
  }

  String getFormattedTime() {
    if (timeStamp == null || timeStamp == 0) return "";
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timeStamp!);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final difference = today.difference(messageDate).inDays;

    if (difference == 0) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference == 1) {
      return "Yesterday";
    } else if (difference < 7) {
      return DateFormat('EEEE').format(dateTime);
    } else {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    }
  }

  String getMessageTime() {
    if (timeStamp == null || timeStamp == 0) return "";
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timeStamp!);
    return DateFormat('HH:mm').format(dateTime);
  }

  MessageClass copyWith({
    String? oduserId,
    String? otherUserId,
    String? messageId,
    String? message,
    String? roomName,
    String? name,
    int? timeStamp,
    bool? isRead,
    String? profilePic,
    String? avatarUrl,
    int? unreadCount,
    String? replyToMessageId,
    String? replyToMessage,
    String? replyToSenderId,
    String? replyToSenderName,
  }) {
    return MessageClass(
      userId: oduserId ?? this.userId,
      otherUserId: otherUserId ?? this.otherUserId,
      messageId: messageId ?? this.messageId,
      message: message ?? this.message,
      roomName: roomName ?? this.roomName,
      name: name ?? this.name,
      timeStamp: timeStamp ?? this.timeStamp,
      isRead: isRead ?? this.isRead,
      profilePic: profilePic ?? this.profilePic,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      unreadCount: unreadCount ?? this.unreadCount,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToMessage: replyToMessage ?? this.replyToMessage,
      replyToSenderId: replyToSenderId ?? this.replyToSenderId,
      replyToSenderName: replyToSenderName ?? this.replyToSenderName,
    );
  }

  @override
  String toString() {
    return 'MessageClass(messageId: $messageId, message: $message, '
        'timestamp: $timeStamp, isRead: $isRead, isReply: $isReply)';
  }
}



/*
class MessageClass {
  String? userId;
  String? otherUserId;
  String? messageId;
  String? message;
  String? roomName;
  String? name;
  int? timeStamp;
  bool? isRead;
  bool isMe = true;
  String? profilePic;
  String? avatarUrl;
  int? unreadCount;

  MessageClass({
    this.userId,
    this.message,
    this.timeStamp,
    this.roomName,
    this.name,
    this.otherUserId,
    this.messageId,
    this.isRead,
    this.profilePic,
    this.avatarUrl,
    this.unreadCount,
  });

  // ═══════════════════════════════════════════════════════════════
  // FIRESTORE FACTORIES
  // ═══════════════════════════════════════════════════════════════

  /// For dashboard/conversation list items
  factory MessageClass.fromFirestoreDashboard(
      Map<String, dynamic> json,
      String docId,
      ) {
    return MessageClass(
      otherUserId: json['otherUserId'] ?? '',
      name: json['otherUserName'] ?? '',
      message: json['lastMessage'] ?? '',
      timeStamp: _parseTimestamp(json['lastMessageTime']),
      isRead: json['isRead'] ?? false,
      profilePic: json['otherUserProfilePic'] ?? '',
      avatarUrl: json['otherUserAvatarUrl'] ?? '',
      unreadCount: json['unreadCount'] ?? 0,
      roomName: json['roomName'] ?? '',
    );
  }

  /// For individual messages in chat
  factory MessageClass.fromFirestoreMessage(
      Map<String, dynamic> json,
      String docId,
      ) {
    return MessageClass(
      messageId: docId,
      userId: json['senderId'] ?? '',
      message: json['text'] ?? '',
      timeStamp: _parseTimestamp(json['timestamp']),
      isRead: json['isRead'] ?? false,
      roomName: json['roomName'] ?? '',
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TIMESTAMP HELPER
  // ═══════════════════════════════════════════════════════════════

  /// Parse Firestore Timestamp or int to milliseconds
  static int? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;

    if (timestamp is Timestamp) {
      return timestamp.millisecondsSinceEpoch;
    }

    if (timestamp is int) {
      // Handle both positive and negative (legacy) timestamps
      return timestamp.abs();
    }

    return null;
  }

  // ═══════════════════════════════════════════════════════════════
  // LEGACY REALTIME DATABASE SUPPORT
  // ═══════════════════════════════════════════════════════════════

  /// Parse from Realtime Database format (for backward compatibility)
  MessageClass.fromJson(Map<String, dynamic> json) {
    userId = json['UserId'] ?? "";
    message = json['Message'] ?? "";
    timeStamp = (json['TimeStamp'] as int?)?.abs() ?? 0;
    roomName = json['RoomName'] ?? "";
    name = json['Name'] ?? "";
    otherUserId = json['OtherUserId'] ?? "";
    isRead = json['isRead'] ?? false;
    profilePic = json['profilePic'] ?? "";
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'UserId': userId,
      'Message': message,
      'TimeStamp': timeStamp,
      'RoomName': roomName,
      'Name': name,
      'OtherUserId': otherUserId,
      'isRead': isRead,
      'profilePic': profilePic,
    };
  }

  // ═══════════════════════════════════════════════════════════════
  // TIME FORMATTING
  // ═══════════════════════════════════════════════════════════════

  /// Format time for dashboard display (e.g., "10:30", "Yesterday", "Monday")
  String getFormattedTime() {
    if (timeStamp == null || timeStamp == 0) return "";

    final dateTime = DateTime.fromMillisecondsSinceEpoch(timeStamp!);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final difference = today.difference(messageDate).inDays;

    if (difference == 0) {
      // Today - show time
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference == 1) {
      // Yesterday
      return "Yesterday";
    } else if (difference < 7) {
      // This week - show day name
      return DateFormat('EEEE').format(dateTime);
    } else {
      // Older - show date
      return DateFormat('dd/MM/yyyy').format(dateTime);
    }
  }

  /// Format time for message bubble (e.g., "10:30")
  String getMessageTime() {
    if (timeStamp == null || timeStamp == 0) return "";

    final dateTime = DateTime.fromMillisecondsSinceEpoch(timeStamp!);
    return DateFormat('HH:mm').format(dateTime);
  }

  // ═══════════════════════════════════════════════════════════════
  // COPY WITH
  // ═══════════════════════════════════════════════════════════════

  MessageClass copyWith({
    String? userId,
    String? otherUserId,
    String? messageId,
    String? message,
    String? roomName,
    String? name,
    int? timeStamp,
    bool? isRead,
    String? profilePic,
    String? avatarUrl,
    int? unreadCount,
  }) {
    return MessageClass(
      userId: userId ?? this.userId,
      otherUserId: otherUserId ?? this.otherUserId,
      messageId: messageId ?? this.messageId,
      message: message ?? this.message,
      roomName: roomName ?? this.roomName,
      name: name ?? this.name,
      timeStamp: timeStamp ?? this.timeStamp,
      isRead: isRead ?? this.isRead,
      profilePic: profilePic ?? this.profilePic,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  String toString() {
    return 'MessageClass(messageId: $messageId, message: $message, '
        'timestamp: $timeStamp, isRead: $isRead)';
  }
}*/



