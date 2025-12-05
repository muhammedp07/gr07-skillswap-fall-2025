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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        title: Text('Reviews for $userName', style: theme.appBarTheme.titleTextStyle),
        iconTheme: theme.iconTheme,
      ),
      body: StreamBuilder<List<Review>>(
        stream: ReviewService.instance.watchReviewsForUser(userId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final reviews = snap.data ?? [];

          if (reviews.isEmpty) {
            return Center(
              child: Text(
                'No reviews yet.',
                style: theme.textTheme.bodyMedium,
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reviews.length,
            separatorBuilder: (_, __) => Divider(color: theme.dividerColor),
            itemBuilder: (context, index) {
              final r = reviews[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    r.rating.toString(),
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                  ),
                ),
                title: Row(
                  children: [
                    ...List.generate(
                      r.rating,
                      (_) => const Icon(Icons.star, size: 16, color: Colors.amber),
                    ),
                    ...List.generate(
                      5 - r.rating,
                      (_) => Icon(
                        Icons.star_border,
                        size: 16,
                        color: theme.iconTheme.color?.withOpacity(0.24),
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
                        style: theme.textTheme.bodyMedium,
                      ),
                    const SizedBox(height: 4),
                    Text(
                      r.createdAt.toLocal().toString(),
                      style: theme.textTheme.bodySmall,
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
