import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_profile.dart';
import '../../models/skill_entry.dart';
import '../../services/user_service.dart';
import '../../services/skill_service.dart';
import '../../widgets/skill_selection_widget.dart';
import '../home/home_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final nameController = TextEditingController();
  final majorController = TextEditingController();
  final bioController = TextEditingController();
  final SkillService _skillService = SkillService();

  List<SkillEntry> skillsTeach = [];
  List<SkillEntry> skillsLearn = [];

  @override
  void initState() {
    super.initState();
    _initializeSkills();
  }

  Future<void> _initializeSkills() async {
    // Initialize default skills in Firebase
    await _skillService.initializeDefaultSkills();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(
          "Set up your profile",
          style: theme.appBarTheme.titleTextStyle,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Your Name",
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 6),
            _buildTextField(nameController, "Enter your name"),

            const SizedBox(height: 20),
            Text(
              "Program / Major",
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 6),
            _buildTextField(majorController, "e.g. Computer Science"),

            const SizedBox(height: 20),
            Text(
              "Bio (Optional)",
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 6),
            _buildBioField(),

            const SizedBox(height: 24),
            SkillSelectionWidget(
              selectedSkills: skillsTeach,
              onSkillsChanged: (skills) {
                setState(() {
                  skillsTeach = skills;
                });
              },
              title: "Skills you can TEACH",
              chipColor: theme.colorScheme.primaryContainer.withOpacity(0.3),
              excludedSkills: skillsLearn,
            ),

            const SizedBox(height: 28),
            SkillSelectionWidget(
              selectedSkills: skillsLearn,
              onSkillsChanged: (skills) {
                setState(() {
                  skillsLearn = skills;
                });
              },
              title: "Skills you want to LEARN",
              chipColor: theme.colorScheme.secondaryContainer.withOpacity(0.3),
              excludedSkills: skillsTeach,
            ),

            const SizedBox(height: 40),
            _buildContinueButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        hintText: hint,
        hintStyle: Theme.of(context).textTheme.bodySmall,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _buildBioField() {
    return TextField(
      controller: bioController,
      maxLength: 150,
      maxLines: 3,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        hintText: "Tell us about yourself...",
        hintStyle: Theme.of(context).textTheme.bodySmall,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        counterStyle: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _handleProfileSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text("Continue", style: Theme.of(context).textTheme.titleSmall),
      ),
    );
  }

  Future<void> _handleProfileSave() async {
    final name = nameController.text.trim();
    final major = majorController.text.trim();
    final bio = bioController.text.trim();

    // Validation
    if (name.isEmpty || major.isEmpty) {
      _showError("Please fill all required fields.");
      return;
    }
    if (skillsTeach.isEmpty || skillsLearn.isEmpty) {
      _showError("Please select at least one teach and one learn skill.");
      return;
    }

    final uid = FirebaseAuth.instance.currentUser!.uid;

    final profile = UserProfile(
      uid: uid,
      name: name,
      major: major,
      skillsTeach: skillsTeach,
      skillsLearn: skillsLearn,
      bio: bio.isEmpty ? null : bio,
    );

    try {
      await UserService().saveUserProfile(profile);

      if (!mounted) return;

      // Navigate to home screen, removing all previous routes
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      _showError("Failed to save profile. Try again.");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Theme.of(context).colorScheme.error),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    majorController.dispose();
    bioController.dispose();
    super.dispose();
  }
}
