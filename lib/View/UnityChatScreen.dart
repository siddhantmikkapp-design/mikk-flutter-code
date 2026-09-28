import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mikk/values/Color.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../ActiveChatTracker.dart';
import '../Demo/MessageClass.dart';
import '../GlobalUnityController.dart';
import '../View_Model/Chat/FirestoreChatService.dart';

class UnityChatScreen extends StatefulWidget {
  final MessageClass receiverUser;
  final String roomName;
  final String avatarUrl;
  final String profilePicUrl;
  final String name;

  const UnityChatScreen({
    Key? key,
    required this.receiverUser,
    required this.roomName,
    required this.avatarUrl,
    required this.profilePicUrl,
    required this.name,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _UnityChatState();
}

class _UnityChatState extends State<UnityChatScreen> {
  // ═══════════════════════════════════════════════════════════════
  // CONTROLLERS
  // ═══════════════════════════════════════════════════════════════
  final ScrollController _avatarModeScrollController = ScrollController();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // ═══════════════════════════════════════════════════════════════
  // STATE
  // ═══════════════════════════════════════════════════════════════
  bool _isExiting = false;
  bool _isSending = false;

  // ═══════════════════════════════════════════════════════════════
  // AVATAR DOWNLOAD STATE
  // ═══════════════════════════════════════════════════════════════


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
    _initUnity();

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

  void _initUnity() {
    final unity = GlobalUnityController();
    unity.showUnity();
    unity.setAvatarUrl(widget.avatarUrl);
    unity.setRoomName(widget.roomName);
    unity.resumeUnity();
  }

  // ═══════════════════════════════════════════════════════════════
  // AVATAR DOWNLOAD
  // ═══════════════════════════════════════════════════════════════



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



    super.dispose();
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
      GlobalUnityController().controller?.postMessage(
        "AnimController",
        "sendMikkMsg",
        message,
      );

      _controller.clear();

      await db.sendMessage(
        msg: message,
        roomName: widget.roomName,
        replyToMessage: null,
      );

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

    GlobalUnityController()
        .controller
        ?.postMessage("RoomActionCanvas", "whoLeaveRoom", "");

    await GlobalUnityController().waitForLeaveConfirmation();


    GlobalUnityController().increment();
    GlobalUnityController().pauseUnity();
    GlobalUnityController().hideUnity();

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
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Unity Widget
            if (GlobalUnityController().isVisible)
              Positioned.fill(
                child: GlobalUnityController().getUnityWidget(),
              ),

            // Receiver Messages (Top)
            Positioned(
              top: topPadding + 7,
              left: 0,
              right: 0,
              child: _AvatarModeMessages(
                scrollController: _avatarModeScrollController,
              ),
            ),

            // My Latest Message (Bottom)
            Positioned(
              bottom: keyboardHeight + 60,
              left: 0,
              right: 0,
              child: const _AvatarModeChatBubble(),
            ),

            // Input Area
            Positioned(
              bottom: keyboardHeight,
              left: 0,
              right: 0,
              child: _buildInputArea(),
            ),

            // Back Button
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

            // Flip Camera Button
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

            // Download Progress Indicator

          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // INPUT AREA
  // ═══════════════════════════════════════════════════════════════

  Widget _buildInputArea() {
    return Container(
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
                final db =
                Provider.of<FirestoreChatService>(context, listen: false);
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
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════

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
// AVATAR MODE MESSAGES
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
                  final msg = displayMessages[displayMessages.length - 1 - index];
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

        myMessages.sort((a, b) => (a.timeStamp ?? 0).compareTo(b.timeStamp ?? 0));
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