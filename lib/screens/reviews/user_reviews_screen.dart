// lib/screens/reviews/user_reviews_screen.dart

import 'package:flutter/material.dart';

import '../../models/review.dart';
import '../../services/review_service.dart';

class UserReviewsScreen extends StatelessWidget {
  final String userId;
  final String userName;

  const UserReviewsScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1126),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1126),
        title: Text(
          'Reviews for $userName',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<Review>>(
        stream: ReviewService.instance.watchReviewsForUser(userId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final reviews = snap.data ?? [];

          if (reviews.isEmpty) {
            return const Center(
              child: Text(
                'No reviews yet.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reviews.length,
            separatorBuilder: (_, __) => const Divider(color: Colors.white10),
            itemBuilder: (context, index) {
              final r = reviews[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blueGrey.shade700,
                  child: Text(
                    r.rating.toString(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Row(
                  children: [
                    ...List.generate(
                      r.rating,
                      (_) =>
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                    ),
                    ...List.generate(
                      5 - r.rating,
                      (_) => const Icon(
                        Icons.star_border,
                        size: 16,
                        color: Colors.white24,
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (r.comment != null && r.comment!.isNotEmpty)
                      Text(
                        r.comment!,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      r.createdAt.toLocal().toString(),
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
