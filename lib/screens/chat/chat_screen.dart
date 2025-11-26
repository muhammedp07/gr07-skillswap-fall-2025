// lib/screens/chat/chat_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/chat_models.dart' as chat_models; // 👈 use prefix
import '../../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();

  String get _currentUserId {
    final user = FirebaseAuth.instance.currentUser;
    // Fallback to dummy id if somehow not logged in
    return user?.uid ?? chat_models.dummyCurrentUserId; // 👈 updated
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();

    await ChatService.instance.sendTextMessageAndNotify(
      chatId: widget.chatId,
      senderId: _currentUserId,
      recipientId: widget.otherUserId, // who should get the notification
      text: text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<chat_models.ChatMessage>>(
              // 👈 typed
              stream: ChatService.instance.watchMessages(widget.chatId),
              builder: (context, snapshot) {
                // When messages arrive, mark the latest incoming one as read
                List<chat_models.ChatMessage> messages = [];

                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  messages = snapshot.data!;

                  final last = messages.last;
                  final isIncoming = last.senderId != _currentUserId;
                  final alreadyRead = last.readBy.contains(_currentUserId);

                  if (isIncoming && !alreadyRead) {
                    ChatService.instance.markMessageRead(
                      chatId: widget.chatId,
                      messageId: last.id,
                      userId: _currentUserId,
                    );
                  }
                } else if (snapshot.connectionState ==
                        ConnectionState.waiting &&
                    !snapshot.hasData) {
                  // first load
                  return const Center(child: CircularProgressIndicator());
                } else {
                  // no Firestore messages yet -> fall back to dummy (preview only)
                  messages =
                      chat_models.dummyMessagesByChatId[widget.chatId] ??
                      []; // 👈 updated
                }

                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet.\nSay hi and start the swap! 👋',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == _currentUserId;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          message.text,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(24)),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _handleSend,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
