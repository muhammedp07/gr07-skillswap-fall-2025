import 'skill_entry.dart';

class Post {
  final String id;
  final String userId;
  final String userName;
  final String userMajor;
  final List<SkillEntry> skillsTeach;
  final List<SkillEntry> skillsLearn;
  final String? description;
  final String? availability;
  final DateTime createdAt;

  Post({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userMajor,
    required this.skillsTeach,
    required this.skillsLearn,
    this.description,
    this.availability,
    required this.createdAt,
  });

  // Helper getters for display
  List<String> get skillsTeachDisplay => 
      skillsTeach.map((skill) => skill.displaySkill).toList();
  
  List<String> get skillsLearnDisplay => 
      skillsLearn.map((skill) => skill.displaySkill).toList();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userMajor': userMajor,
      'skillsTeach': skillsTeach.map((skill) => skill.toMap()).toList(),
      'skillsLearn': skillsLearn.map((skill) => skill.toMap()).toList(),
      'description': description,
      'availability': availability,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Post.fromMap(Map<String, dynamic> map) {
    // Handle both new format (SkillEntry) and legacy format (plain strings)
    List<SkillEntry> parseSkills(dynamic skillsData) {
      if (skillsData is List) {
        return skillsData.map((item) {
          try {
            if (item is Map<String, dynamic>) {
              // New format
              return SkillEntry.fromMap(item);
            } else if (item is String) {
              // Legacy format - convert to SkillEntry
              return SkillEntry.fromLegacyString(item);
            }
            // Fallback for unexpected types
            return SkillEntry.fromLegacyString('Other');
          } catch (e) {
            print('Error parsing skill item: $item, error: $e');
            // If parsing fails, create a safe fallback
            return SkillEntry.fromLegacyString('Other');
          }
        }).toList();
      }
      return [];
    }

    return Post(
      id: map['id'],
      userId: map['userId'],
      userName: map['userName'],
      userMajor: map['userMajor'],
      skillsTeach: parseSkills(map['skillsTeach']),
      skillsLearn: parseSkills(map['skillsLearn']),
      description: map['description'],
      availability: map['availability'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }
}