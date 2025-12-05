import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gr07_skillswap/services/bookmark_service.dart';
import '../../models/post.dart';
import '../../models/user_profile.dart';
import '../../services/post_service.dart';
import '../../services/user_service.dart';

import 'post_detail_screen.dart';

import '../../services/chat_service.dart';
import '../chat/chat_screen.dart';

class FeedScreen extends StatefulWidget {
  final Function(int)? onTabChange;

  const FeedScreen({super.key, this.onTabChange});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final TextEditingController _searchController = TextEditingController();
  final PostService _postService = PostService();
  final UserService _userService = UserService();
  final ChatService _chatService = ChatService.instance;
  final BookmarkService _bookmarkService = BookmarkService();

  String _searchQuery = '';
  String _selectedFilter = 'all';
  // ignore: unused_field
  List<String> _availableSkills = [];
  UserProfile? _currentUserProfile;

  StreamSubscription<UserProfile?>? _profileSubscription;

  @override
  void initState() {
    super.initState();
    _loadAvailableSkills();
    _setupProfileStream();
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _loadAvailableSkills() {
    _availableSkills = [
      "Python",
      "Java",
      "C++",
      "Web Development",
      "UI/UX",
      "Flutter",
      "Cooking",
      "Photography",
      "Painting",
      "Music",
      "Editing",
      "Data Analysis",
      "Public Speaking",
    ];
  }

  void _setupProfileStream() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    UserProfile? previousProfile;

    _profileSubscription = _userService
        .getUserProfileStream(currentUser.uid)
        .listen(
          (userProfile) {
            if (mounted) {
              setState(() {
                // Track changes before updating
                final hadPreviousProfile = _currentUserProfile != null;
                _updateMatchTracking(userProfile, _currentUserProfile);
                previousProfile = _currentUserProfile;
                _currentUserProfile = userProfile;

                // Show notification if this is an update (not initial load)
                if (hadPreviousProfile && userProfile != null) {
                  _showProfileUpdateNotification(userProfile, previousProfile!);
                }
              });
            }
          },
          onError: (error) {
            print('Error in profile stream: $error');
          },
        );
  }

