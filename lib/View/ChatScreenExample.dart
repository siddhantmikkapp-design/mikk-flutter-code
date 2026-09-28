import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Demo/Message.dart';
import '../View_Model/Chat/ChatService.dart';






class ChatScreenExample extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String receiverProfilePic;

  const ChatScreenExample({
    Key? key,
    required this.receiverId,
    required this.receiverName,
    required this.receiverProfilePic,
  }) : super(key: key);

  @override
  State<ChatScreenExample> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreenExample> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late ChatService _chatService;

  @override
  void initState() {
    super.initState();
    _chatService = Provider.of<ChatService>(context, listen: false);
    _chatService.listenToMessages(widget.receiverId);

    // ✅ Listen for new messages and auto-scroll
    _chatService.addListener(_scrollToBottom);
  }

  @override
  void dispose() {
    _chatService.removeListener(_scrollToBottom);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0, // ✅ Scroll to position 0 (bottom in reverse ListView)
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isNotEmpty) {
      final text = _messageController.text.trim();
      _messageController.clear();

      await _chatService.sendMessage(widget.receiverId, text);
      // Auto-scroll will happen via listener
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Color(0xFF1E1E1E),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(widget.receiverProfilePic),
            ),
            SizedBox(width: 12),
            Text(
              widget.receiverName,
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: Consumer<ChatService>(
              builder: (context, chatService, child) {
                if (chatService.isLoading) {
                  return Center(
                    child: CircularProgressIndicator(color: Colors.teal),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,

                   // ✅ Keep reverse: true
                  padding: EdgeInsets.all(16),
                  itemCount: chatService.messages.length,
                  itemBuilder: (context, index) {
                    // ✅ Since messages are sorted oldest first and ListView is reversed,
                    // newest messages will appear at bottom
                    final message = chatService.messages[index];
                    return _MessageBubble(message: message);
                  },
                );
              },
            ),
          ),

          // Message Input
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF1E1E1E),
              border: Border(top: BorderSide(color: Colors.grey[800]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(color: Colors.teal),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  onPressed: _sendMessage,
                  icon: Icon(Icons.send, color: Colors.teal),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: message.isMe ? Colors.teal : Colors.grey[700],
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            SizedBox(height: 4),
            Text(
              message.formattedTime,
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}