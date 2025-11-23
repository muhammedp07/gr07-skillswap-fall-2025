// lib/screens/chat/chat_list_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/chat_models.dart';
import '../../services/chat_service.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Real Firebase user if available, otherwise fallback.
    final user = FirebaseAuth.instance.currentUser;
    final currentUserId = user?.uid ?? dummyCurrentUserId;

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: StreamBuilder<List<Chat>>(
        stream: ChatService.instance.watchChatsForUser(currentUserId),
        builder: (context, snapshot) {
          // If Firestore has chats, use them. Otherwise keep dummy ones.
          final chats = (snapshot.hasData && snapshot.data!.isNotEmpty)
              ? snapshot.data!
              : dummyChats;

          if (chats.isEmpty) {
            return const Center(
              child: Text(
                'No messages yet.\nStart a chat from a SkillSwap post!',
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.separated(
            itemCount: chats.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final chat = chats[index];

              final otherUserId = chat.memberIds.isNotEmpty
                  ? chat.memberIds.firstWhere(
                      (id) => id != currentUserId,
                      orElse: () => 'unknown_user',
                    )
                  : 'unknown_user';

              return ListTile(
                leading: CircleAvatar(
                  child: Text(otherUserId.substring(0, 1).toUpperCase()),
                ),
                title: Text('Chat with $otherUserId'),
                subtitle: Text(
                  chat.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  _formatTime(chat.lastMessageAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(chatId: chat.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),

      // TEMP BUTTON: create a test chat in Firestore so we can see real data
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Hard-coded test data for now.
          const testOtherUserId = 'test_user_2';
          const testPostId = 'test_post_1';

          final chatId = await ChatService.instance.createOrGetChatForPost(
            currentUserId: currentUserId,
            otherUserId: testOtherUserId,
            postId: testPostId,
          );

          if (!context.mounted) return;

          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => ChatScreen(chatId: chatId)));
        },
        child: const Icon(Icons.add_comment),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}
