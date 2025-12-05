import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/post.dart';
import '../../models/user_profile.dart';
import '../../models/skill_entry.dart';
import '../../services/post_service.dart';
import '../../services/user_service.dart';
import '../../services/skill_service.dart';

class CreatePostScreen extends StatefulWidget {
  final Function(int)? onTabChange;
  final GlobalKey<CreatePostScreenState>? key;

  const CreatePostScreen({this.key, this.onTabChange}) : super(key: key);

  @override
  CreatePostScreenState createState() => CreatePostScreenState();
}

class CreatePostScreenState extends State<CreatePostScreen> {
  final PostService _postService = PostService();
  final UserService _userService = UserService();
  final SkillService _skillService = SkillService();

  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _availabilityController = TextEditingController();

  List<SkillEntry> _selectedTeachSkills = [];
  List<SkillEntry> _selectedLearnSkills = [];
  bool _isSubmitting = false;

  UserProfile? _currentUserProfile;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _initializeSkills();
  }

  Future<void> _initializeSkills() async {
    await _skillService.initializeDefaultSkills();
  }

  Future<void> _loadUserProfile() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await _userService.db.collection('users').doc(uid).get();
    if (doc.exists) {
      setState(() {
        _currentUserProfile = UserProfile.fromMap(doc.data()!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _currentUserProfile == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Info Card
                  Card(
                    color: Theme.of(context).colorScheme.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            child: Text(
                              _currentUserProfile!.name[0].toUpperCase(),
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimary,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _currentUserProfile!.name,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  _currentUserProfile!.major,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Skills I Can Teach Section
                  Text(
                    "Skills I Can TEACH in this swap",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(
                        context,
                      ).colorScheme.onBackground, // Add this
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Select from your teaching skills",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(
                        context,
                      ).colorScheme.onBackground, // Add this
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSkillChips(
                    availableSkills: _currentUserProfile!.skillsTeach,
                    selectedSkills: _selectedTeachSkills,
                    isTeachSection: true,
                  ),

                  const SizedBox(height: 28),

                  // Skills I Want to Learn Section
                  Text(
                    "Skills I Want to LEARN in this swap",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Select from your learning skills",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  _buildSkillChips(
                    availableSkills: _currentUserProfile!.skillsLearn,
                    selectedSkills: _selectedLearnSkills,
                    isTeachSection: false,
                  ),

                  const SizedBox(height: 28),

                  // Description (Optional)
                  Text(
                    "Description (Optional)",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface, // Add this
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    style: Theme.of(context).textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText:
                          "Add any details about your teaching style, learning goals, etc...",
                      hintStyle: Theme.of(context).textTheme.bodySmall,
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Availability (Optional)
                  Text(
                    "Availability (Optional)",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface, // Add this
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _availabilityController,
                    style: Theme.of(context).textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: "e.g., Weekdays after 5 PM, Weekends flexible",
                      hintStyle: Theme.of(context).textTheme.bodySmall,
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : submitPost,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            )
                          : Text(
                              "Create Post",
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary, // Explicitly set text color
                                    fontWeight: FontWeight
                                        .w600, // Add some weight for better readability
                                  ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  // Public method that can be called from HomeScreen
  void submitPost() {
    _submitPost();
  }

  Widget _buildSkillChips({
    required List<SkillEntry> availableSkills,
    required List<SkillEntry> selectedSkills,
    required bool isTeachSection,
  }) {
    if (availableSkills.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Text(
          isTeachSection
              ? "No teaching skills in your profile. Add skills in your profile settings."
              : "No learning skills in your profile. Add skills in your profile settings.",
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(
              0.7,
            ), // Changed from Colors.white70
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: availableSkills.map((skill) {
        final isSelected = selectedSkills.contains(skill);
        final isDisabled = isTeachSection
            ? _selectedLearnSkills.contains(skill)
            : _selectedTeachSkills.contains(skill);

        return FilterChip(
          label: Text(skill.displaySkill),
          selected: isSelected,
          onSelected: isDisabled
              ? null
              : (selected) {
                  setState(() {
                    if (selected) {
                      if (isTeachSection) {
                        _selectedTeachSkills.add(skill);
                      } else {
                        _selectedLearnSkills.add(skill);
                      }
                    } else {
                      if (isTeachSection) {
                        _selectedTeachSkills.remove(skill);
                      } else {
                        _selectedLearnSkills.remove(skill);
                      }
                    }
                  });
                },
          backgroundColor: Colors.grey.withOpacity(0.2),
          selectedColor: isTeachSection
              ? const Color.fromARGB(255, 20, 234, 28).withOpacity(0.6)
              : const Color.fromARGB(255, 233, 125, 2).withOpacity(0.6),
          disabledColor: Colors.grey.withOpacity(0.1),
          labelStyle: TextStyle(
            color: isDisabled
                ? Colors
                      .grey // Changed from Colors.white38
                : isSelected
                ? Colors.white
                : Theme.of(
                    context,
                  ).colorScheme.onSurface, // Changed from Colors.white70
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          checkmarkColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected
                  ? (isTeachSection ? Colors.green : Colors.orange)
                  : Theme.of(
                      context,
                    ).colorScheme.outline, // Changed from Colors.white24
              width: isSelected ? 2 : 1,
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _submitPost() async {
    // Validation
    if (_selectedTeachSkills.isEmpty || _selectedLearnSkills.isEmpty) {
      _showError(
        "Please select at least one skill to teach and one skill to learn.",
      );
      return;
    }

    if (_selectedTeachSkills.length + _selectedLearnSkills.length > 6) {
      _showError(
        "Please select up to 6 skills total (3 teach + 3 learn recommended).",
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final post = Post(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: FirebaseAuth.instance.currentUser!.uid,
        userName: _currentUserProfile!.name,
        userMajor: _currentUserProfile!.major,
        skillsTeach: _selectedTeachSkills,
        skillsLearn: _selectedLearnSkills,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        availability: _availabilityController.text.trim().isEmpty
            ? null
            : _availabilityController.text.trim(),
        createdAt: DateTime.now(),
      );

      await _postService.createPost(post);

      // Update user profile with new skills and categories
      await _updateUserSkillsWithPostSkills();

      if (!mounted) return;

      // Clear form after successful submission
      _resetForm();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Post created successfully!"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Navigate to feed tab after successful post creation
      _navigateToFeed();
    } catch (e) {
      if (!mounted) return;
      _showError("Failed to create post. Please try again.");
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _updateUserSkillsWithPostSkills() async {
    if (_currentUserProfile == null) return;

    final updatedTeachSkills = _currentUserProfile!.skillsTeach.toList();
    for (final skill in _selectedTeachSkills) {
      if (!updatedTeachSkills.contains(skill)) {
        updatedTeachSkills.add(skill);
      }
    }

    final updatedLearnSkills = _currentUserProfile!.skillsLearn.toList();
    for (final skill in _selectedLearnSkills) {
      if (!updatedLearnSkills.contains(skill)) {
        updatedLearnSkills.add(skill);
      }
    }

    // Remove skills that are now in the opposite category
    updatedTeachSkills.removeWhere(
      (skill) => _selectedLearnSkills.contains(skill),
    );
    updatedLearnSkills.removeWhere(
      (skill) => _selectedTeachSkills.contains(skill),
    );

    final updatedProfile = UserProfile(
      uid: _currentUserProfile!.uid,
      name: _currentUserProfile!.name,
      major: _currentUserProfile!.major,
      skillsTeach: updatedTeachSkills,
      skillsLearn: updatedLearnSkills,
      profileImageUrl: _currentUserProfile!.profileImageUrl,
      bio: _currentUserProfile!.bio,
    );

    await _userService.updateUserProfile(updatedProfile);
  }

  void _resetForm() {
    setState(() {
      _selectedTeachSkills.clear();
      _selectedLearnSkills.clear();
      _descriptionController.clear();
      _availabilityController.clear();
    });
  }

  void _navigateToFeed() {
    // Navigate back to feed tab (index 0)
    widget.onTabChange?.call(0);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _availabilityController.dispose();
    super.dispose();
  }
}
