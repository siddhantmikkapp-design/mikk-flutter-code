// firestore_chat_service.dart

import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import '../../Demo/MessageClass.dart';



class FirestoreChatService extends ChangeNotifier {
  // ═══════════════════════════════════════════════════════════════
  // FIREBASE REFERENCES
  // ═══════════════════════════════════════════════════════════════

  /// Firestore for messages, conversations, read receipts
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Realtime Database ONLY for typing indicators (low latency)
  final DatabaseReference _rtdb = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://mikklabs-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref();

  /// Current user ID
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  // ═══════════════════════════════════════════════════════════════
  // FIRESTORE COLLECTIONS
  // ═══════════════════════════════════════════════════════════════

  CollectionReference get _conversationsRef =>
      _firestore.collection('conversations');

  CollectionReference get _userConversationsRef =>
      _firestore.collection('userConversations');

  // ═══════════════════════════════════════════════════════════════
  // STATE - USER DATA
  // ═══════════════════════════════════════════════════════════════

  MessageClass? receiverUser;
  String? currentConversationId;
  String currentUserName = "";
  String? avatarUrl;

  // ═══════════════════════════════════════════════════════════════
  // STATE - MESSAGE STORAGE (Simplified: Single List)
  // ═══════════════════════════════════════════════════════════════

  /// All messages in current conversation
  final List<MessageClass> _messages = [];

  /// Dashboard/conversation list
  final List<MessageClass> dashboardMessageList = [];

  /// Getters for filtered access (maintains compatibility with UI)
  List<MessageClass> get sendMessageList =>
      _messages.where((m) => m.userId == uid).toList();

  List<MessageClass> get receiverMessageList =>
      _messages.where((m) => m.userId != uid).toList();

  // ═══════════════════════════════════════════════════════════════
  // STATE - PAGINATION (Cursor-Based)
  // ═══════════════════════════════════════════════════════════════

  static const int pageSize = 20;

  /// Cursor for loading older messages (scroll up)
  DocumentSnapshot? _oldestMessageDoc;

  /// Cursor for real-time listener (newest message we have)
  DocumentSnapshot? _newestMessageDoc;

  bool hasMoreMessages = true;
  bool isLoadingMore = false;
  bool _isInitialLoadComplete = false;

  // ═══════════════════════════════════════════════════════════════
  // STATE - TRACKING (Prevent Duplicates)
  // ═══════════════════════════════════════════════════════════════

  final Set<String> _loadedMessageIds = {};
  final Set<String> _loadedConversationIds = {};

  // ═══════════════════════════════════════════════════════════════
  // STATE - SUBSCRIPTIONS
  // ═══════════════════════════════════════════════════════════════

  StreamSubscription<QuerySnapshot>? _messagesSubscription;
  StreamSubscription<QuerySnapshot>? _dashboardSubscription;
  StreamSubscription<QuerySnapshot>? _readStatusSubscription;

  // ═══════════════════════════════════════════════════════════════
  // STATE - TYPING (RTDB)
  // ═══════════════════════════════════════════════════════════════

  DatabaseReference? _typingRef;

  // ═══════════════════════════════════════════════════════════════
  // STATE - LOADING
  // ═══════════════════════════════════════════════════════════════

  bool isLoader = false;

// ═══════════════════════════════════════════════════════════════
// ═══════════════════════════════════════════════════════════════
//                    BLOCKING
// ═══════════════════════════════════════════════════════════════
// ═══════════════════════════════════════════════════════════════

  CollectionReference get _blockedUsersRef =>
      _firestore.collection('users').doc(uid).collection('blocked_users');

  /// Users I have blocked (IDs — fast lookup)
  final Set<String> blockedUserIds = {};

  /// Users who have blocked me
  final Set<String> blockedByUserIds = {};

  /// Full details of users I've blocked (for the Blocked Accounts screen)
  final List<Map<String, dynamic>> blockedUsersDetails = [];

  StreamSubscription<QuerySnapshot>? _blockedByMeSubscription;
  StreamSubscription<QuerySnapshot>? _blockedByOthersSubscription;

