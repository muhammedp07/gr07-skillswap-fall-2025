class UserProfile {
  final String uid;
  final String name;
  final String major;
  final List<String> skillsTeach;
  final List<String> skillsLearn;
  final String? profileImageUrl;
  final String? bio;

  UserProfile({
    required this.uid,
    required this.name,
    required this.major,
    required this.skillsTeach,
    required this.skillsLearn,
    this.profileImageUrl,
    this.bio,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'major': major,
      'skillsTeach': skillsTeach,
      'skillsLearn': skillsLearn,
      'profileImageUrl': profileImageUrl,
      'bio': bio,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'],
      name: map['name'],
      major: map['major'],
      skillsTeach: List<String>.from(map['skillsTeach']),
      skillsLearn: List<String>.from(map['skillsLearn']),
      profileImageUrl: map['profileImageUrl'],
      bio: map['bio'],
    );
  }
}
