import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/profile_controller.dart';
import '../../models/user_profile.dart';
import '../../models/skill_entry.dart';
import '../../services/skill_service.dart';
import '../../widgets/skill_selection_widget.dart';

class EditProfileScreen extends StatefulWidget {
  final UserProfile currentProfile;

  const EditProfileScreen({super.key, required this.currentProfile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ProfileController _controller = ProfileController();
  final nameController = TextEditingController();
  final majorController = TextEditingController();
  final bioController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final SkillService _skillService = SkillService();

  File? _selectedImage;
  bool _isUploading = false;

  List<SkillEntry> skillsTeach = [];
  List<SkillEntry> skillsLearn = [];

  @override
  void initState() {
    super.initState();
    _initializeProfile();
  }

  Future<void> _initializeProfile() async {
    // Initialize default skills in Firebase
    await _skillService.initializeDefaultSkills();
    
    // Pre-fill with current profile data
    nameController.text = widget.currentProfile.name;
    majorController.text = widget.currentProfile.major;
    bioController.text = widget.currentProfile.bio ?? '';
    setState(() {
      skillsTeach = List.from(widget.currentProfile.skillsTeach);
      skillsLearn = List.from(widget.currentProfile.skillsLearn);
    });
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1126),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1126),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Edit Profile",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Image Picker
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.blueAccent,
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : (widget.currentProfile.profileImageUrl != null
                              ? NetworkImage(widget.currentProfile.profileImageUrl!)
                              : null) as ImageProvider?,
                      child: (_selectedImage == null && widget.currentProfile.profileImageUrl == null)
                          ? const Icon(Icons.person, size: 60, color: Colors.white)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

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
            _buildSaveButton(),
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

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isUploading ? null : _handleSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isUploading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                "Save Changes",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
      ),
    );
  }

  Future<void> _handleSave() async {
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

    setState(() {
      _isUploading = true;
    });

    try {
      String? imageUrl = widget.currentProfile.profileImageUrl;

      // Upload new image if selected
      if (_selectedImage != null) {
        imageUrl = await _controller.uploadProfileImage(_selectedImage!);
      }

      // Create updated profile
      final updatedProfile = UserProfile(
        uid: widget.currentProfile.uid,
        name: name,
        major: major,
        skillsTeach: skillsTeach,
        skillsLearn: skillsLearn,
        profileImageUrl: imageUrl,
        bio: bio.isEmpty ? null : bio,
      );

      await _controller.updateUserProfile(updatedProfile);

      if (!mounted) return;

      // Show success and return
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile updated successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true); // Return true to indicate success
    } catch (e) {
      _showError("Failed to update profile. Try again.");
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
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
