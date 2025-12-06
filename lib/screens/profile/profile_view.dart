import 'package:flutter/material.dart';
import 'package:gr07_skillswap/screens/feed/saved_posts_screen.dart';
import '../../controllers/profile_controller.dart';
import '../../models/user_profile.dart';
import 'edit_profile_screen.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  // Initialize the controller
  final ProfileController _controller = ProfileController();

  // State variables
  UserProfile? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Ask the controller for data
  Future<void> _loadData() async {
    final profile = await _controller.getUserProfile();
    if (mounted) {
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 1. Loading State
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 2. Error State (Profile not found)
    if (_profile == null) {
      return const Center(
        child: Text(
          "Error: Profile not found.",
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    // 3. Success State (Display Profile)
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // Profile Image
            CircleAvatar(
            radius: 50,
            backgroundColor: theme.colorScheme.primary,
            backgroundImage: _profile!.profileImageUrl != null
              ? NetworkImage(_profile!.profileImageUrl!)
              : null,
            child: _profile!.profileImageUrl == null
              ? Icon(Icons.person, size: 60, color: theme.colorScheme.onPrimary)
              : null,
            ),
          const SizedBox(height: 16),

          // Name
          Text(
            _profile!.name,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),

          // Major
          Text(
            _profile!.major,
            style: theme.textTheme.bodyMedium,
          ),

          // Bio
          if (_profile!.bio != null && _profile!.bio!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                  _profile!.bio!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
            ),
          ],

          const SizedBox(height: 24),

          // Edit Profile Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EditProfileScreen(currentProfile: _profile!),
                  ),
                );
                // Reload profile if changes were saved
                if (result == true) {
                  _loadData();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Edit Profile",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          
          _buildSavedPostsSection(theme),
          const SizedBox(height: 32),
          // Skills I Can Teach Section
          _buildSkillSection(
            title: "Skills I Teach",
            skills: _profile!.skillsTeachDisplay,
            color: theme.cardColor,
            textColor: theme.textTheme.bodySmall?.color ?? Colors.grey.shade400,
          ),

          const SizedBox(height: 24),

          // Skills I Want To Learn Section
          _buildSkillSection(
            title: "Skills I Want To Learn",
            skills: _profile!.skillsLearnDisplay,
            color: theme.cardColor,
            textColor: theme.textTheme.bodySmall?.color ?? Colors.grey.shade400,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSavedPostsSection(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Saved Posts",
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: Icon(Icons.bookmark, color: theme.colorScheme.primary),
              title: Text(
                'View Saved Posts',
                style: theme.textTheme.bodyMedium,
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SavedPostsScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget to draw the chips
  Widget _buildSkillSection({
    required String title,
    required List<String> skills,
    required Color color,
    required Color textColor,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          skills.isEmpty
              ? const Text(
                  "No skills listed.",
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.white54,
                  ),
                )
              : Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.start,
                    children: skills.map((skill) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: textColor),
                        ),
                        child: Text(
                          skill,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
        ],
      ),
    );
  }
}
