import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/post.dart';
import '../../models/user_profile.dart';
import '../../services/post_service.dart';
import '../../services/user_service.dart';

class CreatePostScreen extends StatefulWidget {
  final Function(int)? onTabChange;
  final GlobalKey<CreatePostScreenState>? key;

  const CreatePostScreen({
    this.key,
    this.onTabChange,
  }) : super(key: key);

  @override
  CreatePostScreenState createState() => CreatePostScreenState();
}

class CreatePostScreenState extends State<CreatePostScreen> {
  final PostService _postService = PostService();
  final UserService _userService = UserService();

  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _availabilityController = TextEditingController();

  List<String> _selectedTeachSkills = [];
  List<String> _selectedLearnSkills = [];
  bool _isSubmitting = false;

  // Track which skills are mutually exclusive
  final Map<String, String> _skillCategories = {}; // skill -> 'teach' or 'learn'

  final List<String> _allSkills = [
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

  UserProfile? _currentUserProfile;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _initializeSkillCategories();
  }

  void _initializeSkillCategories() {
    // Initialize all skills as available for both categories
    for (final skill in _allSkills) {
      _skillCategories[skill] = 'available'; // available, teach, or learn
    }
  }

  Future<void> _loadUserProfile() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await _userService.db.collection('users').doc(uid).get();
    if (doc.exists) {
      setState(() {
        _currentUserProfile = UserProfile.fromMap(doc.data()!);
        
        // Pre-categorize skills from user profile
        for (final skill in _currentUserProfile!.skillsTeach) {
          _skillCategories[skill] = 'teach';
        }
        for (final skill in _currentUserProfile!.skillsLearn) {
          _skillCategories[skill] = 'learn';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1126),
      body: _currentUserProfile == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Info Card
                  Card(
                    color: const Color(0xFF1A1D36),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Text(
                              _currentUserProfile!.name[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _currentUserProfile!.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _currentUserProfile!.major,
                                  style: const TextStyle(color: Colors.white70),
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
                  const Text(
                    "Skills I Can TEACH in this swap:",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Select skills you're comfortable teaching to others",
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  _buildSkillChips(
                    selectedList: _selectedTeachSkills,
                    isTeachSection: true,
                  ),

                  const SizedBox(height: 28),

                  // Skills I Want to Learn Section
                  const Text(
                    "Skills I Want to LEARN in this swap:",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Select skills you want to learn from others",
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  _buildSkillChips(
                    selectedList: _selectedLearnSkills,
                    isTeachSection: false,
                  ),

                  const SizedBox(height: 28),

                  // Description (Optional)
                  const Text(
                    "Description (Optional)",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText:
                          "Add any details about your teaching style, learning goals, etc...",
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF1A1D36),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Availability (Optional)
                  const Text(
                    "Availability (Optional)",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _availabilityController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "e.g., Weekdays after 5 PM, Weekends flexible",
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF1A1D36),
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
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "Create Post",
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildSkillChips({
    required List<String> selectedList,
    required bool isTeachSection,
  }) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _allSkills.map((skill) {
        final bool isSelected = selectedList.contains(skill);
        final String? skillCategory = _skillCategories[skill];
        
        // Determine if skill should be disabled
        bool isDisabled = false;
        String disabledReason = '';
        
        if (isTeachSection) {
          // In Teach section, disable if skill is categorized as 'learn'
          if (skillCategory == 'learn') {
            isDisabled = true;
            disabledReason = 'Already in your Learn skills';
          }
        } else {
          // In Learn section, disable if skill is categorized as 'teach'
          if (skillCategory == 'teach') {
            isDisabled = true;
            disabledReason = 'Already in your Teach skills';
          }
        }

        return Tooltip(
          message: isDisabled ? disabledReason : '',
          child: GestureDetector(
            onTap: isDisabled ? null : () => _toggleSkill(skill, isTeachSection),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: isDisabled
                    ? Colors.grey.withOpacity(0.3)
                    : isSelected
                    ? isTeachSection
                        ? Colors.green.withOpacity(0.3)
                        : Colors.red.withOpacity(0.3)
                    : const Color(0xFF1A1D36),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDisabled
                      ? Colors.grey
                      : isSelected
                      ? isTeachSection
                          ? Colors.green
                          : Colors.red
                      : Colors.white30,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    skill,
                    style: TextStyle(
                      color: isDisabled ? Colors.white30 : Colors.white,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 6),
                    Icon(
                      Icons.check,
                      size: 16,
                      color: isTeachSection ? Colors.green : Colors.red,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _toggleSkill(String skill, bool isTeachSection) {
    setState(() {
      if (isTeachSection) {
        if (_selectedTeachSkills.contains(skill)) {
          _selectedTeachSkills.remove(skill);
          // Only reset category if not predefined in profile
          if (!_currentUserProfile!.skillsTeach.contains(skill)) {
            _skillCategories[skill] = 'available';
          }
        } else {
          _selectedTeachSkills.add(skill);
          _skillCategories[skill] = 'teach';
          
          // Remove from learn if it was there
          if (_selectedLearnSkills.contains(skill)) {
            _selectedLearnSkills.remove(skill);
          }
        }
      } else {
        if (_selectedLearnSkills.contains(skill)) {
          _selectedLearnSkills.remove(skill);
          // Only reset category if not predefined in profile
          if (!_currentUserProfile!.skillsLearn.contains(skill)) {
            _skillCategories[skill] = 'available';
          }
        } else {
          _selectedLearnSkills.add(skill);
          _skillCategories[skill] = 'learn';
          
          // Remove from teach if it was there
          if (_selectedTeachSkills.contains(skill)) {
            _selectedTeachSkills.remove(skill);
          }
        }
      }
    });
  }

  // Public method that can be called from HomeScreen
  void submitPost() {
    _submitPost();
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

    // Check for mutual exclusion violations
    for (final skill in _selectedTeachSkills) {
      if (_skillCategories[skill] == 'learn') {
        _showError(
          "Skill '$skill' cannot be in both Teach and Learn sections. "
          "It is already categorized as a Learn skill.",
        );
        return;
      }
    }

    for (final skill in _selectedLearnSkills) {
      if (_skillCategories[skill] == 'teach') {
        _showError(
          "Skill '$skill' cannot be in both Teach and Learn sections. "
          "It is already categorized as a Teach skill.",
        );
        return;
      }
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

    updatedTeachSkills.removeWhere((skill) => _skillCategories[skill] == 'learn');
    updatedLearnSkills.removeWhere((skill) => _skillCategories[skill] == 'teach');

    final updatedProfile = UserProfile(
      uid: _currentUserProfile!.uid,
      name: _currentUserProfile!.name,
      major: _currentUserProfile!.major,
      skillsTeach: updatedTeachSkills,
      skillsLearn: updatedLearnSkills,
    );

    await _userService.updateUserProfile(updatedProfile);
  }

  void _resetForm() {
    setState(() {
      _selectedTeachSkills.clear();
      _selectedLearnSkills.clear();
      _descriptionController.clear();
      _availabilityController.clear();
      _initializeSkillCategories();
      
      // Re-initialize with profile skills
      if (_currentUserProfile != null) {
        for (final skill in _currentUserProfile!.skillsTeach) {
          _skillCategories[skill] = 'teach';
        }
        for (final skill in _currentUserProfile!.skillsLearn) {
          _skillCategories[skill] = 'learn';
        }
      }
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