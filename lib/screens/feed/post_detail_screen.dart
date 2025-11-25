// lib/screens/feed/post_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/post.dart';
import '../../services/chat_service.dart';
import '../chat/chat_screen.dart';
import '../../models/user_profile.dart';
import '../../services/user_service.dart';

class PostDetailScreen extends StatelessWidget {
  final Post post;

  const PostDetailScreen({super.key, required this.post});

  String _buildMainSkill() {
    // Use first teach skill as the “title”, or fall back to a generic label
    if (post.skillsTeach.isNotEmpty) {
      return post.skillsTeach.first;
    }
    if (post.skillsLearn.isNotEmpty) {
      return post.skillsLearn.first;
    }
    return 'Skill Swap';
  }

  Future<void> _startChatFromDetail(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Prevent messaging your own post
    if (post.userId == currentUser.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You can't message your own post.")),
      );
      return;
    }

    try {
      final chatId = await ChatService.instance.createOrGetChatForPost(
        currentUserId: currentUser.uid,
        otherUserId: post.userId,
        postId: post.id,
      );

      if (!context.mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(chatId: chatId, otherUserId: post.userId),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to open chat: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final mainSkill = _buildMainSkill();

    return Scaffold(
      backgroundColor: const Color(0xFF0E1126),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1126),
        elevation: 0,
        title: const Text(
          'Swap Details',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔹 Large header card with profile info
                  FutureBuilder<UserProfile?>(
                    future: UserService().getUserProfile(post.userId),
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        // Little skeleton placeholder so it doesn’t jump
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF151936),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: 32,
                                backgroundColor: Colors.blueGrey,
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 140,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: Colors.white12,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: 100,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: Colors.white10,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }

                      return _buildUserHeader(post, snap.data!);
                    },
                  ),

                  const SizedBox(height: 24),

                  // Big “main skill” card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF151936),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      mainSkill,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Chips row: Offers / Wants / Availability
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      // Offers (Can Teach)
                      ...post.skillsTeach.map(
                        (skill) => _buildPillChip(
                          label: 'Offers: $skill',
                          background: const Color(0xFF1F2A5A),
                        ),
                      ),

                      // Wants (Wants to Learn)
                      ...post.skillsLearn.map(
                        (skill) => _buildPillChip(
                          label: 'Wants: $skill',
                          background: const Color(0xFF264C5E),
                        ),
                      ),

                      // Availability, if present
                      if (post.availability != null &&
                          post.availability!.isNotEmpty)
                        _buildPillChip(
                          label: 'Availability: ${post.availability!}',
                          background: const Color(0xFF2F2345),
                        ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    (post.description != null &&
                            post.description!.trim().isNotEmpty)
                        ? post.description!
                        : 'No description added yet.',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom “Message” button
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              color: const Color(0xFF0E1126),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _startChatFromDetail(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    'Message ${post.userName.split(' ').first}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillChip({required String label, required Color background}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 13),
      ),
    );
  }

  // 🔹 Premium-style header container
  Widget _buildUserHeader(Post post, UserProfile profile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF20254A), Color(0xFF151936)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 32,
            backgroundImage:
                (profile.profileImageUrl != null &&
                    profile.profileImageUrl!.isNotEmpty)
                ? NetworkImage(profile.profileImageUrl!)
                : null,
            backgroundColor: const Color(0xFF2F3E86),
            child:
                (profile.profileImageUrl == null ||
                    profile.profileImageUrl!.isEmpty)
                ? Text(
                    profile.name.isNotEmpty
                        ? profile.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 28,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.major,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Member since 2023",
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