  void listenToBlockedUsers() {
    _blockedByMeSubscription?.cancel();
    _blockedByMeSubscription = _blockedUsersRef.snapshots().listen((snapshot) {
      blockedUserIds
        ..clear()
        ..addAll(snapshot.docs.map((d) => d.id));

      blockedUsersDetails
        ..clear()
        ..addAll(snapshot.docs.map((d) {
          final data = d.data() as Map<String, dynamic>;
          return {
            'userId': d.id,
            'name': data['name'] ?? 'Unknown',
            'profilePic': data['profilePic'] ?? '',
            'id': data['id'] ?? '',
          };
        }));

      notifyListeners();
    });

    _blockedByOthersSubscription?.cancel();
    _blockedByOthersSubscription = _firestore
        .collectionGroup('blocked_users')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .listen((snapshot) {
      blockedByUserIds
        ..clear()
        ..addAll(snapshot.docs
            .map((d) => d.reference.parent.parent?.id)
            .whereType<String>());
      notifyListeners();
    }, onError: (e) => debugPrint('❌ blockedByOthers listener error: $e'));
  }

  void _cancelBlockListeners() {
    _blockedByMeSubscription?.cancel();
    _blockedByOthersSubscription?.cancel();
  }

  bool isBlockedSync(String otherUserId) =>
      blockedUserIds.contains(otherUserId) || blockedByUserIds.contains(otherUserId);

  Future<bool> isBlocked(String otherUserId) async {
    if (isBlockedSync(otherUserId)) return true;
    final a = await _blockedUsersRef.doc(otherUserId).get();
    if (a.exists) return true;
    final b = await _firestore
        .collection('users')
        .doc(otherUserId)
        .collection('blocked_users')
        .doc(uid)
        .get();
    return b.exists;
  }

// NEW: now also stores profilePic, so the Blocked Accounts screen has something to show
  Future<void> blockUser(String otherUserId,
      {String? name, String? id, String? profilePic}) async {
    await _blockedUsersRef.doc(otherUserId).set({
      'userId': otherUserId,
      'name': name,
      'id': id,
      'profilePic': profilePic,
      'blockedAt': FieldValue.serverTimestamp(),
    });
    blockedUserIds.add(otherUserId);
    notifyListeners();
  }

  Future<void> unblockUser(String otherUserId) async {
    await _blockedUsersRef.doc(otherUserId).delete();
    blockedUserIds.remove(otherUserId);
    blockedUsersDetails.removeWhere((u) => u['userId'] == otherUserId);
    notifyListeners();
  }

  List<MessageClass> get visibleDashboardMessageList => dashboardMessageList
      .where((m) => !isBlockedSync(m.otherUserId.toString()))
      .toList();


  Future<void> deleteConversation(String otherUserId) async {
    final conversationId = createConversationId(uid, otherUserId);
    try {
      await _userConversationsRef
          .doc(uid)
          .collection('conversations')
          .doc(conversationId)
          .delete();

      dashboardMessageList.removeWhere((m) => m.otherUserId == otherUserId);
      _loadedConversationIds.remove(conversationId);
      notifyListeners();

      debugPrint('✅ Conversation deleted (local copy): $conversationId');
    } catch (e) {
      debugPrint('❌ Error deleting conversation: $e');
      rethrow;
    }
  }


  // ═══════════════════════════════════════════════════════════════
  // CONVERSATION ID GENERATION
  // ═══════════════════════════════════════════════════════════════

