import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/post.dart';
import '../../models/user_profile.dart';
import '../../services/post_service.dart';
import '../../services/user_service.dart';

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

  String _searchQuery = '';
  String _selectedFilter = 'all';
  // ignore: unused_field
  List<String> _availableSkills = [];
  UserProfile? _currentUserProfile;

  // New state for skill-specific filtering
  String? _selectedTeachFilterSkill;
  String? _selectedLearnFilterSkill;

  @override
  void initState() {
    super.initState();
    _loadAvailableSkills();
    _loadCurrentUserProfile();
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

  Future<void> _loadCurrentUserProfile() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userProfile = await _userService.getUserProfile(uid);
    if (mounted) {
      setState(() {
        _currentUserProfile = userProfile;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1126),
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(),

          // Filter Section
          _buildFilterSection(),

          // Posts List
          Expanded(child: _buildPostsList()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: "Search skills, names, majors...",
          hintStyle: const TextStyle(color: Colors.white54),
          prefixIcon: const Icon(Icons.search, color: Colors.white70),
          filled: true,
          fillColor: const Color(0xFF1A1D36),
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
    return Column(
      children: [
        // Main Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildMainFilterChip('All Posts', 'all'),
              _buildMainFilterChip('I Want to Learn', 'learn'),
              _buildMainFilterChip('I Can Teach', 'teach'),
            ],
          ),
        ),

        // Skill-specific filters (only show when relevant main filter is selected)
        if (_selectedFilter == 'learn' || _selectedFilter == 'teach')
          _buildSkillFilterChips(),
      ],
    );
  }

  Widget _buildMainFilterChip(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0, top: 8.0),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            color: _selectedFilter == value ? Colors.white : Colors.white70,
          ),
        ),
        selected: _selectedFilter == value,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = value;
            // Reset skill-specific filters when changing main filter
            _selectedTeachFilterSkill = null;
            _selectedLearnFilterSkill = null;
          });
        },
        backgroundColor: const Color(0xFF1A1D36),
        selectedColor: Colors.blue,
      ),
    );
  }

  Widget _buildSkillFilterChips() {
    return StreamBuilder<List<Post>>(
      stream: _postService.getPostsStream(),
      builder: (context, snapshot) {
        List<String> skillsToShow = [];

        if (snapshot.hasData && _currentUserProfile != null) {
          skillsToShow = _discoverSkillsFromPosts(
            snapshot.data!,
            _selectedFilter,
          );
        } else {
          // Fallback to user's profile skills
          skillsToShow = _selectedFilter == 'learn'
              ? _currentUserProfile?.skillsLearn ?? []
              : _currentUserProfile?.skillsTeach ?? [];
        }

        if (skillsToShow.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _selectedFilter == 'learn'
                  ? "No skills available to learn. Try creating a post or check back later."
                  : "No skills available to teach. Try creating a post or check back later.",
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _selectedFilter == 'learn'
                    ? "Skills you want to learn:"
                    : "Skills you can teach:",
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: skillsToShow.map((skill) {
                  final isSelected = _selectedFilter == 'learn'
                      ? _selectedLearnFilterSkill == skill
                      : _selectedTeachFilterSkill == skill;

                  // Check if this skill is from user's profile or discovered
                  final bool isFromProfile = _selectedFilter == 'learn'
                      ? _currentUserProfile!.skillsLearn.contains(skill)
                      : _currentUserProfile!.skillsTeach.contains(skill);

                  return Tooltip(
                    message: isFromProfile
                        ? "From your profile"
                        : "Discovered from posts",
                    child: FilterChip(
                      label: Text(
                        skill,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: isFromProfile
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (_selectedFilter == 'learn') {
                            _selectedLearnFilterSkill = selected ? skill : null;
                          } else {
                            _selectedTeachFilterSkill = selected ? skill : null;
                          }
                        });
                      },
                      backgroundColor: const Color(0xFF1A1D36),
                      selectedColor: _selectedFilter == 'learn'
                          ? Colors.red.withOpacity(0.3)
                          : Colors.green.withOpacity(0.3),
                      checkmarkColor: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ],
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
              _currentUserProfile!.skillsTeach,
              _currentUserProfile!.skillsLearn,
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
        final filteredPosts = _applyAdvancedFilter(posts);

        if (filteredPosts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_searchQuery.isNotEmpty ||
                      _selectedFilter != 'all' ||
                      _selectedLearnFilterSkill != null ||
                      _selectedTeachFilterSkill != null) ...[
                    // When filters are active but no results
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
                    // When there are genuinely no posts in the system
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1D36),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.group, size: 64, color: Colors.blue),
                          const SizedBox(height: 16),
                          const Text(
                            'No posts yet',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Be the first to create a skill swap post and start connecting with other students!',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () {
                              _navigateToCreatePost();
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Create First Post'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
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
          itemCount: filteredPosts.length,
          itemBuilder: (context, index) {
            return _buildPostCard(filteredPosts[index]);
          },
        );
      },
    );
  }

  void _navigateToCreatePost() {
    // Use the callback to switch to create post tab
    widget.onTabChange?.call(1);
  }

  List<String> _discoverSkillsFromPosts(List<Post> posts, String filterType) {
    final Set<String> discoveredSkills = {};

    for (final post in posts) {
      if (filterType == 'learn') {
        // For "I Want to Learn" filter, only show skills that are categorized as teach skills
        // and not already in the user's teach skills
        for (final skill in post.skillsTeach) {
          // Only include if this skill isn't in the user's teach skills
          if (!_currentUserProfile!.skillsTeach.contains(skill)) {
            discoveredSkills.add(skill);
          }
        }
      } else if (filterType == 'teach') {
        // For "I Can Teach" filter, only show skills that are categorized as learn skills
        // and not already in the user's learn skills
        for (final skill in post.skillsLearn) {
          // Only include if this skill isn't in the user's learn skills
          if (!_currentUserProfile!.skillsLearn.contains(skill)) {
            discoveredSkills.add(skill);
          }
        }
      }
    }

    // Combine with user's existing skills for the respective filter type
    final userSkills = filterType == 'learn'
        ? _currentUserProfile?.skillsLearn ?? []
        : _currentUserProfile?.skillsTeach ?? [];

    return {...userSkills, ...discoveredSkills}.toList()..sort();
  }

  List<Post> _applyAdvancedFilter(List<Post> posts) {
    if (_currentUserProfile == null) return posts;

    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    List<Post> filteredPosts = posts;

    // Apply main filter
    switch (_selectedFilter) {
      case 'teach':
        // Show posts where users want to learn skills that current user can teach
        filteredPosts = posts
            .where(
              (post) =>
                  post.userId != currentUserId && // Exclude own posts
                  post.skillsLearn.any(
                    (skill) => _currentUserProfile!.skillsTeach.contains(skill),
                  ),
            )
            .toList();
        break;
      case 'learn':
        // Show posts where users can teach skills that current user wants to learn
        filteredPosts = posts
            .where(
              (post) =>
                  post.userId != currentUserId && // Exclude own posts
                  post.skillsTeach.any(
                    (skill) => _currentUserProfile!.skillsLearn.contains(skill),
                  ),
            )
            .toList();
        break;
      default: // 'all'
        filteredPosts = posts;
        break;
    }

    // Apply skill-specific filters
    if (_selectedLearnFilterSkill != null) {
      filteredPosts = filteredPosts
          .where((post) => post.skillsTeach.contains(_selectedLearnFilterSkill))
          .toList();
    }

    if (_selectedTeachFilterSkill != null) {
      filteredPosts = filteredPosts
          .where((post) => post.skillsLearn.contains(_selectedTeachFilterSkill))
          .toList();
    }

    return filteredPosts;
  }

  Widget _buildPostCard(Post post) {
    final isOwnPost = post.userId == FirebaseAuth.instance.currentUser!.uid;
    final matchScore = _calculateMatchScore(post);

    return Card(
      color: const Color(0xFF1A1D36),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text(
                    post.userName[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        post.userMajor,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                if (matchScore > 0)
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
                      style: const TextStyle(color: Colors.white, fontSize: 12),
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
                      const Text(
                        "Wants to Learn:",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: post.skillsLearn
                            .map(
                              (skill) => Chip(
                                label: Text(
                                  skill,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                                backgroundColor: Colors.red.withOpacity(0.3),
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
                      const Text(
                        "Can Teach:",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: post.skillsTeach
                            .map(
                              (skill) => Chip(
                                label: Text(
                                  skill,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                                backgroundColor: Colors.green.withOpacity(0.3),
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
            if (post.availability != null && post.availability!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 16, color: Colors.white70),
                  const SizedBox(width: 4),
                  Text(
                    post.availability!,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
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
                      _showMessageDialog(post);
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
    );
  }

  int _calculateMatchScore(Post post) {
    if (_currentUserProfile == null) return 0;

    int score = 0;
    // User can teach what the post wants to learn
    for (String skill in post.skillsLearn) {
      if (_currentUserProfile!.skillsTeach.contains(skill)) score++;
    }
    // User wants to learn what the post can teach
    for (String skill in post.skillsTeach) {
      if (_currentUserProfile!.skillsLearn.contains(skill)) score++;
    }
    return score;
  }

  void _showMessageDialog(Post post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D36),
        title: Text(
          "Message ${post.userName}",
          style: const TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Messaging feature will be implemented in the next phase.\n\nFor now, you can discuss meeting in public spaces on campus like the Library, UC, or Science Building.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}