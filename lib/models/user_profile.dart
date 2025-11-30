import 'skill_entry.dart';

class UserProfile {
  final String uid;
  final String name;
  final String major;
  final List<SkillEntry> skillsTeach;
  final List<SkillEntry> skillsLearn;
  final String? profileImageUrl;
  final String? bio;
  final String? fcmToken;
  final DateTime? fcmTokenUpdatedAt;

  /// Average rating given by other users (0.0–5.0).
  final double avgRating;

  /// How many reviews were submitted for this user.
  final int reviewsCount;

  UserProfile({
    required this.uid,
    required this.name,
    required this.major,
    required this.skillsTeach,
    required this.skillsLearn,
    this.profileImageUrl,
    this.bio,
    this.avgRating = 0.0,
    this.reviewsCount = 0,
    this.fcmToken,
    this.fcmTokenUpdatedAt,
  });

  // Helper getters for display
  List<String> get skillsTeachDisplay =>
      skillsTeach.map((skill) => skill.displaySkill).toList();

  List<String> get skillsLearnDisplay =>
      skillsLearn.map((skill) => skill.displaySkill).toList();

  List<SkillEntry> get skillsTeachSimple => skillsTeach;
  List<SkillEntry> get skillsLearnSimple => skillsLearn;

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'major': major,
      'skillsTeach': skillsTeach.map((skill) => skill.toMap()).toList(),
      'skillsLearn': skillsLearn.map((skill) => skill.toMap()).toList(),
      'profileImageUrl': profileImageUrl,
      'bio': bio,

      // ⭐ NEW – persist rating summary
      'avgRating': avgRating,
      'reviewsCount': reviewsCount,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
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
            return SkillEntry.fromLegacyString('Other');
          } catch (e) {
            print('Error parsing skill item: $item, error: $e');
            return SkillEntry.fromLegacyString('Other');
          }
        }).toList();
      }
      return [];
    }

    return UserProfile(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      major: map['major'] ?? '',
      skillsTeach: parseSkills(map['skillsTeach']),
      skillsLearn: parseSkills(map['skillsLearn']),
      profileImageUrl: map['profileImageUrl'],
      bio: map['bio'],

      // ⭐ NEW – read rating summary (with safe defaults)
      avgRating: (map['avgRating'] as num?)?.toDouble() ?? 0.0,
      reviewsCount: (map['reviewsCount'] as num?)?.toInt() ?? 0,
    );
  }
}