  /// Creates a consistent conversation ID for two users
  String createConversationId(String userId1, String oduserId2) {
    final ids = [userId1, oduserId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }








  // ═══════════════════════════════════════════════════════════════
  // RECEIVER USER MANAGEMENT
  // ═══════════════════════════════════════════════════════════════

  Future<void> updateReceiverUser({required MessageClass newReceiverUser}) async {
    receiverUser = newReceiverUser;
    currentConversationId = createConversationId(uid, newReceiverUser.otherUserId!);
    _resetChatState();
    notifyListeners();
  }

  Future<void> updateCurrentUserName({required String newCurrentUserName}) async {
    currentUserName = newCurrentUserName;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // RESET STATE
  // ═══════════════════════════════════════════════════════════════

  void _resetChatState() {
    _messages.clear();
    _loadedMessageIds.clear();
    _oldestMessageDoc = null;
    _newestMessageDoc = null;
    hasMoreMessages = true;
    isLoadingMore = false;
    _isInitialLoadComplete = false;
  }

  // ═══════════════════════════════════════════════════════════════
  // ═══════════════════════════════════════════════════════════════
  //                    TYPING INDICATORS (RTDB)
  // ═══════════════════════════════════════════════════════════════
  // ═══════════════════════════════════════════════════════════════

  /// Update typing status in Realtime Database
  void updateTyping({
    required String otherUserId,
    required bool isTyping,
  }) {
    final conversationId = createConversationId(uid, otherUserId);

    _typingRef ??= _rtdb.child("Typing").child(conversationId).child(uid);

    _typingRef!.update({
      "isTyping": isTyping,
      "updatedAt": ServerValue.timestamp,
    });
  }

  /// Stop typing indicator
  void stopTyping(String otherUserId) {
    updateTyping(otherUserId: otherUserId, isTyping: false);


  }

  /// Stream of typing status for the other user
  Stream<bool> listenToTypingStatus(String otherUserId) {
    final conversationId = createConversationId(uid, otherUserId);

    return _rtdb
        .child("Typing")
        .child(conversationId)
        .child(otherUserId)
        .onValue
        .map((event) {
      final data = event.snapshot.value as Map?;

      if (data == null) return false;

      final bool isTyping = data['isTyping'] == true;
      final int updatedAt = (data['updatedAt'] is int) ? data['updatedAt'] : 0;

      // Check if typing status is fresh (within 3 seconds)
      final bool isFresh =
          DateTime.now().millisecondsSinceEpoch - updatedAt < 3000;

      return isTyping && isFresh;
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // ═══════════════════════════════════════════════════════════════
  //                    DASHBOARD (Conversation List)
  // ═══════════════════════════════════════════════════════════════
  // ═══════════════════════════════════════════════════════════════

  /// Load and listen to user's conversation list
  void getDashboardMessageData() {
    _cancelDashboardListener();
    dashboardMessageList.clear();
    _loadedConversationIds.clear();
    setLoader(true);

    debugPrint('📋 Loading dashboard conversations...');

    _dashboardSubscription = _userConversationsRef
        .doc(uid)
        .collection('conversations')
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .listen(
      _handleDashboardSnapshot,
      onError: (error) {
        debugPrint('❌ Dashboard error: $error');
        setLoader(false);
      },
    );
  }

  void _handleDashboardSnapshot(QuerySnapshot snapshot) {
    debugPrint('📋 Dashboard update: ${snapshot.docChanges.length} changes');

    for (var change in snapshot.docChanges) {
      final data = change.doc.data() as Map<String, dynamic>?;
      if (data == null) continue;

      final conversationId = change.doc.id;

      switch (change.type) {
        case DocumentChangeType.added:
          if (!_loadedConversationIds.contains(conversationId)) {
            final conversation = MessageClass.fromFirestoreDashboard(
              data,
              conversationId,
            );
            dashboardMessageList.add(conversation);
            _loadedConversationIds.add(conversationId);
            debugPrint('  ➕ Added: ${conversation.name}');
          }
          break;

        case DocumentChangeType.modified:
          final index = dashboardMessageList.indexWhere(
                (m) => m.otherUserId == data['otherUserId'],
          );
          if (index != -1) {
            dashboardMessageList[index] = MessageClass.fromFirestoreDashboard(
              data,
              conversationId,
            );
            debugPrint('  🔄 Modified: ${data['otherUserName']}');
          }
          break;

        case DocumentChangeType.removed:
          dashboardMessageList.removeWhere(
                (m) => m.otherUserId == data['otherUserId'],
          );
          _loadedConversationIds.remove(conversationId);
          debugPrint('  ➖ Removed: ${data['otherUserName']}');
          break;
      }
    }

    // Sort by newest first
    dashboardMessageList.sort(
          (a, b) => (b.timeStamp ?? 0).compareTo(a.timeStamp ?? 0),
    );

    setLoader(false);
    notifyListeners();
  }

  void _cancelDashboardListener() {
    _dashboardSubscription?.cancel();
    _dashboardSubscription = null;
  }

  // ═══════════════════════════════════════════════════════════════
  // ═══════════════════════════════════════════════════════════════
  //                    SEND MESSAGE
  // ═══════════════════════════════════════════════════════════════
  // ═══════════════════════════════════════════════════════════════

  /// Send a new message
  Future<void> sendMessage({
    required String msg,
    required String roomName,
    MessageClass? replyToMessage, // NEW: Optional reply
  }) async {
    if (receiverUser == null || currentConversationId == null) {
      debugPrint('❌ Cannot send: receiverUser or conversationId is null');
      return;
    }

    final message = msg.trim();
    if (message.isEmpty) {
      debugPrint('❌ Cannot send: message is empty');
      return;
    }

    final conversationId = currentConversationId!;
    final timestamp = FieldValue.serverTimestamp();

    debugPrint('📤 Sending message to $conversationId...');

    try {
      final batch = _firestore.batch();

      // Build message data
      final Map<String, dynamic> messageData = {
        'senderId': uid,
        'text': message,
        'timestamp': timestamp,
        'isRead': false,
        'roomName': roomName,
      };

      // Add reply fields if replying
      if (replyToMessage != null) {
        messageData['replyToMessageId'] = replyToMessage.messageId;
        messageData['replyToMessage'] = replyToMessage.message;
        messageData['replyToSenderId'] = replyToMessage.userId;
        messageData['replyToSenderName'] = replyToMessage.userId == uid
            ? 'You'
            : receiverUser!.name ?? 'User';
      }

      // 1. Add message to messages subcollection
      final messageRef = _conversationsRef
          .doc(conversationId)
          .collection('messages')
          .doc();

      batch.set(messageRef, messageData);

      // 2. Update/Create conversation document
      batch.set(
        _conversationsRef.doc(conversationId),
        {
          'participants': [uid, receiverUser!.otherUserId],
          'lastMessage': {
            'text': message,
            'senderId': uid,
            'timestamp': timestamp,
            'isRead': false,
          },
          'updatedAt': timestamp,
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // 3. Update sender's conversation list
      batch.set(
        _userConversationsRef
            .doc(uid)
            .collection('conversations')
            .doc(conversationId),
        {
          'otherUserName': receiverUser!.name ?? '',
          'lastMessage': message,
          'lastMessageTime': timestamp,
          'isRead': true,
          'unreadCount': 0,
        },
        SetOptions(merge: true),
      );

      // 4. Update receiver's conversation list
      batch.set(
        _userConversationsRef
            .doc(receiverUser!.otherUserId)
            .collection('conversations')
            .doc(conversationId),
        {
          'otherUserName': currentUserName,
          'lastMessage': message,
          'lastMessageTime': timestamp,
          'isRead': false,
          'unreadCount': FieldValue.increment(1),
        },
        SetOptions(merge: true),
      );

      await batch.commit();
      debugPrint('✅ Message sent successfully${replyToMessage != null ? ' (with reply)' : ''}');
    } catch (e) {
      debugPrint('❌ Error sending message: $e');
      rethrow;
    }
  }


  // ═══════════════════════════════════════════════════════════════
  // ═══════════════════════════════════════════════════════════════
  //                    GET ALL MESSAGES
  // ═══════════════════════════════════════════════════════════════
  // ═══════════════════════════════════════════════════════════════

  /// Initialize chat: load messages and setup listeners
  Future<void> getAllMessages() async {
    if (currentConversationId == null) {
      debugPrint('❌ Cannot get messages: conversationId is null');
      return;
    }

    debugPrint('📨 Initializing chat for: $currentConversationId');

    // Cancel existing listeners
    _cancelMessageListeners();
    _resetChatState();

    // Load initial batch of messages
    await _loadInitialMessages();

    // Setup real-time listener for new messages
    _setupNewMessageListener();

    // Setup read status listener
    _setupReadStatusListener();

    // Mark received messages as read
    await markMessagesAsRead();
  }

  // ═══════════════════════════════════════════════════════════════
  // INITIAL LOAD - Newest messages first
  // ═══════════════════════════════════════════════════════════════

  Future<void> _loadInitialMessages() async {
    if (currentConversationId == null) return;

    isLoadingMore = true;
    notifyListeners();

    debugPrint('📥 Loading initial messages...');

    try {
      final query = _conversationsRef
          .doc(currentConversationId)
          .collection('messages')
          .orderBy('timestamp', descending: true) // Newest first
          .limit(pageSize);

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        hasMoreMessages = false;
        _isInitialLoadComplete = true;
        debugPrint('📭 No messages found');
        return;
      }

      // Store cursors for pagination
      _newestMessageDoc = snapshot.docs.first; // Newest message
      _oldestMessageDoc = snapshot.docs.last;   // Oldest in this batch

      // Add messages to list
      for (var doc in snapshot.docs) {
        _addMessageFromDoc(doc);
      }

      // Sort messages (oldest first for display)
      _sortMessages();

      hasMoreMessages = snapshot.docs.length >= pageSize;
      _isInitialLoadComplete = true;

      debugPrint('✅ Loaded ${snapshot.docs.length} messages');
      debugPrint('   Newest: ${_newestMessageDoc?.id}');
      debugPrint('   Oldest: ${_oldestMessageDoc?.id}');
      debugPrint('   Has more: $hasMoreMessages');
    } catch (e) {
      debugPrint('❌ Error loading initial messages: $e');
    } finally {
      isLoadingMore = false;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // LOAD MORE - Older messages (scroll up)
  // ═══════════════════════════════════════════════════════════════

  Future<void> loadMoreMessages() async {
    // Guard conditions
    if (currentConversationId == null) {
      debugPrint('⚠️ Cannot load more: no conversation');
      return;
    }
    if (isLoadingMore) {
      debugPrint('⚠️ Already loading');
      return;
    }
    if (!hasMoreMessages) {
      debugPrint('⚠️ No more messages available');
      return;
    }
    if (_oldestMessageDoc == null) {
      debugPrint('⚠️ No cursor for pagination');
      return;
    }

    isLoadingMore = true;
    notifyListeners();

    debugPrint('📜 Loading older messages...');

    try {
      // Cursor-based pagination - reliable!
      final query = _conversationsRef
          .doc(currentConversationId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .startAfterDocument(_oldestMessageDoc!) // Start after oldest we have
          .limit(pageSize);

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        hasMoreMessages = false;
        debugPrint('📭 No more older messages');
        return;
      }

      // Update cursor to new oldest
      _oldestMessageDoc = snapshot.docs.last;

      // Add new messages
      for (var doc in snapshot.docs) {
        _addMessageFromDoc(doc);
      }

      // Re-sort all messages
      _sortMessages();

      hasMoreMessages = snapshot.docs.length >= pageSize;

      debugPrint('✅ Loaded ${snapshot.docs.length} older messages');
      debugPrint('   New oldest: ${_oldestMessageDoc?.id}');
      debugPrint('   Has more: $hasMoreMessages');
    } catch (e) {
      debugPrint('❌ Error loading more messages: $e');
    } finally {
      isLoadingMore = false;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // REAL-TIME LISTENER - New messages only
  // ═══════════════════════════════════════════════════════════════

  void _setupNewMessageListener() {
    if (currentConversationId == null) return;

    debugPrint('👂 Setting up new message listener...');

    _messagesSubscription = _conversationsRef
        .doc(currentConversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(5)
        .snapshots()
        .listen((snapshot) {
      bool needsNotify = false;

      for (var change in snapshot.docChanges) {
        final messageId = change.doc.id;
        final data = change.doc.data();

        if (data == null) continue;

        switch (change.type) {
          case DocumentChangeType.added:
            if (_loadedMessageIds.contains(messageId)) continue;

            final int messageTimestamp;
            if (data['timestamp'] == null) {
              messageTimestamp = DateTime.now().millisecondsSinceEpoch;
            } else if (data['timestamp'] is Timestamp) {
              messageTimestamp =
                  (data['timestamp'] as Timestamp).millisecondsSinceEpoch;
            } else {
              messageTimestamp = DateTime.now().millisecondsSinceEpoch;
            }

            // ✅ Create message with ALL fields including reply
            final message = MessageClass(
              messageId: messageId,
              userId: data['senderId'] ?? '',
              message: data['text'] ?? '',
              timeStamp: messageTimestamp,
              isRead: data['isRead'] ?? false,
              roomName: data['roomName'] ?? '',
              replyToMessageId: data['replyToMessageId'],
              replyToMessage: data['replyToMessage'],
              replyToSenderId: data['replyToSenderId'],
              replyToSenderName: data['replyToSenderName'],
            );

            _messages.add(message);
            _loadedMessageIds.add(messageId);

            if (_newestMessageDoc == null) {
              _newestMessageDoc = change.doc;
            }

            if (data['senderId'] != uid) {
              _markSingleMessageAsRead(messageId);
            }

            debugPrint('📩 New message added (isReply: ${message.isReply})');
            needsNotify = true;
            break;

          case DocumentChangeType.modified:
            final index = _messages.indexWhere((m) => m.messageId == messageId);

            if (index != -1) {
              bool messageUpdated = false;

              // Update timestamp
              if (data['timestamp'] != null && data['timestamp'] is Timestamp) {
                final newTimestamp =
                    (data['timestamp'] as Timestamp).millisecondsSinceEpoch;
                if (_messages[index].timeStamp != newTimestamp) {
                  _messages[index].timeStamp = newTimestamp;
                  messageUpdated = true;
                }
              }

              // Update read status
              final newIsRead = data['isRead'] ?? false;
              if (_messages[index].isRead != newIsRead) {
                _messages[index].isRead = newIsRead;
                messageUpdated = true;
              }

              // ✅ Update reply fields if they exist in data but not in message
              if (_messages[index].replyToMessageId == null &&
                  data['replyToMessageId'] != null) {
                _messages[index].replyToMessageId = data['replyToMessageId'];
                _messages[index].replyToMessage = data['replyToMessage'];
                _messages[index].replyToSenderId = data['replyToSenderId'];
                _messages[index].replyToSenderName = data['replyToSenderName'];
                messageUpdated = true;
              }

              if (messageUpdated) {
                needsNotify = true;
              }
            }
            break;

          case DocumentChangeType.removed:
            _messages.removeWhere((m) => m.messageId == messageId);
            _loadedMessageIds.remove(messageId);
            needsNotify = true;
            break;
        }
      }

      if (needsNotify) {
        _sortMessages();
        notifyListeners();
      }
    }, onError: (error) {
      debugPrint('❌ Message listener error: $error');
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // READ STATUS LISTENER
  // ═══════════════════════════════════════════════════════════════

  void _setupReadStatusListener() {
    if (currentConversationId == null) return;

    debugPrint('👂 Setting up read status listener...');

    // Listen for changes to messages I sent (for read receipts)
    _readStatusSubscription = _conversationsRef
        .doc(currentConversationId)
        .collection('messages')
        .where('senderId', isEqualTo: uid)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          _handleMessageModified(change.doc);
        }
      }
    }, onError: (error) {
      debugPrint('❌ Read status listener error: $error');
    });
  }

  void _handleMessageModified(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return;

    final messageId = doc.id;
    final isRead = data['isRead'] ?? false;

    // Find and update the message
    final index = _messages.indexWhere((m) => m.messageId == messageId);
    if (index != -1 && _messages[index].isRead != isRead) {
      _messages[index].isRead = isRead;
      debugPrint('✅ Read status updated: $messageId -> $isRead');
      notifyListeners();
    }
  }

  void _cancelMessageListeners() {
    _messagesSubscription?.cancel();
    _readStatusSubscription?.cancel();
    _messagesSubscription = null;
    _readStatusSubscription = null;
  }


  Future<void> setActiveChat(String? conversationId) async {
    if (uid == null) return;

    // Create a reference to the activeChats node for this user
    DatabaseReference presenceRef = _rtdb.child("activeChats/$uid");

    if (conversationId != null) {
      // 1. Schedule a 'delete' to happen when the user goes offline
      await presenceRef.onDisconnect().remove();

      // 2. Set the current status to active
      await presenceRef.set({
        'currentConversationId': conversationId,
        'timestamp': ServerValue.timestamp, // Use ServerValue for RTDB
      });
    } else {
      // Manually delete if they leave the chatroom through a UI button
      await presenceRef.remove(); // .remove() is the RTDB equivalent of .delete()
    }


  }

  // ═══════════════════════════════════════════════════════════════
  // ═══════════════════════════════════════════════════════════════
  //                    READ RECEIPTS
  // ═══════════════════════════════════════════════════════════════
  // ═══════════════════════════════════════════════════════════════

  /// Mark all received messages as read
  Future<void> markMessagesAsRead() async {
    if (currentConversationId == null || receiverUser == null) return;

    debugPrint('👁️ Marking messages as read...');

    try {
      // Get unread messages from the other user
      final snapshot = await _conversationsRef
          .doc(currentConversationId)
          .collection('messages')
          .where('senderId', isEqualTo: receiverUser!.otherUserId)
          .where('isRead', isEqualTo: false)
          .get();

      if (snapshot.docs.isEmpty) {
        debugPrint('   No unread messages');
        return;
      }

      final batch = _firestore.batch();

      // Mark each message as read
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      // Reset unread count in user's conversation list
      batch.update(
        _userConversationsRef
            .doc(uid)
            .collection('conversations')
            .doc(currentConversationId),
        {
          'isRead': true,
          'unreadCount': 0,
        },
      );

      await batch.commit();

      // Update local state
      for (var msg in _messages) {
        if (msg.userId != uid) {
          msg.isRead = true;
        }
      }
      notifyListeners();

      debugPrint('✅ Marked ${snapshot.docs.length} messages as read');
    } catch (e) {
      debugPrint('❌ Error marking messages as read: $e');
    }
  }

  /// Mark a single message as read
  Future<void> _markSingleMessageAsRead(String messageId) async {
    if (currentConversationId == null) return;

    try {
      await _conversationsRef
          .doc(currentConversationId)
          .collection('messages')
          .doc(messageId)
          .update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Marked message as read: $messageId');
    } catch (e) {
      debugPrint('❌ Error marking message as read: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ═══════════════════════════════════════════════════════════════
  //                    MESSAGE HELPERS
  // ═══════════════════════════════════════════════════════════════
  // ═══════════════════════════════════════════════════════════════

  /// Add message from Firestore document
  void _addMessageFromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return;

    final messageId = doc.id;

    // Skip duplicates
    if (_loadedMessageIds.contains(messageId)) return;

    final message = MessageClass.fromFirestoreMessage(data, messageId);
    _messages.add(message);
    _loadedMessageIds.add(messageId);
  }

  /// Sort messages by timestamp (oldest first for display)
  void _sortMessages() {
    _messages.sort((a, b) => (a.timeStamp ?? 0).compareTo(b.timeStamp ?? 0));
  }

  /// Get all messages sorted for display
  List<MessageClass> getAllMessagesSorted() {
    // Return a copy to prevent external modifications
    return List<MessageClass>.from(_messages);
  }

  // ═══════════════════════════════════════════════════════════════
  // ═══════════════════════════════════════════════════════════════
  //                    UTILITY METHODS
  // ═══════════════════════════════════════════════════════════════
  // ═══════════════════════════════════════════════════════════════

  void setLoader(bool value) {
    isLoader = value;
    notifyListeners();
  }

  void listenerController() {
    debugPrint('✓ Controller initialized');
    notifyListeners();
  }

  void disposeController() {
    _cancelMessageListeners();
    debugPrint('✓ Chat listeners disposed');
  }

  // ═══════════════════════════════════════════════════════════════
  // DATA CLEANUP
  // ═══════════════════════════════════════════════════════════════

  void clearDashboardData() {
    _cancelDashboardListener();
    dashboardMessageList.clear();
    _loadedConversationIds.clear();
    debugPrint('🗑️ Dashboard data cleared');
    notifyListeners();
  }

  void clearChatData() {
    _cancelMessageListeners();
    _resetChatState();
    receiverUser = null;
    currentConversationId = null;
    debugPrint('🗑️ Chat data cleared');
    notifyListeners();
  }

  void clearAllData() {
    _cancelDashboardListener();
    _cancelMessageListeners();

    dashboardMessageList.clear();
    _messages.clear();
    _loadedMessageIds.clear();
    _loadedConversationIds.clear();

    receiverUser = null;
    currentConversationId = null;
    _oldestMessageDoc = null;
    _newestMessageDoc = null;
    hasMoreMessages = true;
    isLoadingMore = false;
    _isInitialLoadComplete = false;

    debugPrint('🗑️ All data cleared');
    notifyListeners();
  }

  @override
  void dispose() {
    _cancelBlockListeners();   // add this line
    clearAllData();
    super.dispose();
  }
}