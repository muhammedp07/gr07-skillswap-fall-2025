import 'dart:io';

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
import '../video/video_call_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

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

  final ImagePicker _imagePicker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;

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

  Future<String> _getCurrentUserName() async {
    try {
      final userProfile = await UserService().getCurrentUserProfile();
      if (userProfile != null && userProfile.name.isNotEmpty) {
        return userProfile.name;
      }
    } catch (_) {}
    final user = FirebaseAuth.instance.currentUser;
    final emailPrefix = (user?.email ?? '').split('@').first;
    return emailPrefix.isNotEmpty ? emailPrefix : 'Someone';
  }

  Future<void> _pickAndSendImage() async {
    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    // Upload to Firebase Storage
    final ref = _storage.ref().child(
      'chat_images/${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    final uploadTask = await ref.putFile(File(image.path));
    final downloadUrl = await uploadTask.ref.getDownloadURL();

    final senderName = await _getCurrentUserName();

    // Send as special message
    await ChatService.instance.sendTextMessageAndNotify(
      chatId: widget.chatId,
      senderId: _currentUserId,
      senderName: senderName,
      recipientId: widget.otherUserId,
      text: '[Image]',
      attachmentUrl: downloadUrl,
      attachmentType: 'image',
    );
  }

  Future<void> _pickAndSendFile() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: false);
    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    final path = file.path;
    if (path == null) return;

    final fileName = file.name;
    final ref = _storage.ref().child(
      'chat_files/${DateTime.now().millisecondsSinceEpoch}_$fileName',
    );

    final uploadTask = await ref.putFile(File(path));
    final downloadUrl = await uploadTask.ref.getDownloadURL();

    final senderName = await _getCurrentUserName();

    await ChatService.instance.sendTextMessageAndNotify(
      chatId: widget.chatId,
      senderId: _currentUserId,
      senderName: senderName,
      recipientId: widget.otherUserId,
      text: fileName,
      attachmentUrl: downloadUrl,
      attachmentType: 'file',
    );
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
      // no attachment for plain text
    );
  }

  /// Start (or reuse) a video call session for this chat and push the Zego call UI.
  Future<void> _handleStartCall() async {
    try {
      // create or reuse active Firestore session
      final session = await VideoCallService.instance.createOrGetActiveSession(
        chatId: widget.chatId,
        hostUserId: _currentUserId,
      );

      if (!mounted) return;

      final user = FirebaseAuth.instance.currentUser;

      // make sure userName is NEVER empty (Zego asserts on this)
      String localUserName = (user?.displayName ?? '').trim();

      if (localUserName.isEmpty) {
        final emailPrefix = (user?.email ?? '').split('@').first;
        localUserName = emailPrefix.isNotEmpty ? emailPrefix : 'SkillSwap user';
      }

      // use session id as room/call id for now, but keep sdkRoomId hook
      String callId = (session.sdkRoomId ?? session.id).trim();
      if (callId.isEmpty) {
        callId = session.id;
      }

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

  // Enhanced delete confirmation dialog
  void _confirmDeleteChat() async {
    final theme = Theme.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Conversation', style: theme.textTheme.titleMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This will permanently delete:', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text('• All messages', style: theme.textTheme.bodySmall),
            Text('• Swap history', style: theme.textTheme.bodySmall),
            Text('• Scheduled sessions', style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            Text('This action cannot be undone.', style: theme.textTheme.bodyMedium),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: theme.textTheme.bodyMedium),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
            child: Text('Delete Forever'),
          ),
        ],
      ),
    );

    if (result == true) {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(color: theme.colorScheme.primary),
              const SizedBox(width: 16),
              Text('Deleting chat...', style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      );

      try {
        await ChatService.instance.deleteChat(widget.chatId);
        Navigator.of(context)
          ..pop() // Close loading dialog
          ..pop(); // Go back to chat list

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chat deleted successfully', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onPrimary)),
            backgroundColor: theme.colorScheme.primary,
          ),
        );
      } catch (e) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete chat: $e', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onError)),
            backgroundColor: theme.colorScheme.error,
          ),
        );
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
      backgroundColor: Theme.of(context).dialogBackgroundColor,
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

                String senderName = 'Someone';
                try {
                  final userProfile = await UserService().getCurrentUserProfile();
                  if (userProfile != null && userProfile.name.isNotEmpty) {
                    senderName = userProfile.name;
                  }
                } catch (_) {}

                final notification = NotificationModel(
                  id: '',
                  fromUserId: _currentUserId,
                  fromUserName: senderName,
                  title: 'Swap Completed!',
                  body: '$senderName marked your swap as complete. Leave a review!',
                  type: NotificationType.swapCompleted,
                  timestamp: DateTime.now(),
                  relatedId: widget.chatId,
                );

                try {
                  await NotificationService().sendNotification(widget.otherUserId, notification);
                } catch (_) {}

                if (!mounted) return;

                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Swap marked as done and review submitted.')),
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

            final theme = Theme.of(ctx);
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
                        color: theme.dividerColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Text(
                    'Mark swap as done',
                    style: theme.textTheme.titleMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "How was your experience with this swap?",
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14),
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
                          color: isSelected ? theme.colorScheme.secondary : theme.disabledColor,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    style: theme.textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Leave a short comment (optional)',
                      hintStyle: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                      filled: true,
                      fillColor: theme.cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.dividerColor,
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
                          onPressed: isSaving ? null : () => Navigator.of(ctx).pop(),
                          child: Text('Cancel', style: theme.textTheme.bodyMedium),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isSaving ? null : handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: isSaving
                              ? SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(theme.colorScheme.onPrimary),
                                  ),
                                )
                              : Text('Submit & mark done', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
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

  Widget _buildMessageContent(chat_models.ChatMessage message) {
    if (message.attachmentUrl != null && message.attachmentUrl!.isNotEmpty) {
      // Image attachment
      if (message.attachmentType == 'image') {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: Image.network(message.attachmentUrl!, fit: BoxFit.cover),
            ),
            if (message.text.isNotEmpty && message.text != '[Image]')
              Text(message.text, style: const TextStyle(color: Colors.white)),
          ],
        );
      }

      // File attachment (non-image)
      if (message.attachmentType == 'file') {
        final fileName = message.text.isNotEmpty ? message.text : 'Attachment';
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insert_drive_file, color: Colors.white),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                fileName,
                style: const TextStyle(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.open_in_new, color: Colors.white),
              onPressed: () async {
                final uri = Uri.tryParse(message.attachmentUrl!);
                if (uri != null) {
                  try {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } catch (_) {}
                }
              },
            ),
          ],
        );
      }

      // Fallback: try to show preview (image) or link
      final theme = Theme.of(context);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: Image.network(message.attachmentUrl!, fit: BoxFit.cover),
          ),
          if (message.text.isNotEmpty) Text(message.text, style: theme.textTheme.bodyMedium),
        ],
      );
    }

    return Text(message.text, style: const TextStyle(color: Colors.white));
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
            title: Row(
              children: [
                CircleAvatar(radius: 16, backgroundColor: Theme.of(context).colorScheme.primary, child: Text(widget.otherUserName[0], style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.onPrimary))),
                const SizedBox(width: 12),
                Text(
                  widget.otherUserName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.videocam, color: Theme.of(context).iconTheme.color),
                onPressed: _handleStartCall,
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Theme.of(context).iconTheme.color),
                itemBuilder: (context) => [
                  // Scheduling options
                  PopupMenuItem(
                    value: 'schedule',
                    child: Row(
                      children: [
                        Icon(Icons.schedule, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        Text('Schedule Swap', style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'view_schedules',
                    child: Row(
                      children: [
                        Icon(Icons.list, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        Text('View Scheduled Swaps', style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  if (chat != null && !isCompleted)
                    PopupMenuItem(
                      value: 'mark_done',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Theme.of(context).colorScheme.secondary),
                          const SizedBox(width: 12),
                          Text('Mark as Done', style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: 'delete_chat',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                        const SizedBox(width: 12),
                        Text('Delete Chat', style: Theme.of(context).textTheme.bodyMedium),
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
                      return Center(
                        child: Text(
                          'No messages yet.\nSay hi and start the swap! 👋',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
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
                                    : Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: _buildMessageContent(message),
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
                           child: Builder(builder: (ctx) {
                               final theme = Theme.of(ctx);
                               return TextField(
                                 controller: _controller,
                                 minLines: 1,
                                 maxLines: 5,
                                 decoration: InputDecoration(
                                   hintText: 'Type a message...',
                                   hintStyle: theme.textTheme.bodySmall,
                                   filled: true,
                                   fillColor: theme.colorScheme.surface,
                                   border: OutlineInputBorder(
                                     borderRadius: BorderRadius.circular(24),
                                     borderSide: BorderSide.none,
                                   ),
                                   contentPadding: const EdgeInsets.symmetric(
                                     horizontal: 16,
                                     vertical: 8,
                                   ),
                                 ),
                               );
                             }),
                      ),
                      const SizedBox(width: 8),
                           // Attachment button
                           IconButton(
                             icon: Icon(Icons.attach_file, color: Theme.of(context).iconTheme.color),
                             onPressed: () {
                               showModalBottomSheet(
                                 context: context,
                                 builder: (ctx) => SafeArea(
                                   child: Wrap(
                                     children: [
                                       ListTile(
                                         leading: Icon(Icons.photo, color: Theme.of(ctx).iconTheme.color),
                                         title: Text('Image', style: Theme.of(ctx).textTheme.bodyMedium),
                                         onTap: () {
                                           Navigator.of(ctx).pop();
                                           _pickAndSendImage();
                                         },
                                       ),
                                       ListTile(
                                         leading: Icon(Icons.insert_drive_file, color: Theme.of(ctx).iconTheme.color),
                                         title: Text('File', style: Theme.of(ctx).textTheme.bodyMedium),
                                         onTap: () {
                                           Navigator.of(ctx).pop();
                                           _pickAndSendFile();
                                         },
                                       ),
                                     ],
                                   ),
                                 ),
                               );
                             },
                           ),
                           IconButton(
                             icon: Icon(Icons.send, color: Theme.of(context).iconTheme.color),
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
