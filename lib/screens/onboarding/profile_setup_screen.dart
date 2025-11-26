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
    return Scaffold(
      backgroundColor: const Color(0xFF0E1126),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1126),
        elevation: 0,
        title: const Text(
          "Set up your profile",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Your Name",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 6),
            _buildTextField(nameController, "Enter your name"),

            const SizedBox(height: 20),
            const Text(
              "Program / Major",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 6),
            _buildTextField(majorController, "e.g. Computer Science"),

            const SizedBox(height: 20),
            const Text(
              "Bio (Optional)",
              style: TextStyle(color: Colors.white70, fontSize: 16),
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
              chipColor: Colors.green.withOpacity(0.3),
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
              chipColor: Colors.orange.withOpacity(0.3),
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
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF1A1D36),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _buildBioField() {
    return TextField(
      controller: bioController,
      maxLength: 150,
      maxLines: 3,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF1A1D36),
        hintText: "Tell us about yourself...",
        hintStyle: const TextStyle(color: Colors.white54),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        counterStyle: const TextStyle(color: Colors.white54),
      ),
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _handleProfileSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Text("Continue", style: TextStyle(fontSize: 16)),
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
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
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
