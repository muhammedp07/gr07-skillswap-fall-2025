import 'package:flutter/material.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final nameController = TextEditingController();
  final majorController = TextEditingController();

  // Predefined skills (to avoid duplicates like python/Python/Python3)
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

            const SizedBox(height: 24),
            const Text(
              "Skills you can TEACH",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 10),
            _buildSkillChips(
              selectedList: skillsTeach,
              onSelect: (skill) {
                setState(() {
                  if (skillsTeach.contains(skill)) {
                    skillsTeach.remove(skill);
                  } else {
                    skillsTeach.add(skill);
                  }
                });
              },
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
              onSelect: (skill) {
                setState(() {
                  if (skillsLearn.contains(skill)) {
                    skillsLearn.remove(skill);
                  } else {
                    skillsLearn.add(skill);
                  }
                });
              },
              isTeachList: false,
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

  Widget _buildSkillChips({
    required List<String> selectedList,
    required Function(String) onSelect,
    required bool isTeachList,
  }) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: allSkills.map((skill) {
        final bool isSelected = selectedList.contains(skill);

        // Disable logic:
        // If this is Teach list → disable chips already chosen in Learn
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

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {},
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

  @override
  void dispose() {
    nameController.dispose();
    majorController.dispose();
    super.dispose();
  }
}
