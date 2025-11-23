class Post {
  final String id;
  final String userId;
  final String userName;
  final String userMajor;
  final List<String> skillsTeach;
  final List<String> skillsLearn;
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userMajor': userMajor,
      'skillsTeach': skillsTeach,
      'skillsLearn': skillsLearn,
      'description': description,
      'availability': availability,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map['id'],
      userId: map['userId'],
      userName: map['userName'],
      userMajor: map['userMajor'],
      skillsTeach: List<String>.from(map['skillsTeach']),
      skillsLearn: List<String>.from(map['skillsLearn']),
      description: map['description'],
      availability: map['availability'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }
}