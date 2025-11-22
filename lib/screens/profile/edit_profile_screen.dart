import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/profile_controller.dart';
import '../../models/user_profile.dart';

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
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  bool _isUploading = false;

  final List<String> allSkills = [
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

  List<String> skillsTeach = [];
  List<String> skillsLearn = [];

  @override
  void initState() {
    super.initState();
    // Pre-fill with current profile data
    nameController.text = widget.currentProfile.name;
    majorController.text = widget.currentProfile.major;
    skillsTeach = List.from(widget.currentProfile.skillsTeach);
    skillsLearn = List.from(widget.currentProfile.skillsLearn);
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

            const SizedBox(height: 24),
            const Text(
              "Skills you can TEACH",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 10),
            _buildSkillChips(
              selectedList: skillsTeach,
              isTeachList: true,
            ),

            const SizedBox(height: 28),
            const Text(
              "Skills you want to LEARN",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 10),
            _buildSkillChips(
              selectedList: skillsLearn,
              isTeachList: false,
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

  Widget _buildSkillChips({
    required List<String> selectedList,
    required bool isTeachList,
  }) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: allSkills.map((skill) {
        final bool isSelected = selectedList.contains(skill);
        final bool isDisabled = isTeachList
            ? skillsLearn.contains(skill)
            : skillsTeach.contains(skill);

        return GestureDetector(
          onTap: isDisabled
              ? null
              : () => setState(() {
                    if (isSelected) {
                      selectedList.remove(skill);
                    } else {
                      selectedList.add(skill);
                    }
                  }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
            decoration: BoxDecoration(
              color: isDisabled
                  ? Colors.grey.shade700
                  : isSelected
                      ? Colors.blue
                      : const Color(0xFF1A1D36),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? Colors.blueAccent
                    : isDisabled
                        ? Colors.grey.shade600
                        : Colors.white30,
              ),
            ),
            child: Text(
              skill,
              style: TextStyle(
                color: isDisabled
                    ? Colors.white30
                    : isSelected
                        ? Colors.white
                        : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
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

    // Validation
    if (name.isEmpty || major.isEmpty) {
      _showError("Please fill all fields.");
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
    super.dispose();
  }
}
