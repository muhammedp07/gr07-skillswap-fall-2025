import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gr07_skillswap/screens/swap/schedule_swap_screen.dart';
import 'package:gr07_skillswap/screens/swap/scheduled_swaps_screen.dart';

import '../../models/chat_models.dart' as chat_models; // Chat + SwapStatus
import '../../models/notification_model.dart';
import '../../services/chat_service.dart';
import '../../services/notification_service.dart';
import '../../services/review_service.dart';
import '../../services/user_service.dart';
import '../../services/video_call_service.dart';
import '../profile/public_profile_screen.dart';
import '../video/video_call_screen.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();

  String get _currentUserId {
    final user = FirebaseAuth.instance.currentUser;
    // small fallback so chat still works if auth glitches
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

    // Get the current user's name from Firestore (not Firebase Auth displayName)
    String senderName = 'Someone';
    try {
      final userProfile = await UserService().getCurrentUserProfile();
      if (userProfile != null && userProfile.name.isNotEmpty) {
        senderName = userProfile.name;
      }
    } catch (e) {
      // Fall back to 'Someone' if profile fetch fails
    }

    await ChatService.instance.sendTextMessageAndNotify(
      chatId: widget.chatId,
      senderId: _currentUserId,
      senderName: senderName,
      recipientId: widget.otherUserId,
      text: text,
    );
  }

  /// Start (or reuse) a video call session for this chat and push the Zego call UI.
  /// Start (or reuse) a video call session for this chat and push the Zego call UI.
  Future<void> _handleStartCall() async {
    try {
      // 1) Create or reuse an active Firestore session
      final session = await VideoCallService.instance.createOrGetActiveSession(
        chatId: widget.chatId,
        hostUserId: _currentUserId,
      );

      if (!mounted) return;

      final user = FirebaseAuth.instance.currentUser;

      // 2) Make sure userName is NEVER empty (Zego asserts on this)
      String localUserName = (user?.displayName ?? '').trim();

      if (localUserName.isEmpty) {
        final emailPrefix = (user?.email ?? '').split('@').first;
        localUserName = emailPrefix.isNotEmpty ? emailPrefix : 'SkillSwap user';
      }

      // 3) Use session id as room/call id for now, but keep sdkRoomId hook
      String callId = (session.sdkRoomId ?? session.id).trim();
      if (callId.isEmpty) {
        callId = session.id;
      }

      // 4) Send an "incoming call" notification to the other user
      String callerName = 'Someone';
      try {
        final userProfile = await UserService().getCurrentUserProfile();
        if (userProfile != null && userProfile.name.isNotEmpty) {
          callerName = userProfile.name;
        }
      } catch (_) {
        // If profile lookup fails, fallback to 'Someone'
      }

      final notification = NotificationModel(
        id: '',
        fromUserId: _currentUserId,
        fromUserName: callerName,
        title: '$callerName is calling you',
        body: 'Tap to open your SkillSwap chat and join the video call.',
        type: NotificationType.incomingCall,
        timestamp: DateTime.now(),
        relatedId: widget.chatId, // so backend / navigation can use the chat
      );

      try {
        await NotificationService().sendNotification(
          widget.otherUserId,
          notification,
        );
      } catch (_) {
        // Don't block the call UI if notification fails
      }

      // 5) Navigate to the call UI for the caller
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoCallScreen(
            sessionId: session.id,
            callId: callId,
            localUserId: _currentUserId,
            localUserName: localUserName,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to start call: $e')));
    }
  }

  /// Show confirmation dialog to delete the entire chat thread
  Future<void> _confirmDeleteChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Chat'),
        content: const Text(
          'Are you sure you want to delete this entire conversation? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ChatService.instance.deleteChat(widget.chatId);
        if (mounted) {
          Navigator.of(context).pop(); // Go back to chat list
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chat deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to delete chat: $e')));
        }
      }
    }
  }

  /// Show confirmation dialog to delete a single message
  Future<void> _confirmDeleteMessage(chat_models.ChatMessage message) async {
    // Only allow users to delete their own messages
    if (message.senderId != _currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only delete your own messages')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ChatService.instance.deleteMessage(
          chatId: widget.chatId,
          messageId: message.id,
        );
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Message deleted')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete message: $e')),
          );
        }
      }
    }
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
                await ReviewService.instance.submitReview(
                  chatId: widget.chatId,
                  fromUserId: _currentUserId,
                  toUserId: widget.otherUserId,
                  rating: selectedRating,
                  comment: commentController.text,
                );

                await ChatService.instance.updateSwapStatus(
                  chatId: widget.chatId,
                  status: chat_models.SwapStatus.completed,
                  markedByUserId: _currentUserId,
                );

                // 3) Send notification to other user to leave a review
                String senderName = 'Someone';
                try {
                  final userProfile = await UserService()
                      .getCurrentUserProfile();
                  if (userProfile != null && userProfile.name.isNotEmpty) {
                    senderName = userProfile.name;
                  }
                } catch (_) {}

                final notification = NotificationModel(
                  id: '',
                  fromUserId: _currentUserId,
                  fromUserName: senderName,
                  title: 'Swap Completed!',
                  body:
                      '$senderName marked your swap as complete. Leave a review!',
                  type: NotificationType.swapCompleted,
                  timestamp: DateTime.now(),
                  relatedId: widget.chatId,
                );

                try {
                  await NotificationService().sendNotification(
                    widget.otherUserId,
                    notification,
                  );
                } catch (_) {
                  // Don't fail the whole operation if notification fails
                }

                if (!mounted) return;

                Navigator.of(ctx).pop();
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
    return StreamBuilder<chat_models.Chat?>(
      stream: ChatService.instance.watchChat(widget.chatId),
      builder: (context, chatSnap) {
        final chat = chatSnap.data;
        final isCompleted =
            chat?.swapStatus == chat_models.SwapStatus.completed;

        return Scaffold(
          appBar: AppBar(
            title: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        PublicProfileScreen(userId: widget.otherUserId),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (chat != null)
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompleted ? Colors.green : Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isCompleted ? 'Completed' : 'In progress',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.videocam),
                onPressed: _handleStartCall,
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                itemBuilder: (context) => [
                  // Scheduling options
                  const PopupMenuItem(
                    value: 'schedule',
                    child: Row(
                      children: [
                        Icon(Icons.schedule, color: Colors.blue),
                        SizedBox(width: 12),
                        Text('Schedule Swap'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'view_schedules',
                    child: Row(
                      children: [
                        Icon(Icons.list, color: Colors.blue),
                        SizedBox(width: 12),
                        Text('View Scheduled Swaps'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  if (chat != null && !isCompleted)
                    const PopupMenuItem(
                      value: 'mark_done',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 12),
                          Text('Mark as Done'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'delete_chat',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Delete Chat'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'schedule') {
                    _navigateToScheduleSwap();
                  } else if (value == 'view_schedules') {
                    _navigateToScheduledSwaps();
                  } else if (value == 'mark_done' && chat != null) {
                    _onMarkDonePressed(chat);
                  } else if (value == 'delete_chat') {
                    _confirmDeleteChat();
                  }
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: StreamBuilder<List<chat_models.ChatMessage>>(
                  stream: ChatService.instance.watchMessages(widget.chatId),
                  builder: (context, snapshot) {
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
                      return const Center(child: CircularProgressIndicator());
                    } else {
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
                          child: GestureDetector(
                            onLongPress: isMe
                                ? () => _confirmDeleteMessage(message)
                                : null,
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

  void _navigateToScheduleSwap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScheduleSwapScreen(
          postId: 'from_chat_${widget.chatId}',
          chatId: widget.chatId,
          otherUserId: widget.otherUserId,
          otherUserName: widget.otherUserName,
        ),
      ),
    );
  }

  void _navigateToScheduledSwaps() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScheduledSwapsScreen(
          chatId: widget.chatId,
          otherUserId: widget.otherUserId,
          otherUserName: widget.otherUserName,
        ),
      ),
    );
  }
}
