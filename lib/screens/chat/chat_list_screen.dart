// lib/screens/chat/chat_list_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/chat_models.dart';
import '../../models/user_profile.dart';
import '../../services/chat_service.dart';
import '../../services/user_service.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final currentUserId = user?.uid ?? dummyCurrentUserId;
    final userService = UserService();

    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Your conversations',
              style: theme.textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<List<Chat>>(
              stream: ChatService.instance.watchChatsForUser(currentUserId),
              builder: (context, snapshot) {
                // ERROR HANDLING
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Error loading messages:\n${snapshot.error}',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final firestoreChats = snapshot.data ?? [];
                final chats = firestoreChats.isNotEmpty
                    ? firestoreChats
                    : dummyChats;

                if (chats.isEmpty) {
                  return Center(
                    child: Text(
                      "No conversations yet.\nTap Message on a SkillSwap post to start one!",
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: chats.length,
                  separatorBuilder: (_, __) => Divider(color: theme.dividerColor, height: 1),
                  itemBuilder: (context, index) {
                    final chat = chats[index];

                    // --------- Find OTHER user id safely ----------
                    String? otherUserId;

                    if (chat.members.isNotEmpty) {
                      try {
                        otherUserId = chat.members.firstWhere(
                          (m) => m != currentUserId,
                          orElse: () => '',
                        );
                        if (otherUserId.isEmpty) {
                          otherUserId = chat.members.first;
                        }
                      } catch (_) {
                        otherUserId = chat.members.first;
                      }
                    }

                    if (otherUserId == null || otherUserId.isEmpty) {
                      // Fallback tile if weird data
                      return _buildChatTile(
                        context: context,
                        chat: chat,
                        displayName: 'Unknown user',
                        avatarLetter: 'U',
                        profileImageUrl: null,
                        hasUnread: false,
                        otherUserId: 'unknown_user',
                      );
                    }

                    // --------- Look up that user in Firestore ----------
                    return FutureBuilder<UserProfile?>(
                      future: userService.getUserProfile(otherUserId),
                      builder: (context, userSnap) {
                        String displayName = 'Unknown user';
                        String? profileImageUrl;

                        if (userSnap.hasData && userSnap.data != null) {
                          displayName = userSnap.data!.name;
                          profileImageUrl = userSnap.data!.profileImageUrl;
                        }

                        final avatarLetter = displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : 'U';

                        // --------- Watch last message for unread dot ----------
                        return StreamBuilder<ChatMessage?>(
                          stream: ChatService.instance.watchLastMessage(
                            chat.id,
                          ),
                          builder: (context, lastMsgSnap) {
                            final lastMessage = lastMsgSnap.data;

                            final hasUnread =
                                lastMessage != null &&
                                lastMessage.senderId != currentUserId &&
                                !lastMessage.readBy.contains(currentUserId);

                            return _buildChatTile(
                              context: context,
                              chat: chat,
                              displayName: displayName,
                              avatarLetter: avatarLetter,
                              profileImageUrl: profileImageUrl,
                              hasUnread: hasUnread,
                              otherUserId: otherUserId!,
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: theme.colorScheme.primary,
        child: Icon(Icons.chat_bubble_outline, color: theme.colorScheme.onPrimary),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Start a chat by tapping Message on a SkillSwap post.', style: theme.textTheme.bodyMedium),
            ),
          );
        },
      ),
    );
  }

  // Reusable tile builder
  Widget _buildChatTile({
    required BuildContext context,
    required Chat chat,
    required String displayName,
    required String avatarLetter,
    required String? profileImageUrl,
    required bool hasUnread,
    required String otherUserId,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        backgroundImage: profileImageUrl != null && profileImageUrl.isNotEmpty
            ? NetworkImage(profileImageUrl)
            : null,
        child: (profileImageUrl == null || profileImageUrl.isEmpty)
            ? Text(avatarLetter, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.onPrimary))
            : null,
      ),
      title: Text(
        'Chat with $displayName',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        chat.lastMessage.isEmpty ? 'No messages yet' : chat.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _formatTime(chat.lastMessageAt),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.8)),
          ),
          if (hasUnread) ...[
            const SizedBox(height: 4),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              chatId: chat.id,
              otherUserId: otherUserId,
              otherUserName: displayName, // Pass the actual display name
            ),
          ),
        );
      },
    );
  }
}
