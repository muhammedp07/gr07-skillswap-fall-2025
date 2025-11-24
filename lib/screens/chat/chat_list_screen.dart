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

                // Use Firestore chats if they exist, otherwise fall back to dummy data
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

                    // ---------- Find OTHER user id safely ----------
                    String? otherUserId;

                    if (chat.members.isNotEmpty) {
                      // Try to pick member that is NOT the current user
                      try {
                        otherUserId = chat.members.firstWhere(
                          (m) => m != currentUserId,
                          orElse: () => '',
                        );
                        if (otherUserId.isEmpty) {
                          // if all members equal current user (weird older chat),
                          // fall back to the first member
                          otherUserId = chat.members.first;
                        }
                      } catch (_) {
                        // If something goes wrong, just fall back to first member
                        otherUserId = chat.members.first;
                      }
                    }

                    // If we STILL don't have an id, show an "unknown" tile
                    if (otherUserId == null || otherUserId.isEmpty) {
                      return _buildChatTile(
                        context: context,
                        chat: chat,
                        displayName: 'Unknown user',
                        avatarLetter: 'U',
                        otherUserId: '', // nothing to navigate with
                      );
                    }

                    // ---------- Look up that user in Firestore ----------
                    return FutureBuilder<UserProfile?>(
                      future: userService.getUserProfile(otherUserId),
                      builder: (context, userSnap) {
                        String displayName = 'Unknown user';

                        if (userSnap.hasData && userSnap.data != null) {
                          displayName = userSnap.data!.name;
                        }

                        final avatarLetter = displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : 'U';

                        return _buildChatTile(
                          context: context,
                          chat: chat,
                          displayName: displayName,
                          avatarLetter: avatarLetter,
                          otherUserId: otherUserId!,
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
    required String otherUserId,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.deepPurple,
        child: Text(avatarLetter, style: const TextStyle(color: Colors.white)),
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
      trailing: Text(
        _formatTime(chat.lastMessageAt),
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: Colors.white60),
      ),
      onTap: () {
        if (otherUserId.isEmpty) return; // nothing sensible to open

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              chatId: chat.id,
              otherUserId: otherUserId, // 👈 the one we calculated above
            ),
          ),
        );
      },
    );
  }
}
