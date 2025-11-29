// lib/screens/feed/post_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/post.dart';
import '../../services/chat_service.dart';
import '../chat/chat_screen.dart';
import '../../models/user_profile.dart';
import '../../services/user_service.dart';
import '../../services/review_service.dart'; // ⭐ NEW
import '../profile/public_profile_screen.dart'; // ⭐ NEW
import '../reviews/user_reviews_screen.dart'; // ⭐ NEW

class PostDetailScreen extends StatelessWidget {
  final Post post;

  const PostDetailScreen({super.key, required this.post});

  String _buildMainSkill() {
    // Use first teach skill as the "title", or fall back to a generic label
    if (post.skillsTeach.isNotEmpty) {
      return post.skillsTeach.first.displaySkill;
    }
    if (post.skillsLearn.isNotEmpty) {
      return post.skillsLearn.first.displaySkill;
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
          builder: (_) => ChatScreen(chatId: chatId, otherUserId: post.userId, otherUserName: post.userName),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to open chat: $e')));
    }
  }

  void _openProfile(BuildContext context, String userId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PublicProfileScreen(userId: userId)),
    );
  }

  void _openReviews(
    BuildContext context, {
    required String userId,
    required String userName,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserReviewsScreen(userId: userId, userName: userName),
      ),
    );
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
                  // 🔹 Header: profile + rating + navigation
                  FutureBuilder<UserProfile?>(
                    future: UserService().getUserProfile(post.userId),
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        // skeleton placeholder
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

                      final profile = snap.data!;

                      return StreamBuilder<RatingSummary>(
                        stream: ReviewService.instance.watchRatingForUser(
                          profile.uid,
                        ),
                        builder: (context, ratingSnap) {
                          final summary = ratingSnap.data;

                          // Whole header taps → profile
                          return GestureDetector(
                            onTap: () => _openProfile(context, profile.uid),
                            child: _buildUserHeader(
                              context,
                              post,
                              profile,
                              summary,
                            ),
                          );
                        },
                      );
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
                      ...post.skillsTeach.map(
                        (skill) => _buildPillChip(
                          label: 'Offers: ${skill.displaySkill}',
                          background: const Color(0xFF1F2A5A),
                        ),
                      ),
                      ...post.skillsLearn.map(
                        (skill) => _buildPillChip(
                          label: 'Wants: ${skill.displaySkill}',
                          background: const Color(0xFF264C5E),
                        ),
                      ),
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

  // 🔹 Header: avatar + name + major + rating summary (clickable reviews)
  Widget _buildUserHeader(
    BuildContext context,
    Post post,
    UserProfile profile,
    RatingSummary? summary,
  ) {
    final hasReviews = summary != null && summary.count > 0;

    Widget ratingWidget;
    if (hasReviews) {
      ratingWidget = InkWell(
        // 👇 tap on rating row → reviews screen
        onTap: () =>
            _openReviews(context, userId: profile.uid, userName: profile.name),
        child: Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 18),
            const SizedBox(width: 4),
            Text(
              summary!.average.toStringAsFixed(1),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(${summary.count} review${summary.count == 1 ? '' : 's'})',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      );
    } else {
      ratingWidget = InkWell(
        onTap: () =>
            _openReviews(context, userId: profile.uid, userName: profile.name),
        child: const Text(
          'No reviews yet',
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
      );
    }

    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundImage:
              (profile.profileImageUrl != null &&
                  profile.profileImageUrl!.isNotEmpty)
              ? NetworkImage(profile.profileImageUrl!)
              : null,
          child:
              (profile.profileImageUrl == null ||
                  profile.profileImageUrl!.isEmpty)
              ? Text(
                  profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 28, color: Colors.white),
                )
              : null,
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              profile.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              profile.major,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const Text(
              "Member since 2023",
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 6),
            ratingWidget,
          ],
        ),
      ],
    );
  }
}
