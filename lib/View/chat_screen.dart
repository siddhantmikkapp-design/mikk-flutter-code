// import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mikk/ActiveChatTracker.dart';

import 'package:mikk/values/Color.dart';
import 'package:provider/provider.dart';

import '../Demo/MessageClass.dart';
// import '../GlobalUnityController.dart.dart';
import '../Demo/avatar_manager.dart';
import '../GlobalUnityController.dart';
import '../Model/UserProfileModel.dart';
import '../View_Model/Chat/DatabaseService.dart';
import '../View_Model/Chat/FirestoreChatService.dart';
import '../View_Model/SettingsDetailViewModel/PersonalInformationViewModel.dart';
import '../utils/LogHelper.dart';

import 'package:flutter/material.dart';

import 'package:mikk/values/Color.dart';
import 'package:provider/provider.dart';

import '../Demo/MessageClass.dart';
import '../View_Model/Chat/DatabaseService.dart';





import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class ChatScreen extends StatefulWidget {
  final MessageClass receiverUser;
  final String roomName;
  final String profilePicUrl;
  final String name;

  const ChatScreen({
    Key? key,
    required this.receiverUser,
    required this.roomName,
    required this.profilePicUrl,
    required this.name,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ChatState();
}

class _ChatState extends State<ChatScreen> {
  // ═══════════════════════════════════════════════════════════════
  // CONSTANTS
  // ═══════════════════════════════════════════════════════════════
  static const double _appBarHeight = 60.0;
  static const Color _darkBackground = Color(0xFF1A1A1A);
  static const Color _appBarColor = Color(0xFF1E1E1E);

  // ═══════════════════════════════════════════════════════════════
  // CONTROLLERS
  // ═══════════════════════════════════════════════════════════════
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // ═══════════════════════════════════════════════════════════════
  // STATE
  // ═══════════════════════════════════════════════════════════════
  bool _isExiting = false;
  bool _isSending = false;

  // ═══════════════════════════════════════════════════════════════
  // REPLY STATE
  // ═══════════════════════════════════════════════════════════════
  MessageClass? _replyToMessage;

  // ═══════════════════════════════════════════════════════════════
  // TIMERS & SUBSCRIPTIONS
  // ═══════════════════════════════════════════════════════════════
  Timer? _typingDebounce;
  StreamSubscription<bool>? _typingListener;
  final ValueNotifier<bool> _isReceiverTyping = ValueNotifier(false);

  // ═══════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ═══════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    ActiveChatTracker.activeRoomId = widget.roomName;
    _initData();

    final db = Provider.of<FirestoreChatService>(context, listen: false);

    _typingListener = db
        .listenToTypingStatus(widget.receiverUser.otherUserId.toString())
        .listen((isTyping) {
      _isReceiverTyping.value = isTyping;
    });

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        final db = Provider.of<FirestoreChatService>(context, listen: false);
        db.stopTyping(widget.receiverUser.otherUserId.toString());
      }
    });
  }

  void _initData() {
    final db = Provider.of<FirestoreChatService>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await db.updateReceiverUser(newReceiverUser: widget.receiverUser);
      db.listenerController();
      db.getAllMessages();
      db.setActiveChat(widget.roomName);
    });
  }

  @override
  void dispose() {
    ActiveChatTracker.activeRoomId = null;
    final db = Provider.of<FirestoreChatService>(context, listen: false);
    db.stopTyping(widget.receiverUser.otherUserId.toString());
    _typingListener?.cancel();
    _typingDebounce?.cancel();
    _isReceiverTyping.dispose();
    db.disposeController();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  // REPLY METHODS
  // ═══════════════════════════════════════════════════════════════

  void _setReplyTo(MessageClass message) {
    setState(() {
      _replyToMessage = message;
    });
    _focusNode.requestFocus();
  }

  void _clearReply() {
    setState(() {
      _replyToMessage = null;
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // SEND MESSAGE
  // ═══════════════════════════════════════════════════════════════

  void _sendMessage() async {
    final db = Provider.of<FirestoreChatService>(context, listen: false);
    db.stopTyping(widget.receiverUser.otherUserId.toString());

    final message = _controller.text.trim();
    if (_isSending || message.isEmpty) return;

    setState(() => _isSending = true);

    try {
      _controller.clear();

      await db.sendMessage(
        msg: message,
        roomName: widget.roomName,
        replyToMessage: _replyToMessage,
      );

      _clearReply();

      if (!_focusNode.hasFocus) {
        _focusNode.requestFocus();
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _handleBackPressed() async {
    final db = Provider.of<FirestoreChatService>(context, listen: false);
    db.setActiveChat(null);

    if (_isExiting) return;
    setState(() => _isExiting = true);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBackPressed();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: _darkBackground,
        body: Column(
          children: [
            _buildChatModeAppBar(topPadding),
            Expanded(
              child: _ChatModeMessages(
                onReply: _setReplyTo,
                receiverName: widget.name,
              ),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // APP BAR
  // ═══════════════════════════════════════════════════════════════

  Widget _buildChatModeAppBar(double topPadding) {
    return Container(
      padding: EdgeInsets.only(top: topPadding),
      decoration: const BoxDecoration(
        color: _appBarColor,
        boxShadow: [
          BoxShadow(
            color: Color(0x4D000000),
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: SizedBox(
        height: _appBarHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                onPressed: _handleBackPressed,
                padding: const EdgeInsets.all(8),
              ),
              _buildProfilePicture(),
              const SizedBox(width: 12),
              Expanded(
                child: ValueListenableBuilder<bool>(
                  valueListenable: _isReceiverTyping,
                  builder: (_, isTyping, __) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isTyping)
                          Text(
                            "typing…",
                            style: TextStyle(color: primaryColor2, fontSize: 12),
                          ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePicture() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 40,
        width: 40,
        child: widget.profilePicUrl.isNotEmpty
            ? CachedNetworkImage(
          imageUrl: widget.profilePicUrl,
          placeholder: (context, url) => const _ProfilePlaceholder(),
          fit: BoxFit.cover,
          errorWidget: (context, url, error) => const _DefaultAvatar(),
        )
            : const _DefaultAvatar(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // INPUT AREA
  // ═══════════════════════════════════════════════════════════════

  Widget _buildInputArea() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_replyToMessage != null) _buildReplyPreview(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: const BorderSide(color: Colors.grey, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide(color: primaryColor2, width: 2),
                    ),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  onChanged: (text) {
                    final db = Provider.of<FirestoreChatService>(context, listen: false);
                    _typingDebounce?.cancel();

                    if (text.isNotEmpty) {
                      _typingDebounce = Timer(const Duration(milliseconds: 300), () {
                        db.updateTyping(
                          otherUserId: widget.receiverUser.otherUserId.toString(),
                          isTyping: true,
                        );
                      });
                    } else {
                      db.stopTyping(widget.receiverUser.otherUserId.toString());
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.send, color: _isSending ? Colors.grey : primaryColor2),
                onPressed: _isSending ? null : _sendMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReplyPreview() {
    final db = Provider.of<FirestoreChatService>(context, listen: false);
    final isMyMessage = _replyToMessage!.userId == db.uid;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: isMyMessage ? primaryColor2 : primaryColor1,
            width: 4,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isMyMessage ? 'You' : widget.name,
                  style: TextStyle(
                    color: isMyMessage ? primaryColor2 : primaryColor1,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _replyToMessage!.message ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _clearReply,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white54,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════

class _ProfilePlaceholder extends StatelessWidget {
  const _ProfilePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF2A2A2A),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      ),
    );
  }
}

class _DefaultAvatar extends StatelessWidget {
  const _DefaultAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF2A2A2A),
      child: const Icon(Icons.person, size: 22, color: Colors.white30),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CHAT MODE MESSAGES
// ═══════════════════════════════════════════════════════════════

class _ChatModeMessages extends StatefulWidget {
  final Function(MessageClass)? onReply;
  final String receiverName;

  const _ChatModeMessages({
    this.onReply,
    required this.receiverName,
  });

  @override
  State<_ChatModeMessages> createState() => _ChatModeMessagesState();
}

class _ChatModeMessagesState extends State<_ChatModeMessages>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  bool _shouldAutoScroll = true;
  double? _previousMaxExtent;
  bool _isFirstLoad = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }


  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (_shouldAutoScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToBottom(animate: false);
      });
    }
  }


  void _onScroll() {
    if (!mounted) return;

    final db = Provider.of<FirestoreChatService>(context, listen: false);

    if (_scrollController.position.pixels <= 100 &&
        !db.isLoadingMore &&
        db.hasMoreMessages) {
      _loadMoreOlderMessages();
    }

    final isNearBottom = _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 150;

    if (isNearBottom != _shouldAutoScroll) {
      _shouldAutoScroll = isNearBottom;
    }
  }

  void _loadMoreOlderMessages() {
    final db = Provider.of<FirestoreChatService>(context, listen: false);

    _previousMaxExtent = _scrollController.position.maxScrollExtent;
    final currentOffset = _scrollController.offset;

    db.loadMoreMessages().then((_) {
      if (!mounted) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;

        if (_previousMaxExtent != null) {
          final newMaxExtent = _scrollController.position.maxScrollExtent;
          final addedHeight = newMaxExtent - _previousMaxExtent!;

          if (addedHeight > 0) {
            _scrollController.jumpTo(currentOffset + addedHeight);
          }
        }
      });
    });
  }

  void _scrollToBottom({bool animate = true}) {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;

    if (animate && !_isFirstLoad) {
      _scrollController.animateTo(
        maxScroll,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(maxScroll);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Consumer<FirestoreChatService>(
      builder: (context, db, child) {
        final allMessages = db.getAllMessagesSorted();

        if (allMessages.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || !_scrollController.hasClients) return;

            if (_isFirstLoad) {
              _scrollController.jumpTo(_scrollController.position.maxScrollExtent);

              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted && _scrollController.hasClients) {
                  _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                  _isFirstLoad = false;
                }
              });
            } else if (_shouldAutoScroll) {
              _scrollToBottom(animate: true);
            }
          });
        }

        if (allMessages.isEmpty) {
          return Center(
            child: db.isLoadingMore
                ? CircularProgressIndicator(color: primaryColor2)
                : const Text(
              "No messages yet.\nSay hello! 👋",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        return Column(
          children: [
            if (db.isLoadingMore)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor2),
                ),
              ),

            if (db.hasMoreMessages &&
                !db.isLoadingMore &&
                allMessages.length >= FirestoreChatService.pageSize)
              GestureDetector(
                onTap: _loadMoreOlderMessages,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    "↑ Scroll up for older messages",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              ),

            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                itemCount: allMessages.length,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemBuilder: (context, index) {
                  final msg = allMessages[index];
                  final isMe = msg.userId == db.uid;

                  bool showDateSeparator = false;
                  if (index == 0) {
                    showDateSeparator = true;
                  } else {
                    final prevMsg = allMessages[index - 1];
                    showDateSeparator = !_isSameDay(
                      msg.timeStamp ?? 0,
                      prevMsg.timeStamp ?? 0,
                    );
                  }

                  return Column(
                    children: [
                      if (showDateSeparator)
                        _DateSeparator(timestamp: msg.timeStamp ?? 0),
                      _SwipeableChatBubble(
                        message: msg,
                        isMe: isMe,
                        onReply: widget.onReply,
                        receiverName: widget.receiverName,
                        key: ValueKey('msg_${msg.messageId ?? msg.timeStamp}'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  bool _isSameDay(int timestamp1, int timestamp2) {
    if (timestamp1 == 0 || timestamp2 == 0) return false;
    final date1 = DateTime.fromMillisecondsSinceEpoch(timestamp1);
    final date2 = DateTime.fromMillisecondsSinceEpoch(timestamp2);
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}

// ═══════════════════════════════════════════════════════════════
// DATE SEPARATOR
// ═══════════════════════════════════════════════════════════════

class _DateSeparator extends StatelessWidget {
  final int timestamp;

  const _DateSeparator({required this.timestamp});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);

    String dateText;
    if (difference.inDays == 0) {
      dateText = "Today";
    } else if (difference.inDays == 1) {
      dateText = "Yesterday";
    } else if (difference.inDays < 7) {
      dateText = DateFormat('EEEE').format(date);
    } else {
      dateText = DateFormat('MMM dd, yyyy').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Colors.grey)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              dateText,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Expanded(child: Divider(color: Colors.grey)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SWIPEABLE CHAT BUBBLE
// ═══════════════════════════════════════════════════════════════

class _SwipeableChatBubble extends StatefulWidget {
  final MessageClass message;
  final bool isMe;
  final Function(MessageClass)? onReply;
  final String receiverName;

  const _SwipeableChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onReply,
    required this.receiverName,
  });

  @override
  State<_SwipeableChatBubble> createState() => _SwipeableChatBubbleState();
}

class _SwipeableChatBubbleState extends State<_SwipeableChatBubble> {
  double _dragExtent = 0;
  static const double _swipeThreshold = 50.0;
  static const double _maxSwipe = 70.0;

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      if (widget.isMe) {
        _dragExtent = (_dragExtent + details.delta.dx).clamp(-_maxSwipe, 0);
      } else {
        _dragExtent = (_dragExtent + details.delta.dx).clamp(0, _maxSwipe);
      }
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_dragExtent.abs() >= _swipeThreshold) {
      HapticFeedback.mediumImpact();
      widget.onReply?.call(widget.message);
    }
    setState(() {
      _dragExtent = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double progress = (_dragExtent.abs() / _swipeThreshold).clamp(0.0, 1.0);

    return Stack(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      children: [
        Positioned(
          left: widget.isMe ? null : 20,
          right: widget.isMe ? 20 : null,
          child: Opacity(
            opacity: progress,
            child: Transform.scale(
              scale: 0.5 + (progress * 0.5),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor2,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.reply,
                  color: primaryColor2,
                  size: 20,
                ),
              ),
            ),
          ),
        ),

        GestureDetector(
          onHorizontalDragUpdate: _onHorizontalDragUpdate,
          onHorizontalDragEnd: _onHorizontalDragEnd,
          child: Transform.translate(
            offset: Offset(_dragExtent, 0),
            child: _buildBubble(),
          ),
        ),
      ],
    );
  }

  Widget _buildBubble() {
    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 12),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: widget.isMe ? primaryColor2 : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(widget.isMe ? 16 : 4),
            bottomRight: Radius.circular(widget.isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment:
          widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.message.isReply) _buildQuotedMessage(),

            Text(
              widget.message.message ?? "",
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),

            const SizedBox(height: 3),

            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.message.getMessageTime(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 10,
                  ),
                ),
                if (widget.isMe) ...[
                  const SizedBox(width: 3),
                  Icon(
                    widget.message.isRead == true ? Icons.done_all : Icons.done,
                    size: 13,
                    color: widget.message.isRead == true
                        ? Colors.blue[300]
                        : Colors.white.withOpacity(0.6),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuotedMessage() {
    final isReplyToMe = widget.message.replyToSenderName == 'You';
    final displayName = isReplyToMe ? 'You' : widget.receiverName;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.only(left: 8, right: 6, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: widget.isMe
            ? primaryColor1
            : Colors.grey[800]!.withOpacity(0.5),
        borderRadius: BorderRadius.circular(4),
        border: Border(
          left: BorderSide(
            color: isReplyToMe ? primaryColor : Colors.orange[300]!,
            width: 2,
          ),
        ),
      ),
      child: RichText(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          children: [
            TextSpan(
              text: '$displayName: ',
              style: TextStyle(
                color: isReplyToMe ? primaryColor : Colors.orange[300],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: widget.message.replyToMessage ?? '',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}






















/*


class ChatScreen extends StatefulWidget {
  final MessageClass receiverUser;
  final String roomName;
  final String avatarUrl;
  final String profilePicUrl;
  final String name;

  const ChatScreen({
    Key? key,
    required this.receiverUser,
    required this.roomName,
    required this.avatarUrl,
    required this.profilePicUrl,
    required this.name,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ChatState();
}

class _ChatState extends State<ChatScreen> {
  // ═══════════════════════════════════════════════════════════════
  // CONSTANTS
  // ═══════════════════════════════════════════════════════════════
  static const double _appBarHeight = 60.0;
  static const Color _darkBackground = Color(0xFF1A1A1A);
  static const Color _appBarColor = Color(0xFF1E1E1E);

  // ═══════════════════════════════════════════════════════════════
  // CONTROLLERS
  // ═══════════════════════════════════════════════════════════════
  final ScrollController _avatarModeScrollController = ScrollController();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // ═══════════════════════════════════════════════════════════════
  // STATE
  // ═══════════════════════════════════════════════════════════════
  bool _isflip = false;
  bool showOverlay = true;
  bool _isExiting = false;
  bool _isSending = false;
  bool _hasEnteredAvatarMode = false;

  // ═══════════════════════════════════════════════════════════════
  // AVATAR DOWNLOAD STATE
  // ═══════════════════════════════════════════════════════════════
  bool _isOtherAvatarDownloading = false;
  bool _isOtherAvatarReady = false;
  double _avatarDownloadProgress = 0.0;
  bool _userWaitingForAvatarMode = false; // User tapped button while downloading
  Timer? _avatarModeTimeoutTimer;
  StreamSubscription<DocumentSnapshot>? _otherAvatarListener;

  // ═══════════════════════════════════════════════════════════════
  // REPLY STATE
  // ═══════════════════════════════════════════════════════════════
  MessageClass? _replyToMessage;

  // ═══════════════════════════════════════════════════════════════
  // TIMERS & SUBSCRIPTIONS
  // ═══════════════════════════════════════════════════════════════
  Timer? _typingDebounce;
  StreamSubscription<bool>? _typingListener;
  final ValueNotifier<bool> _isReceiverTyping = ValueNotifier(false);

  // ═══════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ═══════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    ActiveChatTracker.activeRoomId = widget.roomName;
    _initData();
    _initOtherUserAvatar();

    final db = Provider.of<FirestoreChatService>(context, listen: false);

    _typingListener = db
        .listenToTypingStatus(widget.receiverUser.otherUserId.toString())
        .listen((isTyping) {
      _isReceiverTyping.value = isTyping;
    });

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        final db = Provider.of<FirestoreChatService>(context, listen: false);
        db.stopTyping(widget.receiverUser.otherUserId.toString());
      } else {
        if (!showOverlay) {
          GlobalUnityController().controller?.postMessage(
            "Camera",
            "zoomINCamera",
            "",
          );
        }
      }
    });
  }

  void _initData() {
    final db = Provider.of<FirestoreChatService>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await db.updateReceiverUser(newReceiverUser: widget.receiverUser);
      db.listenerController();
      db.getAllMessages();
      db.setActiveChat(widget.roomName);
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // AVATAR DOWNLOAD - STARTS IMMEDIATELY ON CHAT OPEN
  // ═══════════════════════════════════════════════════════════════

  Future<void> _initOtherUserAvatar() async {
    final avatarManager = AvatarManager();
    await avatarManager.initialize();

    final otherUserId = widget.receiverUser.otherUserId.toString();

    // Check if already have their avatar locally
    final alreadyHave = await avatarManager.isOtherAvatarReady(otherUserId);

    if (alreadyHave) {
      if (mounted) {
        setState(() {
          _isOtherAvatarReady = true;
          _isOtherAvatarDownloading = false;
          _avatarDownloadProgress = 1.0;
        });
      }
      debugPrint("[ChatScreen] Other user's avatar already exists locally");
    } else {
      // Start downloading immediately
      if (mounted) {
        setState(() {
          _isOtherAvatarDownloading = true;
          _avatarDownloadProgress = 0.0;
        });
      }

      final path = await avatarManager.downloadOtherUserAvatar(
        otherUserId,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _avatarDownloadProgress = progress;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _isOtherAvatarDownloading = false;
          _isOtherAvatarReady = path != null;
          _avatarDownloadProgress = path != null ? 1.0 : 0.0;
        });

        // If user was waiting for avatar mode, auto-enter now
        if (_userWaitingForAvatarMode && path != null) {
          _avatarModeTimeoutTimer?.cancel();
          _enterAvatarMode();
        }
      }
    }

    // Listen for future avatar updates
    _otherAvatarListener = avatarManager.listenToUserAvatarChanges(
      otherUserId,
      onAvatarUpdated: (newLocalPath) {
        if (mounted && newLocalPath != null) {
          setState(() => _isOtherAvatarReady = true);

          debugPrint("[ChatScreen] Other user's avatar updated: $newLocalPath");

          if (!showOverlay) {
            GlobalUnityController().controller?.postMessage(
              "CreateRoomMenu",
              "obtainNewUrl",
              otherUserId,
            );
          }
        }
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // AVATAR MODE ENTRY LOGIC
  // ═══════════════════════════════════════════════════════════════

  void _onAvatarModeButtonTap() {
    if (_hasEnteredAvatarMode) return;

    // Avatar already ready → enter immediately
    if (_isOtherAvatarReady) {
      _enterAvatarMode();
      return;
    }

    // Avatar still downloading → show "Setting up" state + wait
    if (_isOtherAvatarDownloading) {
      setState(() {
        _userWaitingForAvatarMode = true;
      });

      // Start 8-second timeout
      _avatarModeTimeoutTimer?.cancel();
      _avatarModeTimeoutTimer = Timer(const Duration(seconds: 15), () {
        if (mounted && _userWaitingForAvatarMode && !_isOtherAvatarReady) {
          setState(() {
            _userWaitingForAvatarMode = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.wifi_off, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Taking too long, Internet may be Slow than expected",
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red.shade800,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      });

      return;
    }

    // Not downloading and not ready → other user hasn't synced their avatar
    // Show message but still allow entry
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.person_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "${widget.name}'s avatar hasn't synced yet. You can enter Avatar Mode, but their avatar may not appear.",
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade800,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        action: SnackBarAction(
          label: "Enter Anyway",
          textColor: Colors.white,
          onPressed: () {
            _enterAvatarMode();
          },
        ),
      ),
    );
  }

  void _enterAvatarMode() {
    if (_hasEnteredAvatarMode) return;

    _avatarModeTimeoutTimer?.cancel();

    GlobalUnityController().setAvatarModeOn(true);
    _initUnity();
    final hadFocus = _focusNode.hasFocus;

    setState(() {
      showOverlay = false;
      _hasEnteredAvatarMode = true;
      _userWaitingForAvatarMode = false;
    });

    if (hadFocus) {
      Future.microtask(() {
        if (mounted && !_focusNode.hasFocus) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  void _initUnity() {
    final unity = GlobalUnityController();
    unity.showUnity();
    unity.setAvatarUrl(widget.avatarUrl);
    unity.setRoomName(widget.roomName);
    unity.resumeUnity();
  }

  @override
  void dispose() {
    ActiveChatTracker.activeRoomId = null;
    final db = Provider.of<FirestoreChatService>(context, listen: false);
    _avatarModeScrollController.dispose();
    db.stopTyping(widget.receiverUser.otherUserId.toString());
    _typingListener?.cancel();
    _typingDebounce?.cancel();
    _isReceiverTyping.dispose();
    db.disposeController();
    _controller.dispose();
    _focusNode.dispose();

    // Cleanup avatar
    _otherAvatarListener?.cancel();
    _avatarModeTimeoutTimer?.cancel();
    AvatarManager()
        .stopListeningToUserAvatar(widget.receiverUser.otherUserId.toString());

    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  // REPLY METHODS
  // ═══════════════════════════════════════════════════════════════

  void _setReplyTo(MessageClass message) {
    setState(() {
      _replyToMessage = message;
    });
    _focusNode.requestFocus();
  }

  void _clearReply() {
    setState(() {
      _replyToMessage = null;
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // SEND MESSAGE
  // ═══════════════════════════════════════════════════════════════

  void _sendMessage() async {
    final db = Provider.of<FirestoreChatService>(context, listen: false);
    db.stopTyping(widget.receiverUser.otherUserId.toString());

    final message = _controller.text.trim();
    if (_isSending || message.isEmpty) return;

    setState(() => _isSending = true);

    try {
      if (!showOverlay) {
        GlobalUnityController().controller?.postMessage(
          "AnimController",
          "sendMikkMsg",
          message,
        );
      }

      _controller.clear();

      await db.sendMessage(
        msg: message,
        roomName: widget.roomName,
        replyToMessage: _replyToMessage,
      );

      _clearReply();

      if (!_focusNode.hasFocus) {
        _focusNode.requestFocus();
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _handleBackPressed() async {
    final db = Provider.of<FirestoreChatService>(context, listen: false);
    db.setActiveChat(null);

    if (_isExiting) return;
    setState(() => _isExiting = true);

    // Cancel waiting state
    _avatarModeTimeoutTimer?.cancel();
    _userWaitingForAvatarMode = false;

    if (!showOverlay) {
      GlobalUnityController()
          .controller
          ?.postMessage("RoomActionCanvas", "whoLeaveRoom", "");
      GlobalUnityController().increment();
      GlobalUnityController().pauseUnity();
      GlobalUnityController().hideUnity();
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final topPadding = MediaQuery.of(context).padding.top;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBackPressed();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: showOverlay,
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            if (GlobalUnityController().isVisible &&
                GlobalUnityController().isAvatarModeOn)
              Positioned.fill(
                child: GlobalUnityController().getUnityWidget(),
              ),

            if (showOverlay)
              Positioned.fill(
                child: Container(color: _darkBackground),
              ),

            if (showOverlay)
              Positioned(
                top: topPadding + _appBarHeight,
                bottom: 0,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Flexible(
                      child: _ChatModeMessages(
                        onReply: _setReplyTo,
                        receiverName: widget.name,
                      ),
                    ),
                    _buildInputArea(),
                  ],
                ),
              ),

            if (!showOverlay)
              Positioned(
                top: topPadding + _appBarHeight,
                left: 0,
                right: 0,
                child: _AvatarModeMessages(
                  scrollController: _avatarModeScrollController,
                ),
              ),

            if (!showOverlay)
              Positioned(
                bottom: keyboardHeight,
                left: 0,
                right: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _AvatarModeChatBubble(),
                    _buildInputArea(),
                  ],
                ),
              ),

            if (showOverlay) _buildChatModeAppBar(topPadding),

            if (!showOverlay) ...[
              Positioned(
                top: topPadding + 10,
                left: 12,
                child: _TopButton(
                  icon: Icons.arrow_back,
                  onPressed: _handleBackPressed,
                  size: 20,
                  padding: 12,
                ),
              ),
              Positioned(
                top: topPadding + 10,
                right: 12,
                child: _TopButton(
                  icon: Icons.flip_camera_android,
                  size: 20,
                  padding: 8,
                  onPressed: () {
                    GlobalUnityController()
                        .controller
                        ?.postMessage("Camera", "slideHisSide", "");
                  },
                ),
              ),
            ],

          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // APP BAR WITH DYNAMIC AVATAR MODE BUTTON
  // ═══════════════════════════════════════════════════════════════

  Widget _buildChatModeAppBar(double topPadding) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(top: topPadding),
        decoration: const BoxDecoration(
          color: _appBarColor,
          boxShadow: [
            BoxShadow(
              color: Color(0x4D000000),
              offset: Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: SizedBox(
          height: _appBarHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: Colors.white, size: 24),
                  onPressed: _handleBackPressed,
                  padding: const EdgeInsets.all(8),
                ),
                _buildProfilePicture(),
                const SizedBox(width: 12),
                Expanded(
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _isReceiverTyping,
                    builder: (_, isTyping, __) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (isTyping)
                            const Text(
                              "typing…",
                              style:
                              TextStyle(color: Colors.teal, fontSize: 12),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                if (!_hasEnteredAvatarMode) _buildAvatarModeButton(),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // AVATAR MODE BUTTON - 3 STATES
  // ═══════════════════════════════════════════════════════════════

  Widget _buildAvatarModeButton() {
    // STATE 1: User tapped, waiting for download to finish
    if (_userWaitingForAvatarMode) {
      return _buildSettingUpButton();
    }

    // STATE 2: Downloading in background (user hasn't tapped yet)
    if (_isOtherAvatarDownloading && !_isOtherAvatarReady) {
      return _buildDownloadingButton();
    }

    // STATE 3: Ready or no download needed
    return _buildReadyButton();
  }

  /// Normal "Avatar Mode" button - always tappable
  Widget _buildReadyButton() {
    return GestureDetector(
      onTap: _onAvatarModeButtonTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.teal.withOpacity(0.9),
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: const Text(
          "Avatar Mode",
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// Downloading in background - shows progress bar, still tappable
  Widget _buildDownloadingButton() {
    return GestureDetector(
      onTap: _onAvatarModeButtonTap,
      child: Container(
        width: 110,
        decoration: BoxDecoration(
          color: Colors.teal.withOpacity(0.7),
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Avatar Mode",
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 3,
                child: LinearProgressIndicator(
                  value: _avatarDownloadProgress,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// "Setting up..." state - user tapped while downloading
  Widget _buildSettingUpButton() {
    return Container(
      width: 130,
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                "Setting up...",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 3,
              child: LinearProgressIndicator(
                value: _avatarDownloadProgress,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor:
                const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePicture() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 40,
        width: 40,
        child: widget.profilePicUrl.isNotEmpty
            ? CachedNetworkImage(
          imageUrl: widget.profilePicUrl,
          placeholder: (context, url) => const _ProfilePlaceholder(),
          fit: BoxFit.cover,
          errorWidget: (context, url, error) =>
          const _DefaultAvatar(),
        )
            : const _DefaultAvatar(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // INPUT AREA (unchanged)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildInputArea() {
    final db = Provider.of<FirestoreChatService>(context, listen: false);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_replyToMessage != null) _buildReplyPreview(db),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide:
                      const BorderSide(color: Colors.grey, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide:
                      const BorderSide(color: Colors.teal, width: 2),
                    ),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  onChanged: (text) {
                    final db = Provider.of<FirestoreChatService>(context,
                        listen: false);
                    _typingDebounce?.cancel();

                    if (text.isNotEmpty) {
                      _typingDebounce =
                          Timer(const Duration(milliseconds: 300), () {
                            db.updateTyping(
                              otherUserId:
                              widget.receiverUser.otherUserId.toString(),
                              isTyping: true,
                            );
                          });
                    } else {
                      db.stopTyping(
                          widget.receiverUser.otherUserId.toString());
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.send,
                    color: _isSending ? Colors.grey : Colors.teal),
                onPressed: _isSending ? null : _sendMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReplyPreview(FirestoreChatService db) {
    final isMyMessage = _replyToMessage!.userId == db.uid;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: isMyMessage ? Colors.teal : Colors.orange,
            width: 4,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isMyMessage ? 'You' : widget.name,
                  style: TextStyle(
                    color: isMyMessage ? Colors.teal : Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _replyToMessage!.message ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _clearReply,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white54,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ALL OTHER HELPER WIDGETS REMAIN EXACTLY THE SAME
// Copy from your original code:
// _ProfilePlaceholder, _DefaultAvatar, _TopButton,
// _ChatModeMessages, _SwipeableChatBubble, _DateSeparator,
// _AvatarModeMessages, _CenterChatBubble, _AvatarModeChatBubble
// ═══════════════════════════════════════════════════════════════




// ═══════════════════════════════════════════════════════════════
// HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════

class _ProfilePlaceholder extends StatelessWidget {
  const _ProfilePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF2A2A2A),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      ),
    );
  }
}

class _DefaultAvatar extends StatelessWidget {
  const _DefaultAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF2A2A2A),
      child: const Icon(Icons.person, size: 22, color: Colors.white30),
    );
  }
}

class _TopButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final double size;
  final double padding;

  const _TopButton({
    required this.icon,
    required this.onPressed,
    this.size = 28,
    this.padding = 12,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: EdgeInsets.all(padding),
        child: Icon(icon, color: Colors.white, size: size),
      ),
    );
  }
}


// ═══════════════════════════════════════════════════════════════
// CHAT MODE MESSAGES (UPDATED WITH REPLY CALLBACK)
// ═══════════════════════════════════════════════════════════════

class _ChatModeMessages extends StatefulWidget {
  final Function(MessageClass)? onReply;
  final String receiverName;

  const _ChatModeMessages({
    this.onReply,
    required this.receiverName,
  });

  @override
  State<_ChatModeMessages> createState() => _ChatModeMessagesState();
}

class _ChatModeMessagesState extends State<_ChatModeMessages>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  bool _shouldAutoScroll = true;
  double? _previousMaxExtent;
  bool _isFirstLoad = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (_shouldAutoScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToBottom(animate: false);
      });
    }
  }

  void _onScroll() {
    if (!mounted) return;

    final db = Provider.of<FirestoreChatService>(context, listen: false);

    if (_scrollController.position.pixels <= 100 &&
        !db.isLoadingMore &&
        db.hasMoreMessages) {
      _loadMoreOlderMessages();
    }

    final isNearBottom = _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 150;

    if (isNearBottom != _shouldAutoScroll) {
      _shouldAutoScroll = isNearBottom;
    }
  }

  void _loadMoreOlderMessages() {
    final db = Provider.of<FirestoreChatService>(context, listen: false);

    _previousMaxExtent = _scrollController.position.maxScrollExtent;
    final currentOffset = _scrollController.offset;

    db.loadMoreMessages().then((_) {
      if (!mounted) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;

        if (_previousMaxExtent != null) {
          final newMaxExtent = _scrollController.position.maxScrollExtent;
          final addedHeight = newMaxExtent - _previousMaxExtent!;

          if (addedHeight > 0) {
            _scrollController.jumpTo(currentOffset + addedHeight);
          }
        }
      });
    });
  }

  void _scrollToBottom({bool animate = true}) {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;

    if (animate && !_isFirstLoad) {
      _scrollController.animateTo(
        maxScroll,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(maxScroll);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Consumer<FirestoreChatService>(
      builder: (context, db, child) {
        final allMessages = db.getAllMessagesSorted();

        if (allMessages.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || !_scrollController.hasClients) return;

            if (_isFirstLoad) {
              _scrollController
                  .jumpTo(_scrollController.position.maxScrollExtent);

              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted && _scrollController.hasClients) {
                  _scrollController
                      .jumpTo(_scrollController.position.maxScrollExtent);
                  _isFirstLoad = false;
                }
              });
            } else if (_shouldAutoScroll) {
              _scrollToBottom(animate: true);
            }
          });
        }

        if (allMessages.isEmpty) {
          return Center(
            child: db.isLoadingMore
                ? const CircularProgressIndicator(color: Colors.teal)
                : const Text(
              "No messages yet.\nSay hello! 👋",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        return Column(
          children: [
            if (db.isLoadingMore)
              const Padding(
                padding: EdgeInsets.all(12.0),
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.teal),
                ),
              ),

            if (db.hasMoreMessages &&
                !db.isLoadingMore &&
                allMessages.length >= FirestoreChatService.pageSize)
              GestureDetector(
                onTap: _loadMoreOlderMessages,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    "↑ Scroll up for older messages",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              ),

            // Messages List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                itemCount: allMessages.length,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemBuilder: (context, index) {
                  final msg = allMessages[index];
                  final isMe = msg.userId == db.uid;

                  bool showDateSeparator = false;
                  if (index == 0) {
                    showDateSeparator = true;
                  } else {
                    final prevMsg = allMessages[index - 1];
                    showDateSeparator = !_isSameDay(
                      msg.timeStamp ?? 0,
                      prevMsg.timeStamp ?? 0,
                    );
                  }

                  return Column(
                    children: [
                      if (showDateSeparator)
                        _DateSeparator(timestamp: msg.timeStamp ?? 0),
                      _SwipeableChatBubble(
                        message: msg,
                        isMe: isMe,
                        onReply: widget.onReply,
                        receiverName: widget.receiverName,
                        key: ValueKey('msg_${msg.messageId ?? msg.timeStamp}'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  bool _isSameDay(int timestamp1, int timestamp2) {
    if (timestamp1 == 0 || timestamp2 == 0) return false;
    final date1 = DateTime.fromMillisecondsSinceEpoch(timestamp1);
    final date2 = DateTime.fromMillisecondsSinceEpoch(timestamp2);
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}

// ═══════════════════════════════════════════════════════════════
// DATE SEPARATOR
// ═══════════════════════════════════════════════════════════════

class _DateSeparator extends StatelessWidget {
  final int timestamp;

  const _DateSeparator({required this.timestamp});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);

    String dateText;
    if (difference.inDays == 0) {
      dateText = "Today";
    } else if (difference.inDays == 1) {
      dateText = "Yesterday";
    } else if (difference.inDays < 7) {
      dateText = DateFormat('EEEE').format(date);
    } else {
      dateText = DateFormat('MMM dd, yyyy').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Colors.grey)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              dateText,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Expanded(child: Divider(color: Colors.grey)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SWIPEABLE CHAT BUBBLE (NEW)
// ═══════════════════════════════════════════════════════════════

class _SwipeableChatBubble extends StatefulWidget {
  final MessageClass message;
  final bool isMe;
  final Function(MessageClass)? onReply;
  final String receiverName;

  const _SwipeableChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onReply,
    required this.receiverName,
  });

  @override
  State<_SwipeableChatBubble> createState() => _SwipeableChatBubbleState();
}

class _SwipeableChatBubbleState extends State<_SwipeableChatBubble> {
  double _dragExtent = 0;
  static const double _swipeThreshold = 50.0;
  static const double _maxSwipe = 70.0;

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      if (widget.isMe) {
        _dragExtent = (_dragExtent + details.delta.dx).clamp(-_maxSwipe, 0);
      } else {
        _dragExtent = (_dragExtent + details.delta.dx).clamp(0, _maxSwipe);
      }
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_dragExtent.abs() >= _swipeThreshold) {
      HapticFeedback.mediumImpact();
      widget.onReply?.call(widget.message);
    }
    setState(() {
      _dragExtent = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double progress =
    (_dragExtent.abs() / _swipeThreshold).clamp(0.0, 1.0);

    return Stack(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      children: [
        // Reply icon
        Positioned(
          left: widget.isMe ? null : 20,
          right: widget.isMe ? 20 : null,
          child: Opacity(
            opacity: progress,
            child: Transform.scale(
              scale: 0.5 + (progress * 0.5),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.reply,
                  color: Colors.teal[300],
                  size: 20,
                ),
              ),
            ),
          ),
        ),

        // Swipeable bubble
        GestureDetector(
          onHorizontalDragUpdate: _onHorizontalDragUpdate,
          onHorizontalDragEnd: _onHorizontalDragEnd,
          child: Transform.translate(
            offset: Offset(_dragExtent, 0),
            child: _buildBubble(),
          ),
        ),
      ],
    );
  }

  Widget _buildBubble() {
    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(10), // ✅ Slightly reduced
        margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 12),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: widget.isMe ? Colors.teal[700] : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(widget.isMe ? 16 : 4),
            bottomRight: Radius.circular(widget.isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment:
          widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quoted message
            if (widget.message.isReply) _buildQuotedMessage(),

            // Message text
            Text(
              widget.message.message ?? "",
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),

            const SizedBox(height: 3), // ✅ Reduced

            // Time and read status
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.message.getMessageTime(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 10,
                  ),
                ),
                if (widget.isMe) ...[
                  const SizedBox(width: 3),
                  Icon(
                    widget.message.isRead == true
                        ? Icons.done_all
                        : Icons.done,
                    size: 13,
                    color: widget.message.isRead == true
                        ? Colors.blue[300]
                        : Colors.white.withOpacity(0.6),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // QUOTED MESSAGE - FIXED FOR COMPACT LAYOUT
  // ═══════════════════════════════════════════════════════════════
  Widget _buildQuotedMessage() {
    final isReplyToMe = widget.message.replyToSenderName == 'You';
    final displayName = isReplyToMe ? 'You' : widget.receiverName;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.only(left: 8, right: 6, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: widget.isMe
            ? Colors.teal[800]!.withOpacity(0.5)
            : Colors.grey[800]!.withOpacity(0.5),
        borderRadius: BorderRadius.circular(4),
        border: Border(
          left: BorderSide(
            color: isReplyToMe ? Colors.teal[300]! : Colors.orange[300]!,
            width: 2,
          ),
        ),
      ),
      child: RichText(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          children: [
            TextSpan(
              text: '$displayName: ',
              style: TextStyle(
                color: isReplyToMe ? Colors.teal[300] : Colors.orange[300],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: widget.message.replyToMessage ?? '',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

}

// ═══════════════════════════════════════════════════════════════
// AVATAR MODE WIDGETS (Keep existing)
// ═══════════════════════════════════════════════════════════════

class _AvatarModeMessages extends StatefulWidget {
  final ScrollController scrollController;

  const _AvatarModeMessages({required this.scrollController});

  @override
  State<_AvatarModeMessages> createState() => _AvatarModeMessagesState();
}

class _AvatarModeMessagesState extends State<_AvatarModeMessages>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Consumer<FirestoreChatService>(
      builder: (context, db, child) {
        List<MessageClass> theirMessages = List.from(db.receiverMessageList);
        theirMessages
            .sort((a, b) => (a.timeStamp ?? 0).compareTo(b.timeStamp ?? 0));

        final displayMessages = theirMessages.length > 5
            ? theirMessages.sublist(theirMessages.length - 5)
            : theirMessages;

        if (displayMessages.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          height: 60,
          width: double.infinity,
          padding: const EdgeInsets.only(top: 1),
          child: Center(
            child: SizedBox(
              width: 300,
              child: ListView.builder(
                controller: widget.scrollController,
                reverse: true,
                physics: const ClampingScrollPhysics(),
                itemCount: displayMessages.length,
                itemBuilder: (context, index) {
                  final msg =
                  displayMessages[displayMessages.length - 1 - index];
                  return _CenterChatBubble(
                    message: msg,
                    key: ValueKey('center_${msg.messageId ?? msg.timeStamp}'),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CenterChatBubble extends StatelessWidget {
  final MessageClass message;

  const _CenterChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
        child: Text(
          message.message ?? "",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _AvatarModeChatBubble extends StatelessWidget {
  const _AvatarModeChatBubble();

  @override
  Widget build(BuildContext context) {
    return Consumer<FirestoreChatService>(
      builder: (context, db, child) {
        List<MessageClass> myMessages = List.from(db.sendMessageList);

        if (myMessages.isEmpty) {
          return const SizedBox.shrink();
        }

        myMessages
            .sort((a, b) => (a.timeStamp ?? 0).compareTo(b.timeStamp ?? 0));
        final latestMessage = myMessages.last;

        return Container(
          constraints: const BoxConstraints(maxHeight: 50),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Center(
            child: Text(
              latestMessage.message ?? "",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }
}
*/






/*
class ChatScreen extends StatefulWidget {
  final MessageClass receiverUser;
  final String roomName;
 // final String avatarUrl;

  const ChatScreen({super.key, required this.receiverUser, required this.roomName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showEmojiPicker = false;


  @override
  void initState() {
    super.initState();
   */
/* GlobalUnityController().setAvatarUrl(widget.avatarUrl);
    GlobalUnityController().setRoomName(widget.roomName);
    GlobalUnityController().showUnity();
    GlobalUnityController().resumeUnity(true);*//*

    _initData();
  }

  void _initData() {
    final db = Provider.of<DatabaseService>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await db.listenerController();
      db.getOwnData();
      db.getReceiverData(receiverUser: widget.receiverUser);
    });
  }





  @override
  void dispose() {
   */
/* GlobalUnityController().controller?.postMessage("RoomActionCanvas","OnClick_Leave","");
    GlobalUnityController().hideUnity();
    GlobalUnityController().pauseUnity();*//*

    Provider.of<DatabaseService>(context, listen: false).disposeController();
    super.dispose();
  }


 @override
  Widget build(BuildContext context) {
   return Scaffold(
     resizeToAvoidBottomInset: false,
     backgroundColor: Colors.transparent,
     body: Stack(
       children: [
       */
/* if (GlobalUnityController().isVisible)
           Positioned.fill(
             child: GlobalUnityController().getUnityWidget(),
           ),*//*

         SafeArea(
           child: AnimatedPadding(
             padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
             duration: const Duration(milliseconds: 300),
             curve: Curves.easeOut,
             child: Column(
               children: [
                 _appBar(),
                 Expanded(child: _messagesArea()),
                 const Divider(height: 1),
                 _msgInputArea(),
               ],
             ),
           ),
         ),
       ],
     ),
   );

   */
/* return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          if (GlobalUnityController.dart().isVisible)
            Positioned.fill(
              child: GlobalUnityController.dart().getUnityWidget(),
            ),
          SafeArea(
            child: Column(
              children: [
                _appBar(),
                Expanded(child: _messagesArea()),
                const Divider(height: 1),
                _msgInputArea(),
              ],
            ),
          ),
        ],
      ),
    );*//*

  }










  Widget _appBar() {
    return AppBar(
      centerTitle: true,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: IconButton(
          icon: const Icon(Icons.arrow_back,color: Colors.black,),
          onPressed: LeaveRoom,
        )
      ),
      title: Text(
        widget.receiverUser.name.toString(),
        style: TextStyle(fontWeight: FontWeight.bold, color: whiteColor),
        
      ),
      backgroundColor: Colors.transparent,
    );
  }

  Widget _messagesArea() {
    return Consumer<DatabaseService>(
      builder: (context, db, _) {
        return ListView.builder(
          controller: db.scrollController,
          reverse: true,
          physics: const BouncingScrollPhysics(),
          itemCount: db.receiverMessageList.length + db.sendMessageList.length,
          padding: EdgeInsets.only(top: db.hasMore ? MediaQuery.of(context).size.height / 2 : 0),
          itemBuilder: (context, index) {
            if (index < db.receiverMessageList.length) {
              final msg = db.receiverMessageList[index];
              return _chatBubble(msg, Alignment.bottomLeft);
            } else {
              final msg = db.sendMessageList[index - db.receiverMessageList.length];
              return _chatBubble(msg, Alignment.bottomRight);
            }
          },
        );
      },
    );
  }

  Widget _chatBubble(MessageClass msg, Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
        constraints: const BoxConstraints(maxWidth: 270),
        decoration: BoxDecoration(
          color: msg.isMe ? Colors.teal[100] : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text(msg.message ?? "")),
            if (msg.isMe) ...[
              const SizedBox(width: 5),
              const Icon(Icons.done_all, size: 16, color: Colors.blue),
            ],
          ],
        ),
      ),
    );
  }

  Widget _msgInputArea() {
    final db = Provider.of<DatabaseService>(context, listen: false);
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.emoji_emotions_outlined),
          onPressed: _toggleEmojiPicker,
        ),
        Expanded(
          child: TextField(
            controller: _msgController,
            focusNode: _focusNode,
            decoration: const InputDecoration(
              hintText: 'Type a message...',
              border: InputBorder.none,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.send, color: Colors.teal),
          onPressed: () {
            if (_msgController.text.trim().isNotEmpty) {
          //    GlobalUnityController().controller?.postMessage("AnimController","doChats",_msgController.text.toString());
              db.sendMessage(msg: _msgController.text.trim()).then((_) {
                _msgController.clear();
                
             //   db.getOwnData();
               // db.getReceiverData(receiverUser: widget.receiverUser);
                FocusScope.of(context).requestFocus(_focusNode);
              });
            }
          },
        ),
      ],
    );
  }

  void _toggleEmojiPicker() {
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
      if (_showEmojiPicker) {
        FocusScope.of(context).unfocus();
      } else {
        _focusNode.requestFocus();
      }
    });
  }





  void LeaveRoom() {
     Navigator.pop(context);
  }
}


*/






/*
class ChatScreen extends StatefulWidget {
  final MessageClass receiverUser;

  const ChatScreen({super.key, required this.receiverUser});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Map<String, dynamic>> messages = [
    {'text': 'Hey!', 'isMe': false},
    {'text': 'Hello, how are you?', 'isMe': true},
    {'text': 'I am good. What about you?', 'isMe': false},
    {'text': 'Doing well, thanks!', 'isMe': true},
  ];

  TextEditingController _msgController = TextEditingController();
  FocusNode focusNode = new FocusNode();

  @override
  void initState() {
    super.initState();
    fillData();
  }

  fillData() {
    final databaseServiceVM = Provider.of<DatabaseService>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await databaseServiceVM.listenerController();
      databaseServiceVM.getOwnData();
      databaseServiceVM.getReceiverData(receiverUser: widget.receiverUser);
      getCurrentUserData();
    });
  }

  getCurrentUserData() async {
    String avatarUrl = "";
    String profilePic = "";

    final personalInfoVM = Provider.of<PersonalInformationViewModel>(context, listen: false);
    UserProfileModel? userProfile = await personalInfoVM.getUserProfile();
    if (userProfile != null) {
      profilePic = userProfile!.profilePic.toString();
      avatarUrl = userProfile!.avatarUrl.toString();
    }
    String viewerUrl = Uri.encodeFull(
      (userProfile != null && avatarUrl.isNotEmpty)
          ? 'https://optimus-prime-cd.github.io/readyplayerme-viewer/?modelUrl=$avatarUrl'
          : 'https://optimus-prime-cd.github.io/readyplayerme-viewer/?modelUrl=https://models.readyplayer.me/682e1240092177c0ba355fde.glb',
    );
  }

  @override
  void dispose() {
    DatabaseService().disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseService>(builder: (context, dbServices, child) {
      return Scaffold(
        appBar: appBar(),
        body: Column(
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: ListView.builder(
                      // controller: dbServices.scrollController,
                      reverse: true,
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemCount: dbServices.receiverMessageList.length + (dbServices.isLoadingMore ? 1 : 0),
                      padding: EdgeInsets.only(top: dbServices.hasMore ? MediaQuery.of(context).size.height / 2 : 0),
                      itemBuilder: (context, index) {
                        final item = dbServices.receiverMessageList[index];
                        return listItemUi(
                          msg: item,
                          alignment: Alignment.bottomLeft,
                        );
                        // return ListTile(
                        //     title: Text(item.message ?? 'No Name'),
                        //     subtitle: Text('Timestamp: ${item.timeStamp ?? 0}'),
                        //     trailing: Text(item.message ?? 'N/A'),
                        //   );
                      },
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: dbServices.scrollController,
                      reverse: true,
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemCount: dbServices.sendMessageList.length + (dbServices.isLoadingMore ? 1 : 0),
                      padding: EdgeInsets.only(top: dbServices.hasMore ? MediaQuery.of(context).size.height/2 : 0),
                      itemBuilder: (context, index) {
                        final item = dbServices.sendMessageList[index];
                        return listItemUi(msg: item, alignment: Alignment.bottomRight);
                        // return ListTile(
                        //     title: Text(item.message ?? 'No Name'),
                        //     subtitle: Text('Timestamp: ${item.timeStamp ?? 0}'),
                        //     trailing: Text(item.message ?? 'N/A'),
                        //   );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _msgTextField(dbServices: dbServices),
            // if (_showEmojiPicker)
            //   SizedBox(
            //     height: 250,
            //     child: EmojiPicker(
            //       onEmojiSelected: (category, emoji) {
            //         _onEmojiSelected(emoji);
            //       },
            //       config: EmojiPickerConfig(
            //         columns: 7,
            //         emojiSizeMax: 32,
            //         bgColor: Colors.white,
            //         indicatorColor: Colors.teal,
            //         iconColorSelected: Colors.teal,
            //         backspaceColor: Colors.teal,
            //         skinToneDialogBgColor: Colors.white,
            //       ),
            //     ),
            //   ),
          ],
        ),
      );
    });
  }

  _msgTextField({required DatabaseService dbServices}) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.emoji_emotions_outlined),
          onPressed: () {}, //_toggleEmojiPicker
        ),
        Expanded(
          child: TextField(
            controller: _msgController,
            focusNode: focusNode,
            decoration: const InputDecoration(
              hintText: 'Type a message...',
              border: InputBorder.none,
            ),
            // onSubmitted: (value) {
            //   dbServices.sendMessage(msg: _msgController.text).then(
            //     (value) {
            //       LogHelper("Message send");
            //       _msgController.clear();
            //       // DatabaseService().getData();
            //       dbServices.getOwnData();
            //       dbServices.getReceiverData(receiverUser: widget.receiverUser);
            //       FocusScope.of(context).requestFocus(focusNode);
            //     },
            //   );
            // },
          ),
        ),
        IconButton(
          icon: const Icon(Icons.send, color: Colors.teal),
          onPressed: () {
            // messages.add({'text': _msgController.text, 'isMe': true});
            // setState(() {
            //   _msgController.clear();
            // });
            dbServices.sendMessage(msg: _msgController.text).then(
              (value) {
                _msgController.clear();
                // DatabaseService().getData();
                dbServices.getOwnData();
                dbServices.getReceiverData(receiverUser: widget.receiverUser);
                FocusScope.of(context).requestFocus(focusNode);
              },
            );
          },
        ),
      ],
    );
  }

  Widget listItemUi({MessageClass? msg, required Alignment alignment}) {
    return Align(
      alignment: alignment,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 5),
        constraints: const BoxConstraints(maxWidth: 270),
        decoration: BoxDecoration(
          color: msg!.isMe ? Colors.teal[100] : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(child: Text(msg.message.toString())),
                if (msg.isMe) ...[
                  const SizedBox(width: 5),
                  const Icon(Icons.done_all, size: 16, color: Colors.blue),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _showEmojiPicker = false;
  final FocusNode _focusNode = FocusNode();

  // void _onEmojiSelected(Emoji emoji) {
  //   _msgController.text += emoji.emoji;
  // }

  void _toggleEmojiPicker() {
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
      if (_showEmojiPicker) {
        FocusScope.of(context).unfocus(); // Hide keyboard
      } else {
        _focusNode.requestFocus(); // Show keyboard
      }
    });
  }

  appBar() {
    return AppBar(
      centerTitle: true,
      leading: const Padding(
        padding: EdgeInsets.only(left: 16),
        child: CircleAvatar(
          backgroundImage: NetworkImage("https://i.pravatar.cc/150?img=3"),
          radius: 20,
        ),
      ),
      title: Text(
        widget.receiverUser.name.toString(),
        style: TextStyle(fontWeight: FontWeight.bold, color: whiteColor),
      ),
      backgroundColor: Colors.teal,
    );
  }
}
*/

