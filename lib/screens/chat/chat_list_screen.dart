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

    return Scaffold(
      backgroundColor: const Color(0xFF0E1126),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              'Messages',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Messages',
              style: TextStyle(color: Colors.white70, fontSize: 16),
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
                        style: const TextStyle(color: Colors.redAccent),
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
                  return const Center(
                    child: Text(
                      "No conversations yet.\nTap Message on a SkillSwap post to start one!",
                      style: TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: chats.length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: Colors.white12, height: 1),
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
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.chat_bubble_outline),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Start a chat by tapping Message on a SkillSwap post.',
              ),
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
        backgroundColor: Colors.deepPurple,
        backgroundImage: profileImageUrl != null && profileImageUrl.isNotEmpty
            ? NetworkImage(profileImageUrl)
            : null,
        child: (profileImageUrl == null || profileImageUrl.isEmpty)
            ? Text(avatarLetter, style: const TextStyle(color: Colors.white))
            : null,
      ),
      title: Text(
        'Chat with $displayName',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        chat.lastMessage.isEmpty ? 'No messages yet' : chat.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white70, fontSize: 13),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _formatTime(chat.lastMessageAt),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.white60),
          ),
          if (hasUnread) ...[
            const SizedBox(height: 4),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                ChatScreen(chatId: chat.id, otherUserId: otherUserId),
          ),
        );
      },
    );
  }
}
