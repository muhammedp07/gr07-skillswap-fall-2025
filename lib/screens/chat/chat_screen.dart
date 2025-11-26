// lib/screens/chat/chat_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/chat_models.dart'
    as chat_models; // 👈 Chat + SwapStatus + dummy data
import '../../services/chat_service.dart';
import '../../services/review_service.dart'; // 👈 NEW

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
    return user?.uid ?? chat_models.dummyCurrentUserId;
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

  /// Open bottom sheet to rate + confirm swap completion.
  void _onMarkDonePressed(chat_models.Chat chat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF151936),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        int selectedRating = 5;
        final TextEditingController commentController = TextEditingController();
        bool isSaving = false;

        return StatefulBuilder(
          builder: (ctx, setModalState) {
            Future<void> handleSubmit() async {
              if (isSaving) return;

              setModalState(() => isSaving = true);

              try {
                // 1) Save review
                await ReviewService.instance.submitReview(
                  chatId: widget.chatId,
                  fromUserId: _currentUserId,
                  toUserId: widget.otherUserId,
                  rating: selectedRating,
                  comment: commentController.text,
                );

                // 2) Mark swap as completed on the chat
                await ChatService.instance.updateSwapStatus(
                  chatId: widget.chatId,
                  status: chat_models.SwapStatus.completed,
                  markedByUserId: _currentUserId,
                );

                if (!mounted) return;

                Navigator.of(ctx).pop(); // close bottom sheet

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Swap marked as done and review submitted.'),
                  ),
                );
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to submit review: $e')),
                  );
                }
              } finally {
                setModalState(() => isSaving = false);
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const Text(
                    'Mark swap as done',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "How was your experience with this swap?",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ⭐ Rating row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final value = index + 1;
                      final isSelected = value <= selectedRating;
                      return IconButton(
                        onPressed: () {
                          setModalState(() {
                            selectedRating = value;
                          });
                        },
                        icon: Icon(
                          isSelected ? Icons.star : Icons.star_border,
                          color: isSelected ? Colors.amber : Colors.grey,
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 8),

                  // Optional comment
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Leave a short comment (optional)',
                      hintStyle: const TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF11152B),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.white24,
                          width: 1,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: isSaving
                              ? null
                              : () => Navigator.of(ctx).pop(),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isSaving ? null : handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: isSaving
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Submit & mark done',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🧠 Outer stream: watch the chat itself for swapStatus changes
    return StreamBuilder<chat_models.Chat?>(
      stream: ChatService.instance.watchChat(widget.chatId),
      builder: (context, chatSnap) {
        final chat = chatSnap.data;
        final isCompleted =
            chat?.swapStatus == chat_models.SwapStatus.completed;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Chat'),
            actions: [
              if (chat != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 10.0,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isCompleted ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isCompleted
                              ? Icons.check_circle
                              : Icons.hourglass_top,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isCompleted ? 'Completed' : 'In progress',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (chat != null && !isCompleted)
                TextButton.icon(
                  onPressed: () => _onMarkDonePressed(chat),
                  icon: const Icon(Icons.check, color: Colors.white, size: 18),
                  label: const Text(
                    'Mark done',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: StreamBuilder<List<chat_models.ChatMessage>>(
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
                          [];
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
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
                              borderRadius: BorderRadius.all(
                                Radius.circular(24),
                              ),
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
      },
    );
  }
}
