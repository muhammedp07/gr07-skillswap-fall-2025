// lib/screens/profile/public_profile_screen.dart

import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import '../../services/user_service.dart';
import '../../services/review_service.dart';
import '../reviews/user_reviews_screen.dart';

class PublicProfileScreen extends StatelessWidget {
  final String userId;

  const PublicProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor:
            theme.appBarTheme.backgroundColor ?? theme.colorScheme.background,
        title: Text('Profile', style: theme.textTheme.titleLarge),
        iconTheme: theme.iconTheme,
      ),
      body: FutureBuilder<UserProfile?>(
        future: UserService().getUserProfile(userId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData) {
            return Center(
              child: Text('User not found', style: theme.textTheme.bodyMedium),
            );
          }

          final profile = snap.data!;

          return StreamBuilder<RatingSummary>(
            stream: ReviewService.instance.watchRatingForUser(profile.uid),
            builder: (context, ratingSnap) {
              final summary = ratingSnap.data;
              final hasReviews = summary != null && summary.count > 0;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundImage:
                              (profile.profileImageUrl != null &&
                                  profile.profileImageUrl!.isNotEmpty)
                              ? NetworkImage(profile.profileImageUrl!)
                              : null,
                          child:
                              (profile.profileImageUrl == null ||
                                  profile.profileImageUrl!.isEmpty)
                              ? Text(
                                  profile.name.isNotEmpty
                                      ? profile.name[0].toUpperCase()
                                      : '?',
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        color: theme.colorScheme.onSurface,
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
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                profile.major,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 14,
                                ),
                              ),
                              // Badges
                              if (profile.badges != null &&
                                  profile.badges!.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    if (profile.badges["helper"] == true)
                                      _badgeIcon(
                                        "Helper",
                                        Icons.volunteer_activism,
                                      ),

                                    if (profile.badges["topTeacher"] == true)
                                      _badgeIcon("Top Teacher", Icons.star),

                                    if (profile.badges["activeUser"] == true)
                                      _badgeIcon("Active User", Icons.bolt),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 8),
                              if (hasReviews)
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      color: theme.colorScheme.secondary,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      summary.average.toStringAsFixed(1),
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '(${summary.count} review${summary.count == 1 ? '' : 's'})',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(fontSize: 12),
                                    ),
                                  ],
                                )
                              else
                                Text(
                                  'No reviews yet',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    if ((profile.bio ?? '').isNotEmpty) ...[
                      Text(
                        'About',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        profile.bio!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    Text('Can Teach', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: profile.skillsTeachDisplay
                          .map(
                            (s) => Chip(
                              label: Text(s, style: theme.textTheme.bodySmall),
                              backgroundColor:
                                  theme.colorScheme.primaryContainer,
                            ),
                          )
                          .toList(),
                    ),

                    const SizedBox(height: 24),

                    Text('Wants to Learn', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: profile.skillsLearnDisplay
                          .map(
                            (s) => Chip(
                              label: Text(s, style: theme.textTheme.bodySmall),
                              backgroundColor:
                                  theme.colorScheme.secondaryContainer,
                            ),
                          )
                          .toList(),
                    ),

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => UserReviewsScreen(
                                userId: profile.uid,
                                userName: profile.name,
                              ),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: theme.colorScheme.primary),
                          foregroundColor: theme.colorScheme.primary,
                        ),
                        child: Text(
                          'View all reviews',
                          style: theme.textTheme.bodyMedium,
                        ),
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

  Widget _badgeIcon(String label, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
