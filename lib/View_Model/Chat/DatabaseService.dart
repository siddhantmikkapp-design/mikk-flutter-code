import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:mikk/utils/LogHelper.dart';

import '../../Demo/MessageClass.dart';
import '../../Model/UserProfileModel.dart';
import '../../values/StaticText.dart';
import '../SettingsDetailViewModel/PersonalInformationViewModel.dart';




class DatabaseService extends ChangeNotifier {
  // ═══════════════════════════════════════════════════════════════
  // FIREBASE REFERENCES
  // ═══════════════════════════════════════════════════════════════
  final DatabaseReference baseRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: ConstantLabels.realTimeKey,
  ).ref();

  // ═══════════════════════════════════════════════════════════════
  // USER DATA
  // ═══════════════════════════════════════════════════════════════
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  final currentUser = FirebaseAuth.instance.currentUser;
  String currentUserName = "";
  String? avatarUrl;
  MessageClass? receiverUser;

  // ═══════════════════════════════════════════════════════════════
  // MESSAGE LISTS
  // ═══════════════════════════════════════════════════════════════
  List<MessageClass> dashboardMessageList = [];
  List<MessageClass> sendMessageList = [];
  List<MessageClass> receiverMessageList = [];

  // ═══════════════════════════════════════════════════════════════
  // PAGINATION
  // ═══════════════════════════════════════════════════════════════
  final int pageSize = 20;
  int? _newestLoadedTimestamp; // Most negative (newest)
  int? _oldestLoadedTimestamp; // Least negative (oldest)
  bool hasMoreMessages = true;
  bool isLoadingMore = false;
  bool _isInitialLoad = true;

  // ═══════════════════════════════════════════════════════════════
  // TRACKING SETS (Prevent Duplicates)
  // ═══════════════════════════════════════════════════════════════
  final Set<String> _loadedUserIds = {};
  final Set<String> _loadedMessageIds = {};

  // ═══════════════════════════════════════════════════════════════
  // STREAM SUBSCRIPTIONS (For Cleanup)
  // ═══════════════════════════════════════════════════════════════
  StreamSubscription<DatabaseEvent>? _messageListener;
  StreamSubscription<DatabaseEvent>? _newMessageListener;
  StreamSubscription<DatabaseEvent>? _readStatusListener; // ✅ NEW
  StreamSubscription<DatabaseEvent>? _dashboardAddedListener;
  StreamSubscription<DatabaseEvent>? _dashboardChangedListener;
  StreamSubscription<DatabaseEvent>? _dashboardRemovedListener;



  // TYPING INDICATORS

  DatabaseReference? _typingRef;

  bool _isTyping = false;

  // ═══════════════════════════════════════════════════════════════
  // LOADING STATE
  // ═══════════════════════════════════════════════════════════════
  bool isLoader = false;

  // ═══════════════════════════════════════════════════════════════
  // RECEIVER USER MANAGEMENT
  // ═══════════════════════════════════════════════════════════════
  Future<void> updateReceiverUser({required MessageClass newReceiverUser}) async {
    receiverUser = newReceiverUser;
    _resetPagination();
    notifyListeners();
  }

  Future<void> updateCurrentUserName({required String newCurrentUserName}) async {
    currentUserName = newCurrentUserName;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // PAGINATION RESET
  // ═══════════════════════════════════════════════════════════════
  void _resetPagination() {
    _newestLoadedTimestamp = null;
    _oldestLoadedTimestamp = null;
    hasMoreMessages = true;
    isLoadingMore = false;
    _isInitialLoad = true;
    _loadedMessageIds.clear();
    sendMessageList.clear();
    receiverMessageList.clear();
  }


  void updateTyping({
    required String otherUserId,
    required bool isTyping,
  }) {
    final roomId = createRoomId(uid, otherUserId);

    _typingRef ??= baseRef
        .child("Typing")
        .child(roomId)
        .child(uid);

    _typingRef!.update({
      "isTyping": isTyping,
      "updatedAt": ServerValue.timestamp,
    });

    _isTyping = isTyping;
  }

  void stopTyping(String otherUserId) {
    updateTyping(otherUserId: otherUserId, isTyping: false);
  }


  // ═══════════════════════════════════════════════════════════════
  // DASHBOARD MESSAGES
  // ═══════════════════════════════════════════════════════════════
  void getDashboardMessageData() {
    // ✅ Cancel existing listeners first
    _cancelDashboardListeners();

    DatabaseReference ref = baseRef.child('UserRooms').child(uid);
    Query query = ref.orderByChild('TimeStamp');

    // Clear existing data
    dashboardMessageList.clear();
    _loadedUserIds.clear();
    setLoader(true);

    LogHelper("=== Loading Dashboard Messages ===");

    // ✅ Store listener for cleanup
    _dashboardAddedListener = query.onChildAdded.listen(
          (event) => _handleDashboardChildAdded(event),
      onError: (error) {
        LogHelper("❌ Error in onChildAdded: $error");
        setLoader(false);
      },
    );

    _dashboardChangedListener = query.onChildChanged.listen(
          (event) => _handleDashboardChildChanged(event),
      onError: (error) => LogHelper("❌ Error in onChildChanged: $error"),
    );

    _dashboardRemovedListener = query.onChildRemoved.listen(
          (event) => _handleDashboardChildRemoved(event),
      onError: (error) => LogHelper("❌ Error in onChildRemoved: $error"),
    );
  }

  Future<void> _handleDashboardChildAdded(DatabaseEvent event) async {
    final value = event.snapshot.value;
    final odUserId = event.snapshot.key ?? '';

    if (_loadedUserIds.contains(odUserId)) {
      LogHelper("⚠️ Skipping duplicate user: $odUserId");
      return;
    }

    if (value == null) {
      setLoader(false);
      return;
    }

    try {
      final messageItem = MessageClass.fromJson(
        Map<String, dynamic>.from(value as Map),
      );
      messageItem.otherUserId = odUserId;

      LogHelper("📩 Loading chat with user: $odUserId");

      // Load profile picture
      final userProfile = await PersonalInformationViewModel()
          .getUserProfile(userId: odUserId);
      if (userProfile != null) {
        messageItem.profilePic = userProfile.profilePic;
      }

      // Add to list and tracking set
      _loadedUserIds.add(odUserId);
      dashboardMessageList.add(messageItem);

      // Sort by timestamp (most negative first = newest)
      dashboardMessageList.sort(
            (a, b) => (a.timeStamp ?? 0).compareTo(b.timeStamp ?? 0),
      );

      LogHelper("✓ Added to dashboard: ${messageItem.name} - Total: ${dashboardMessageList.length}");
      notifyListeners();
    } catch (e) {
      LogHelper("❌ Error parsing message for $odUserId: $e");
    } finally {
      setLoader(false);
    }
  }

  Future<void> _handleDashboardChildChanged(DatabaseEvent event) async {
    final value = event.snapshot.value;
    final odUserId = event.snapshot.key ?? '';

    LogHelper("🔄 Chat updated with user: $odUserId");

    if (value == null) return;

    try {
      final messageItem = MessageClass.fromJson(
        Map<String, dynamic>.from(value as Map),
      );
      messageItem.otherUserId = odUserId;

      // Load profile picture
      final userProfile = await PersonalInformationViewModel()
          .getUserProfile(userId: odUserId);
      if (userProfile != null) {
        messageItem.profilePic = userProfile.profilePic;
      }

      // Find and update existing item
      final index = dashboardMessageList.indexWhere(
            (item) => item.otherUserId == odUserId,
      );

      if (index != -1) {
        dashboardMessageList[index] = messageItem;

        // Re-sort by timestamp
        dashboardMessageList.sort(
              (a, b) => (a.timeStamp ?? 0).compareTo(b.timeStamp ?? 0),
        );

        LogHelper("✓ Updated dashboard item: ${messageItem.name}");
        notifyListeners();
      }
    } catch (e) {
      LogHelper("❌ Error updating message for $odUserId: $e");
    }
  }

  void _handleDashboardChildRemoved(DatabaseEvent event) {
    final odUserId = event.snapshot.key ?? '';

    dashboardMessageList.removeWhere((item) => item.otherUserId == odUserId);
    _loadedUserIds.remove(odUserId);

    LogHelper("🗑️ Removed from dashboard: $odUserId");
    notifyListeners();
  }

  void _cancelDashboardListeners() {
    _dashboardAddedListener?.cancel();
    _dashboardChangedListener?.cancel();
    _dashboardRemovedListener?.cancel();
    _dashboardAddedListener = null;
    _dashboardChangedListener = null;
    _dashboardRemovedListener = null;
  }

  // ═══════════════════════════════════════════════════════════════
  // SEND MESSAGE
  // ═══════════════════════════════════════════════════════════════
  Future<void> sendMessage({String msg = "", String roomName = ""}) async {
    if (receiverUser == null) {
      LogHelper("❌ Cannot send message: receiverUser is null");
      return;
    }

    final String message = msg.trim();
    if (message.isEmpty) {
      LogHelper("❌ Cannot send empty message");
      return;
    }

    final String roomId = createRoomId(uid, receiverUser!.otherUserId.toString());

    try {
      // Get server timestamp
      final DatabaseReference timestampRef = baseRef.child("TimeStamp").child(uid);
      await timestampRef.update({"TimeStamp": ServerValue.timestamp});

      final DatabaseEvent event = await timestampRef.once();
      final dynamic timeValue = event.snapshot.child("TimeStamp").value;

      if (timeValue is! int) {
        LogHelper("❌ Failed to get valid timestamp");
        return;
      }

      final int negativeTime = -1 * timeValue;

      // Message object
      final messageData = {
        "UserId": uid,
        "Message": message,
        "TimeStamp": negativeTime,
        "isRead": false,
        "RoomName": roomName

      };

      // Write to Messages
      final refMessages = baseRef.child("Messages").child(roomId);
      await refMessages.push().set(messageData);


      final Map<String, dynamic> roomUpdateForReceiver = {
        "TimeStamp": negativeTime,
        "isRead": false, // ✅ Unread for receiver
        "Message": message,
      };

      // Update UserRooms for both users
      final Map<String, dynamic> roomUpdateForSender = {
        "TimeStamp": negativeTime,
        "isRead": true,
        "Message": message,
      };

      await Future.wait([
        baseRef
            .child("UserRooms")
            .child(receiverUser!.otherUserId.toString())
            .child(uid)
            .update(roomUpdateForReceiver),
        baseRef
            .child("UserRooms")
            .child(uid)
            .child(receiverUser!.otherUserId.toString())
            .update(roomUpdateForSender),
      ]);

      LogHelper("✓ Message sent successfully");
    } catch (e) {
      LogHelper("❌ Error sending message: $e");
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ROOM ID GENERATION
  // ═══════════════════════════════════════════════════════════════
  String createRoomId(String userId1, String oduserId2) {
    final ids = [userId1, oduserId2]..sort();
    return "${ids[0]}_${ids[1]}";
  }

  // ═══════════════════════════════════════════════════════════════
  // GET ALL MESSAGES (Initial Load + Listener)
  // ═══════════════════════════════════════════════════════════════
  Future<void> getAllMessages() async {
    if (receiverUser == null) {
      LogHelper("❌ Cannot get messages: receiverUser is null");
      return;
    }

    final String roomId = createRoomId(uid, receiverUser!.otherUserId.toString());
    LogHelper("📨 Loading initial messages for room: $roomId");

    // Cancel existing listeners
    _cancelMessageListeners();
    _resetPagination();

    // Load initial messages
    await _loadInitialMessages(roomId);

    // Setup listener for new messages
    _setupNewMessageListener(roomId);
    _setupReadStatusListener(roomId); // ✅ Listen for read status changes

    // ✅ Mark received messages as read when opening chat
    await markMessagesAsRead();
  }

  Future<void> _loadInitialMessages(String roomId) async {
    isLoadingMore = true;
    notifyListeners();

    try {
      final ref = baseRef.child('Messages').child(roomId);
      final query = ref.orderByChild('TimeStamp').limitToFirst(pageSize);
      final event = await query.once();

      if (!event.snapshot.exists) {
        hasMoreMessages = false;
        LogHelper("📭 No messages found");
        return;
      }

      final List<MessageClass> newMessages = [];

      for (final child in event.snapshot.children) {
        final value = child.value;
        final messageId = child.key ?? '';

        if (_loadedMessageIds.contains(messageId) || value == null) continue;

        try {
          final message = MessageClass.fromJson(
            Map<String, dynamic>.from(value as Map),
          );
          message.messageId = messageId;
          newMessages.add(message);
          _loadedMessageIds.add(messageId);
        } catch (e) {
          LogHelper("❌ Error parsing message: $e");
        }
      }

      if (newMessages.isEmpty) {
        hasMoreMessages = false;
        return;
      }

      // Sort by timestamp (most negative first = newest first)
      newMessages.sort((a, b) => (a.timeStamp ?? 0).compareTo(b.timeStamp ?? 0));

      // Track boundaries
      _newestLoadedTimestamp = newMessages.first.timeStamp;
      _oldestLoadedTimestamp = newMessages.last.timeStamp;

      // Add to lists
      for (final message in newMessages) {
        if (message.userId == uid) {
          sendMessageList.add(message);
        } else {
          receiverMessageList.add(message);
        }
      }

      hasMoreMessages = newMessages.length >= pageSize;

      LogHelper("✓ Loaded ${newMessages.length} initial messages");
      LogHelper("  Newest timestamp: $_newestLoadedTimestamp");
      LogHelper("  Oldest timestamp: $_oldestLoadedTimestamp");
    } catch (e) {
      LogHelper("❌ Error loading messages: $e");
    } finally {
      isLoadingMore = false;
      _isInitialLoad = false;
      notifyListeners();
    }
  }

  void _setupNewMessageListener(String roomId) {
    final ref = baseRef.child('Messages').child(roomId);

    _newMessageListener = ref.onChildAdded.listen((event) {
      final value = event.snapshot.value;
      final messageId = event.snapshot.key ?? '';

      // Skip if already loaded
      if (_loadedMessageIds.contains(messageId) || value == null) return;

      try {
        final message = MessageClass.fromJson(
          Map<String, dynamic>.from(value as Map),
        );

        // Only add if it's newer than what we have
        final isNewer = _newestLoadedTimestamp == null ||
            (message.timeStamp ?? 0) < _newestLoadedTimestamp!;

        if (!isNewer) return;

        message.messageId = messageId;
        _loadedMessageIds.add(messageId);
        _newestLoadedTimestamp = message.timeStamp;

        if (message.userId == uid) {
          sendMessageList.add(message);
        } else {
          receiverMessageList.add(message);
          _markSingleMessageAsRead(roomId, messageId);
        }

        LogHelper("📩 New message: ${message.message}");
        notifyListeners();
      } catch (e) {
        LogHelper("❌ Error parsing new message: $e");
      }
    });
  }



  // ═══════════════════════════════════════════════════════════════
  // ✅ NEW: LISTEN FOR READ STATUS CHANGES
  // ═══════════════════════════════════════════════════════════════
  void _setupReadStatusListener(String roomId) {
    final ref = baseRef.child('Messages').child(roomId);

    _readStatusListener = ref.onChildChanged.listen((event) {
      final value = event.snapshot.value;
      final messageId = event.snapshot.key ?? '';

      if (value == null) return;

      try {
        final updatedData = Map<String, dynamic>.from(value as Map);
        final isRead = updatedData['isRead'] ?? false;
        final messageUserId = updatedData['UserId'] ?? '';

        // Only update if it's MY message (sent by me)
        if (messageUserId == uid) {
          // Find and update in sendMessageList
          final index = sendMessageList.indexWhere(
                (msg) => msg.messageId == messageId,
          );

          if (index != -1) {
            sendMessageList[index].isRead = isRead;
            LogHelper("✅ Read status updated for message: $messageId -> $isRead");
            notifyListeners();
          }
        }
      } catch (e) {
        LogHelper("❌ Error updating read status: $e");
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // ✅ NEW: MARK ALL RECEIVED MESSAGES AS READ
  // ═══════════════════════════════════════════════════════════════
  Future<void> markMessagesAsRead() async {
    if (receiverUser == null) return;

    final String roomId = createRoomId(uid, receiverUser!.otherUserId.toString());

    try {
      // Get all unread messages from the other user
      final ref = baseRef.child('Messages').child(roomId);
      final snapshot = await ref.get();

      if (!snapshot.exists) return;

      final Map<String, dynamic> updates = {};

      for (final child in snapshot.children) {
        final value = child.value;
        final messageId = child.key ?? '';

        if (value == null) continue;

        final messageData = Map<String, dynamic>.from(value as Map);
        final messageUserId = messageData['UserId'] ?? '';
        final isRead = messageData['isRead'] ?? false;

        // Mark as read if:
        // 1. It's NOT my message (it's from the other user)
        // 2. It's currently unread
        if (messageUserId != uid && !isRead) {
          updates['$messageId/isRead'] = true;
        }
      }

      if (updates.isNotEmpty) {
        await ref.update(updates);
        LogHelper("✅ Marked ${updates.length} messages as read");

        // Update local list
        for (var msg in receiverMessageList) {
          msg.isRead = true;
        }
        notifyListeners();
      }

      // Also update UserRooms to mark conversation as read
      await baseRef
          .child("UserRooms")
          .child(uid)
          .child(receiverUser!.otherUserId.toString())
          .update({"isRead": true});

    } catch (e) {
      LogHelper("❌ Error marking messages as read: $e");
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ✅ NEW: MARK SINGLE MESSAGE AS READ
  // ═══════════════════════════════════════════════════════════════
  Future<void> _markSingleMessageAsRead(String roomId, String messageId) async {
    try {
      await baseRef
          .child('Messages')
          .child(roomId)
          .child(messageId)
          .update({"isRead": true});

      LogHelper("✅ Marked message $messageId as read");
    } catch (e) {
      LogHelper("❌ Error marking single message as read: $e");
    }
  }









  void _cancelMessageListeners() {
    _messageListener?.cancel();
    _newMessageListener?.cancel();
    _readStatusListener?.cancel();
    _messageListener = null;
    _newMessageListener = null;
    _readStatusListener = null;
  }

  // ═══════════════════════════════════════════════════════════════
  // LOAD MORE MESSAGES (Pagination)
  // ═══════════════════════════════════════════════════════════════
  Future<void> loadMoreMessages() async {
    if (receiverUser == null) {
      LogHelper("⚠️ Cannot load more: receiverUser is null");
      return;
    }

    if (isLoadingMore) {
      LogHelper("⚠️ Already loading more messages");
      return;
    }

    if (!hasMoreMessages) {
      LogHelper("⚠️ No more messages to load");
      return;
    }

    if (_oldestLoadedTimestamp == null) {
      LogHelper("⚠️ No oldest timestamp to paginate from");
      return;
    }

    final String roomId = createRoomId(uid, receiverUser!.otherUserId.toString());
    LogHelper("📜 Loading older messages from timestamp: $_oldestLoadedTimestamp");

    isLoadingMore = true;
    notifyListeners();

    try {
      final ref = baseRef.child('Messages').child(roomId);
      final query = ref
          .orderByChild('TimeStamp')
          .startAfter(_oldestLoadedTimestamp)
          .limitToFirst(pageSize);

      final event = await query.once();

      if (!event.snapshot.exists) {
        hasMoreMessages = false;
        LogHelper("📭 No more older messages");
        return;
      }

      final List<MessageClass> olderMessages = [];

      for (final child in event.snapshot.children) {
        final value = child.value;
        final messageId = child.key ?? '';

        if (_loadedMessageIds.contains(messageId) || value == null) continue;

        try {
          final message = MessageClass.fromJson(
            Map<String, dynamic>.from(value as Map),
          );
          message.messageId = messageId;
          olderMessages.add(message);
          _loadedMessageIds.add(messageId);
        } catch (e) {
          LogHelper("❌ Error parsing message: $e");
        }
      }

      if (olderMessages.isEmpty) {
        hasMoreMessages = false;
        LogHelper("📭 No more older messages");
        return;
      }

      // Sort by timestamp
      olderMessages.sort((a, b) => (a.timeStamp ?? 0).compareTo(b.timeStamp ?? 0));

      // Update oldest boundary
      _oldestLoadedTimestamp = olderMessages.last.timeStamp;

      // Add to lists
      for (final message in olderMessages) {
        if (message.userId == uid) {
          sendMessageList.add(message);
        } else {
          receiverMessageList.add(message);
        }
      }

      hasMoreMessages = olderMessages.length >= pageSize;

      LogHelper("✓ Loaded ${olderMessages.length} older messages");
      LogHelper("  New oldest timestamp: $_oldestLoadedTimestamp");
    } catch (e) {
      LogHelper("❌ Error loading more messages: $e");
    } finally {
      isLoadingMore = false;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // GET ALL MESSAGES SORTED
  // ═══════════════════════════════════════════════════════════════
  List<MessageClass> getAllMessagesSorted() {
    final allMessages = <MessageClass>[
      ...receiverMessageList,
      ...sendMessageList,
    ];

    // Sort ascending by timestamp (most negative first = newest first)
    allMessages.sort((a, b) => (a.timeStamp ?? 0).compareTo(b.timeStamp ?? 0));

    return allMessages;
  }






  // ═══════════════════════════════════════════════════════════════
  // LOADER STATE
  // ═══════════════════════════════════════════════════════════════
  void setLoader(bool value) {
    isLoader = value;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // CONTROLLER MANAGEMENT
  // ═══════════════════════════════════════════════════════════════
  void disposeController() {
    _cancelMessageListeners();
    LogHelper("✓ Database listeners disposed");
  }

  void listenerController() {
    LogHelper("✓ Controller initialized");
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // DATA CLEANUP
  // ═══════════════════════════════════════════════════════════════
  void clearDashboardData() {
    _cancelDashboardListeners();
    dashboardMessageList.clear();
    _loadedUserIds.clear();
    LogHelper("🗑️ Dashboard data cleared");
    notifyListeners();
  }

  void clearChatData() {
    _cancelMessageListeners();
    sendMessageList.clear();
    receiverMessageList.clear();
    _loadedMessageIds.clear();
    _resetPagination();
    LogHelper("🗑️ Chat data cleared");
    notifyListeners();
  }

  void clearAllData() {
    _cancelDashboardListeners();
    _cancelMessageListeners();

    dashboardMessageList.clear();
    sendMessageList.clear();
    receiverMessageList.clear();
    _loadedUserIds.clear();
    _loadedMessageIds.clear();

    receiverUser = null;
    _newestLoadedTimestamp = null;
    _oldestLoadedTimestamp = null;
    hasMoreMessages = true;
    isLoadingMore = false;
    _isInitialLoad = true;

    LogHelper("🗑️ All data cleared");
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // DISPOSE
  // ═══════════════════════════════════════════════════════════════
  @override
  void dispose() {
    _cancelDashboardListeners();
    _cancelMessageListeners();
    LogHelper("🗑️ DatabaseService disposed");
    super.dispose();
  }
}




/*class DatabaseService extends ChangeNotifier {
  final DatabaseReference baseRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: ConstantLabels.realTimeKey,
  ).ref();

  String? avatarUrl;
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  final currentUser = FirebaseAuth.instance.currentUser;
  String currentUserName = "";

  // final String receiverUserId = "faWRyhNSvSSQAZsvJzVw255mEzx1";

  // final String receiverUserId = "yfhtwMETF1MYeNNJxggJ10NlcZe2";
  final TextEditingController _controller = TextEditingController(text: "Kuch Bhi");

  List<MessageClass> dashboardMessageList = [];
  List<MessageClass> sendMessageList = [];
  List<MessageClass> receiverMessageList = [];
  final ScrollController scrollController = ScrollController();
  MessageClass? receiverUser;
  final int pageSize = 10;
  int? lastTimeStamp;
  bool hasMore = true;
  bool isLoadingMore = false;

  bool isLoader = false;


  Future<void> updateReceiverUser({required MessageClass newReceiverUser}) async {
    receiverUser = newReceiverUser;
    notifyListeners();
  }
  Future<void> updateCurrentUserName({required String newCurrentUserName}) async {
    currentUserName = newCurrentUserName;
    notifyListeners();
  }

  Future<void> sendMessage({String msg = ""}) async {
    final String senderRoom = receiverUser!.otherUserId.toString() + uid;
    /// final String senderRoom = receiverUser != null ? (receiverUser.otherUserId.toString() + uid) : "$receiverUserId$uid";
    // final String senderRoom = "$receiverUserId$uid";
    final String message = msg.isNotEmpty ? msg.trim() : _controller.text.trim();

    if (message.isEmpty) return;

    final DatabaseReference timestampRef = baseRef.child("TimeStamp").child(uid);

    await timestampRef.update({
      "TimeStamp": ServerValue.timestamp,
    });

    timestampRef.once().then((DatabaseEvent event) async {
      final DataSnapshot snapshot = event.snapshot;
      final dynamic timeValue = snapshot.child("TimeStamp").value;

      if (timeValue is int) {
        final int negativeTime = -1 * timeValue;

        // MessageClass messageObj = MessageClass(
        //   name: receiverUser!.name.toString(),
        //   timeStamp: negativeTime,
        //   isRead: false,
        //   message: message,
        //   otherUserId: receiverUser!.otherUserId
        // );

        // String currentUserName = await SessionManager.getStringData(SessionManager.FULL_NAME);

        final Map<String, dynamic> messageObj = {
          "TimeStamp": negativeTime,
          "isRead": false,
          "Message": message,
        };

        // LogHelper("currentUserName $currentUserName");
        // MessageClass receiverMessageObj = MessageClass(
        //   name: (sendMessageList.isEmpty || receiverMessageList.isEmpty) ?  currentUserName : null,
        //   timeStamp: negativeTime,
        //   isRead: false,
        //   message: message,
        //   otherUserId: uid
        // );

        final vp = MessageClass(userId: uid, message: message, timeStamp: negativeTime).toJson();

        final refMessage = baseRef.child("SenderMessage").child(senderRoom);
        final refMessage2 = baseRef.child("ReceiverMessage").child(senderRoom);
        final refUserRoomReceiver = baseRef.child("UserRooms").child(receiverUser!.otherUserId.toString()).child(uid);
        final refUserRoomSender = baseRef.child("UserRooms").child(uid).child(receiverUser!.otherUserId.toString());

        await refMessage.push().set(vp);
        await refMessage2.push().set(vp);

        await refUserRoomReceiver.update(messageObj);
        await refUserRoomSender.update(messageObj);
      } else {
        LogHelper("Failed to get valid timestamp.");
      }
    }).catchError((error) {
      LogHelper("Error reading timestamp: $error");
    });
  }

  void getDashboardMessageData() {
    DatabaseReference ref = baseRef.child('UserRooms').child(uid);
    Query query = ref.orderByChild('TimeStamp');

    query.onValue.listen((event) async {
      dashboardMessageList.clear();
      for (DataSnapshot child in event.snapshot.children) {
        final value = child.value;
        if (value != null) {
          final michItem = MessageClass.fromJson(Map<String, dynamic>.from(value as Map));
          UserProfileModel? userProfile = await PersonalInformationViewModel().getUserProfile(userId: michItem.otherUserId.toString());
          if(userProfile != null) {
            michItem.profilePic = userProfile.profilePic;
            notifyListeners();
          }

          LogHelper("michItem ${jsonEncode(michItem)}");
          dashboardMessageList.add(michItem);
        }
      }
      setLoader(false);
    }, onError: (error) {
      setLoader(false);
    });
  }

  void scrollListener() {
    if (scrollController.position.pixels == scrollController.position.maxScrollExtent
        && hasMore && !isLoadingMore) {
      loadMore();
    }
  }

  void loadMore() async {
    LogHelper("loadMore ${receiverUser == null}");
    final String senderRoom = receiverUser!.otherUserId.toString() + uid;
    if (!hasMore || isLoadingMore || lastTimeStamp == null) return;
    setLoader(true);
    // setState(() => isLoadingMore = true);

    DatabaseReference ref = baseRef.child('SenderMessage').child(senderRoom);
    Query query = ref.orderByChild("TimeStamp").startAt(lastTimeStamp).limitToFirst(pageSize + 1);

    try {
      DatabaseEvent event = await query.once();
      List<MessageClass> newItems = [];
      bool skipFirst = true;

      for (DataSnapshot child in event.snapshot.children) {
        if (skipFirst) {
          skipFirst = false;
          continue;
        }
        final value = child.value;
        if (value != null) {
          final michItem = MessageClass.fromJson(Map<String, dynamic>.from(value as Map));
          newItems.add(michItem);
        }
      }

      if (newItems.isNotEmpty) {
        sendMessageList.addAll(newItems);
        lastTimeStamp = newItems.last.timeStamp;
        hasMore = newItems.length >= pageSize;
      } else {
        hasMore = false;
      }
    } catch (error) {
      print("Error loading more: $error");
    }

    setLoader(false);
  }

  void getOwnData() {
    // final String senderRoom = "$receiverUserId$uid";
    final String senderRoom = receiverUser!.otherUserId.toString() + uid;

    /// final String receiverRoom = "$uid$receiverUserId";
    bool isSender = true;
    DatabaseReference ref = baseRef.child(isSender ? 'SenderMessage' : "ReceiverMessage").child(senderRoom);
    Query query = ref.orderByChild("TimeStamp").limitToFirst(pageSize);

    query.onValue.listen((event) {
      sendMessageList.clear();
      for (DataSnapshot child in event.snapshot.children) {
        final value = child.value;
        if (value != null) {
          final michItem = MessageClass.fromJson(Map<String, dynamic>.from(value as Map));
          sendMessageList.add(michItem);
        }
      }

      // Update pagination markers
      if (sendMessageList.isNotEmpty) {
        lastTimeStamp = sendMessageList.last.timeStamp;
        hasMore = sendMessageList.length >= pageSize;
      } else {
        hasMore = false;
      }

      setLoader(false);
    }, onError: (error) {
      setLoader(false);
    });
  }


  void getReceiverData({required MessageClass receiverUser}) {
    // final String senderRoom = "$receiverUserId$uid";
    final String senderRoom = receiverUser!.otherUserId.toString() + uid;

    final String receiverRoom = uid + receiverUser!.otherUserId.toString();
    DatabaseReference ref = baseRef.child("ReceiverMessage").child(receiverRoom);
    Query query = ref.orderByChild("TimeStamp").limitToFirst(pageSize);

    query.onValue.listen((event) {
      receiverMessageList.clear();
      for (DataSnapshot child in event.snapshot.children) {
        final value = child.value;
        if (value != null) {
          final michItem = MessageClass.fromJson(Map<String, dynamic>.from(value as Map));
          receiverMessageList.add(michItem);
        }
      }
      notifyListeners();
      // Update pagination markers
      if (receiverMessageList.isNotEmpty) {
        lastTimeStamp = receiverMessageList.last.timeStamp;
        hasMore = receiverMessageList.length >= pageSize;
      } else {
        hasMore = false;
      }

      LogHelper("receiverMessageList ${receiverMessageList.length}");
      setLoader(false);
    }, onError: (error) {
      setLoader(false);
    });
  }



  setLoader(bool value) {
    isLoader = value;
    notifyListeners();
  }

  disposeController() {
    scrollController.dispose();
    notifyListeners();
  }

  listenerController() {
    scrollController.addListener(scrollListener);
    LogHelper("listenerController");
    notifyListeners();
  }



  void getOwnData() {
    if (receiverUser == null) {
      LogHelper("❌ Cannot get own data: receiverUser is null");
      return;
    }

    final String senderRoom = receiverUser!.otherUserId.toString() + uid;

    LogHelper("📨 Loading own messages for room: $senderRoom");

    bool isSender = true;
    DatabaseReference ref = baseRef.child(isSender ? 'SenderMessage' : "ReceiverMessage")
        .child(senderRoom);
    Query query = ref.orderByChild("TimeStamp").limitToFirst(pageSize);

    query.onValue.listen((event) {
      sendMessageList.clear();
      for (DataSnapshot child in event.snapshot.children) {
        final value = child.value;
        if (value != null) {
          final michItem = MessageClass.fromJson(Map<String, dynamic>.from(value as Map));
          sendMessageList.add(michItem);
        }
      }

      if (sendMessageList.isNotEmpty) {
        lastTimeStamp = sendMessageList.last.timeStamp;
        hasMore = sendMessageList.length >= pageSize;
      } else {
        hasMore = false;
      }

      LogHelper("✓ Loaded ${sendMessageList.length} own messages");
      setLoader(false);
      notifyListeners();
    }, onError: (error) {
      LogHelper("❌ Error loading own data: $error");
      setLoader(false);
    });
  }

  void getReceiverData({required MessageClass receiverUser}) {
    if (receiverUser.otherUserId == null) {
      LogHelper("❌ Cannot get receiver data: otherUserId is null");
      return;
    }

    final String senderRoom = receiverUser.otherUserId.toString() + uid;
    final String receiverRoom = uid + receiverUser.otherUserId.toString();

    LogHelper("📨 Loading receiver messages for room: $receiverRoom");

    DatabaseReference ref = baseRef.child("ReceiverMessage").child(receiverRoom);
    Query query = ref.orderByChild("TimeStamp").limitToFirst(pageSize);

    query.onValue.listen((event) {
      receiverMessageList.clear();
      for (DataSnapshot child in event.snapshot.children) {
        final value = child.value;
        if (value != null) {
          final michItem = MessageClass.fromJson(Map<String, dynamic>.from(value as Map));
          receiverMessageList.add(michItem);
        }
      }

      if (receiverMessageList.isNotEmpty) {
        lastTimeStamp = receiverMessageList.last.timeStamp;
        hasMore = receiverMessageList.length >= pageSize;
      } else {
        hasMore = false;
      }

      LogHelper("✓ Loaded ${receiverMessageList.length} receiver messages");
      setLoader(false);
      notifyListeners();
    }, onError: (error) {
      LogHelper("❌ Error loading receiver data: $error");
      setLoader(false);
    });
  }




 */