  // NEW: Show notification when profile update affects matches
  void _showProfileUpdateNotification(
    UserProfile newProfile,
    UserProfile oldProfile,
  ) {
    final newTeachSkills = newProfile.skillsTeachSimple.toSet();
    final oldTeachSkills = oldProfile.skillsTeachSimple.toSet();
    final newLearnSkills = newProfile.skillsLearnSimple.toSet();
    final oldLearnSkills = oldProfile.skillsLearnSimple.toSet();

    final teachSkillsAdded = newTeachSkills.difference(oldTeachSkills);
    final learnSkillsAdded = newLearnSkills.difference(oldLearnSkills);

    if (teachSkillsAdded.isNotEmpty || learnSkillsAdded.isNotEmpty) {
      final skillCount = teachSkillsAdded.length + learnSkillsAdded.length;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Profile updated! Found new matches with $skillCount new skill${skillCount > 1 ? 's' : ''}',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                // Optional: Scroll to top or highlight new matches
              },
            ),
          ),
        );
      });
    }
  }

  // New method to calculate comprehensive match score
  double _calculateComprehensiveMatchScore(Post post) {
    if (_currentUserProfile == null) return 0.0;

    double score = 0.0;

    // Perfect matches (user can teach what post wants to learn)
    for (final skill in post.skillsLearn) {
      if (_currentUserProfile!.skillsTeachSimple.any((s) => s == skill)) {
        score += 2.0; // High weight for perfect matches
      }
    }

    // Perfect matches (user wants to learn what post can teach)
    for (final skill in post.skillsTeach) {
      if (_currentUserProfile!.skillsLearnSimple.any((s) => s == skill)) {
        score += 2.0; // High weight for perfect matches
      }
    }

    // Category-based matches (lower weight)
    final userTeachCategories = _currentUserProfile!.skillsTeach
        .map((s) => s.category)
        .toSet();
    final userLearnCategories = _currentUserProfile!.skillsLearn
        .map((s) => s.category)
        .toSet();

    for (final skill in post.skillsLearn) {
      if (userTeachCategories.contains(skill.category)) {
        score += 0.5; // Same category but different skill
      }
    }

    for (final skill in post.skillsTeach) {
      if (userLearnCategories.contains(skill.category)) {
        score += 0.5; // Same category but different skill
      }
    }

    return score;
  }

  // New method to sort posts by relevance
  List<Post> _sortPostsByRelevance(List<Post> posts) {
    if (_currentUserProfile == null) return posts;

    final scoredPosts = posts.map((post) {
      return {
        'post': post,
        'score': _calculateComprehensiveMatchScore(post),
        'isPerfectMatch': _calculateMatchScore(post) > 0,
      };
    }).toList();

    // Sort by: perfect matches first, then by score, then by timestamp
    scoredPosts.sort((a, b) {
      final aPerfect = a['isPerfectMatch'] as bool;
      final bPerfect = b['isPerfectMatch'] as bool;

      if (aPerfect && !bPerfect) return -1;
      if (!aPerfect && bPerfect) return 1;

      final aScore = a['score'] as double;
      final bScore = b['score'] as double;

      if (aScore != bScore) return bScore.compareTo(aScore);

      // Fall back to recent posts
      final aPost = a['post'] as Post;
      final bPost = b['post'] as Post;
      return bPost.createdAt.compareTo(aPost.createdAt);
    });

    return scoredPosts.map((item) => item['post'] as Post).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(),

          // Filter Section (only main filters now)
          _buildFilterSection(),

          // Posts List (smart sorting happens internally)
          Expanded(child: _buildPostsList()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        style: theme.textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: "Search skills, names, majors...",
          hintStyle: theme.textTheme.bodySmall,
          prefixIcon: Icon(Icons.search, color: theme.iconTheme.color),
          filled: true,
          fillColor: theme.colorScheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 0,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildMainFilterChip('All Posts', 'all'),
          _buildMainFilterChip('I Want to Learn', 'learn'),
          _buildMainFilterChip('I Can Teach', 'teach'),
        ],
      ),
    );
  }

  Widget _buildMainFilterChip(String label, String value) {
    return StreamBuilder<List<Post>>(
      stream: _postService.getPostsStream(),
      builder: (context, snapshot) {
        int matchCount = 0;

        if (snapshot.hasData && _currentUserProfile != null) {
          final posts = snapshot.data!;
          matchCount = _calculateFilterMatchCount(posts, value);
        }

        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.only(right: 8.0, top: 8.0),
          child: ChoiceChip(
            label: matchCount > 0 ? Text('$label ($matchCount)') : Text(label),
            labelStyle: TextStyle(
              color: _selectedFilter == value ? theme.colorScheme.onPrimary : theme.textTheme.bodySmall?.color,
            ),
            selected: _selectedFilter == value,
            onSelected: (selected) {
              setState(() {
                _selectedFilter = value;
              });
            },
            backgroundColor: theme.colorScheme.surface,
            selectedColor: theme.colorScheme.primary,
          ),
        );
      },
    );
  }

  Widget _buildPostsList() {
    if (_currentUserProfile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<List<Post>>(
      stream: _searchQuery.isEmpty
          ? _postService.getPostsForUser(
              _currentUserProfile!.skillsTeachSimple,
              _currentUserProfile!.skillsLearnSimple,
            )
          : _postService.searchPosts(_searchQuery),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }

        final posts = snapshot.data ?? [];

        // Apply main filters (no subcategory filters anymore)
        final filteredPosts = _applyAdvancedFilter(posts);

        // Always apply smart sorting (smart feed is always on)
        final sortedPosts = _sortPostsByRelevance(filteredPosts);

        final theme = Theme.of(context);
        if (sortedPosts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_searchQuery.isNotEmpty || _selectedFilter != 'all') ...[
                    const Icon(
                      Icons.search_off,
                      size: 64,
                      color: Colors.white38,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No matching posts found',
                      style: TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Try adjusting your filters or search terms',
                      style: TextStyle(color: Colors.white38, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.group, size: 64, color: theme.colorScheme.primary),
                          const SizedBox(height: 16),
                          Text(
                            'No posts yet',
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Be the first to create a skill swap post and start connecting with other students!',
                            style: theme.textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () {
                              _navigateToCreatePost();
                            },
                            icon: Icon(Icons.add, color: theme.colorScheme.onPrimary),
                            label: Text('Create First Post', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onPrimary)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sortedPosts.length,
              itemBuilder: (context, index) {
                return _buildPostCard(sortedPosts[index]);
              },
            );
      },
    );
  }

  void _navigateToCreatePost() {
    // Use the callback to switch to create post tab
    widget.onTabChange?.call(1);
  }

  List<Post> _applyAdvancedFilter(List<Post> posts) {
    if (_currentUserProfile == null) return posts;

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    List<Post> filteredPosts = posts;

    // Apply main filter only (no more skill-specific subfilters)
    switch (_selectedFilter) {
      case 'teach':
        filteredPosts = posts
            .where(
              (post) =>
                  post.userId != currentUserId && // Exclude own posts
                  post.skillsLearn.any(
                    (skill) => _currentUserProfile!.skillsTeachSimple.any(
                      (s) => s == skill,
                    ),
                  ),
            )
            .toList();
        break;
      case 'learn':
        filteredPosts = posts
            .where(
              (post) =>
                  post.userId != currentUserId && // Exclude own posts
                  post.skillsTeach.any(
                    (skill) => _currentUserProfile!.skillsLearnSimple.any(
                      (s) => s == skill,
                    ),
                  ),
            )
            .toList();
        break;
      default: // 'all'
        filteredPosts = posts;
        break;
    }

    return filteredPosts;
  }

  Widget _buildPostCard(Post post) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return Container();

    final isOwnPost = post.userId == currentUserId;
    final matchScore = _calculateMatchScore(post);
    final comprehensiveScore = _calculateComprehensiveMatchScore(post);

    // NEW: Check if this is a new match due to recent profile update
    final bool isNewMatch = _isNewlyMatchedPost(post);

    // Determine relevance badge
    String? relevanceBadge;
    Color? badgeColor;

    if (matchScore > 0) {
      relevanceBadge = 'Perfect Match!';
      badgeColor = Colors.green;
    } else if (comprehensiveScore >= 1.0) {
      relevanceBadge = 'Good Match';
      badgeColor = Colors.blue;
    } else if (comprehensiveScore > 0) {
      relevanceBadge = 'Related';
      badgeColor = Colors.orange;
    }

    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)));
      },
      child: Card(
        color: theme.colorScheme.surface,
        margin: const EdgeInsets.only(bottom: 16),
        // NEW: Highlight border for new matches
        shape: isNewMatch
            ? RoundedRectangleBorder(
                side: BorderSide(
                  color: Colors.green.withOpacity(0.5),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Info with relevance badge
              Row(
                children: [
                    CircleAvatar(
                      backgroundColor: theme.colorScheme.primary,
                      child: Text(
                        post.userName[0].toUpperCase(),
                        style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onPrimary),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.userName,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          post.userMajor,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (isNewMatch)
                    Icon(Icons.fiber_new, color: Colors.green, size: 20),

                  StreamBuilder<bool>(
                    stream: _bookmarkService.isBookmarkedStream(currentUserId, post.id),
                    builder: (context, snapshot) {
                      final isBookmarked = snapshot.data ?? false;
                        return IconButton(
                        icon: Icon(
                          isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                          color: isBookmarked ? theme.colorScheme.primary : theme.iconTheme.color,
                        ),
                        onPressed: () {
                          _bookmarkService.toggleBookmark(currentUserId, post.id);
                        },
                      );
                    },
                  ),
                  
                  if (relevanceBadge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        relevanceBadge,
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  if (matchScore > 0 && relevanceBadge == null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$matchScore match${matchScore > 1 ? 'es' : ''}',
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.white),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Skills Section
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Skills to Learn
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Wants to Learn:",
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                                children: post.skillsLearn
                              .map(
                                (skill) => Chip(
                                  label: Text(
                                    skill.displaySkill,
                                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface),
                                  ),
                                  backgroundColor: theme.colorScheme.secondary.withOpacity(0.2),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Skills to Teach
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Can Teach:",
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                                children: post.skillsTeach
                              .map(
                                (skill) => Chip(
                                  label: Text(
                                    skill.displaySkill,
                                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface),
                                  ),
                                  backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Description
              if (post.description != null && post.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  post.description!,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],

              // Availability
              if (post.availability != null &&
                  post.availability!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 16, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      post.availability!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _startChatForPost(post);
                      },
                      icon: const Icon(Icons.message, size: 18),
                      label: const Text("Message"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  if (isOwnPost) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deletePost(post.id),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  final Set<String> _newlyMatchedPostIds = <String>{};

  bool _isNewlyMatchedPost(Post post) {
    return _newlyMatchedPostIds.contains(post.id);
  }

  // NEW: Update match tracking when profile changes
  void _updateMatchTracking(UserProfile? newProfile, UserProfile? oldProfile) {
    if (newProfile == null || oldProfile == null) return;

    // Compare skills to detect changes
    final newTeachSkills = newProfile.skillsTeachSimple.toSet();
    final oldTeachSkills = oldProfile.skillsTeachSimple.toSet();
    final newLearnSkills = newProfile.skillsLearnSimple.toSet();
    final oldLearnSkills = oldProfile.skillsLearnSimple.toSet();

    final teachSkillsAdded = newTeachSkills.difference(oldTeachSkills);
    final learnSkillsAdded = newLearnSkills.difference(oldLearnSkills);

    // If skills were added, mark potentially affected posts as new matches
    if (teachSkillsAdded.isNotEmpty || learnSkillsAdded.isNotEmpty) {
      _newlyMatchedPostIds.clear();

      // In a real implementation, you'd check which posts now match
      // For now, we'll simulate this by checking current posts
      // You could add more sophisticated tracking here
    }
  }

  int _calculateFilterMatchCount(List<Post> posts, String filterType) {
    if (_currentUserProfile == null) return 0;

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    int count = 0;

    switch (filterType) {
      case 'teach':
        count = posts
            .where(
              (post) =>
                  post.userId != currentUserId &&
                  post.skillsLearn.any(
                    (skill) => _currentUserProfile!.skillsTeachSimple.any(
                      (s) => s == skill,
                    ),
                  ),
            )
            .length;
        break;
      case 'learn':
        count = posts
            .where(
              (post) =>
                  post.userId != currentUserId &&
                  post.skillsTeach.any(
                    (skill) => _currentUserProfile!.skillsLearnSimple.any(
                      (s) => s == skill,
                    ),
                  ),
            )
            .length;
        break;
      case 'all':
      default:
        count = posts.length;
        break;
    }

    return count;
  }

  int _calculateMatchScore(Post post) {
    if (_currentUserProfile == null) return 0;

    int score = 0;
    // User can teach what the post wants to learn
    for (final skill in post.skillsLearn) {
      if (_currentUserProfile!.skillsTeachSimple.any((s) => s == skill))
        score++;
    }
    // User wants to learn what the post can teach
    for (final skill in post.skillsTeach) {
      if (_currentUserProfile!.skillsLearnSimple.any((s) => s == skill))
        score++;
    }
    return score;
  }

  Future<void> _startChatForPost(Post post) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Optional: stop user messaging their own post
    if (post.userId == currentUser.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You can't message your own post.")),
      );
      return;
    }

    try {
      // This returns the chatId (String) - ensures only one chat between two users
      final chatId = await _chatService.createOrGetChatBetweenUsers(
        postId: post.id,
        currentUserId: currentUser.uid,
        otherUserId: post.userId,
      );

      if (!mounted) return;

      // Navigate to your existing ChatScreen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: chatId,
            otherUserId: post.userId, // owner of the post
            otherUserName: post.userName,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to open chat: $e')));
    }
  }

  void _deletePost(String postId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D36),
        title: const Text("Delete Post", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Are you sure you want to delete this post?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () {
              _postService.deletePost(postId);
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
