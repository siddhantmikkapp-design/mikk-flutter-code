import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';

import '../../Demo/Message.dart';
import '../../Model/Conversation.dart';
import '../../values/StaticText.dart';


class ChatService extends ChangeNotifier {
  final DatabaseReference _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: ConstantLabels.realTimeKey,
  ).ref();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  List<Message> _messages = [];
  List<Conversation> _conversations = [];
  bool _isLoading = false;
  StreamSubscription? _messagesSubscription;
  StreamSubscription? _conversationsSubscription;

  List<Message> get messages => _messages;
  List<Conversation> get conversations => _conversations;
  bool get isLoading => _isLoading;

  // Generate conversation ID (smaller userId first for consistency)
  String _getConversationId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2];
    ids.sort();
    return '${ids[0]}_${ids[1]}';
  }

  // Send a message
  Future<void> sendMessage(String receiverId, String text) async {
    if (text.trim().isEmpty) return;

    try {
      final conversationId = _getConversationId(currentUserId, receiverId);
      final timestamp = DateTime.now().millisecondsSinceEpoch; // ✅ POSITIVE timestamp

      // Create message
      final messageRef = _database.child('messages').child(conversationId).push();
      final message = Message(
        id: messageRef.key!,
        text: text.trim(),
        senderId: currentUserId,
        timestamp: timestamp,
      );

      // Save message
      await messageRef.set(message.toJson());

      // Update conversation
      await _database.child('conversations').child(conversationId).update({
        'participants/$currentUserId': true,
        'participants/$receiverId': true,
        'lastMessage': {
          'text': text.trim(),
          'senderId': currentUserId,
          'timestamp': timestamp,
        },
        'updatedAt': timestamp,
      });

      print("✅ Message sent successfully");
    } catch (e) {
      print("❌ Error sending message: $e");
    }
  }

  // Listen to messages for a conversation
  void listenToMessages(String receiverId) {
    _messagesSubscription?.cancel();

    final conversationId = _getConversationId(currentUserId, receiverId);

    _setLoading(true);

    _messagesSubscription = _database
        .child('messages')
        .child(conversationId)
        .orderByChild('timestamp') // ✅ Order by timestamp
        .onValue
        .listen((event) {

      _messages.clear();

      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);

        data.forEach((key, value) {
          final message = Message.fromJson(key, Map<String, dynamic>.from(value));
          _messages.add(message);
        });

        // ✅ Sort OLDEST first (for reverse ListView)
        _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      }

      _setLoading(false);
      notifyListeners();
    });
  }

  // Listen to all conversations
  void listenToConversations() {
    _conversationsSubscription?.cancel();

    _conversationsSubscription = _database
        .child('conversations')
        .orderByChild('updatedAt')
        .onValue
        .listen((event) {

      _conversations.clear();

      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);

        data.forEach((key, value) {
          final conversation = Conversation.fromJson(key, Map<String, dynamic>.from(value));

          // Only include conversations where current user is a participant
          if (conversation.participants.contains(currentUserId)) {
            _conversations.add(conversation);
          }
        });

        // Sort by updatedAt (newest first for conversation list)
        _conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      }

      notifyListeners();
    });
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void dispose() {
    _messagesSubscription?.cancel();
    _conversationsSubscription?.cancel();
    super.dispose();
  }
}