import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Getter to access the db instance
  FirebaseFirestore get db => _db;

  Future<void> saveUserProfile(UserProfile profile) async {
    await _db.collection('users').doc(profile.uid).set(profile.toMap());
  }

  // Update user profile with new skills
  Future<void> updateUserProfile(UserProfile profile) async {
    await _db.collection('users').doc(profile.uid).update(profile.toMap());
  }

  Future<bool> doesProfileExist() async {
    final uid = _auth.currentUser!.uid;
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists;
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserProfile.fromMap(doc.data()!);
    }
    return null;
  }

  // Get current user profile (convenience method)
  Future<UserProfile?> getCurrentUserProfile() async {
    final uid = _auth.currentUser!.uid;
    return await getUserProfile(uid);
  }

  // Search users by name or major
  Stream<List<UserProfile>> searchUsers(String query) {
    return _db.collection('users')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserProfile.fromMap(doc.data()))
            .where((user) =>
                user.name.toLowerCase().contains(query.toLowerCase()) ||
                user.major.toLowerCase().contains(query.toLowerCase()))
            .toList());
  }

  // Update specific skills for a user
  Future<void> updateUserSkills({
    required String uid,
    List<String>? skillsTeach,
    List<String>? skillsLearn,
  }) async {
    final updateData = <String, dynamic>{};
    
    if (skillsTeach != null) {
      updateData['skillsTeach'] = skillsTeach;
    }
    
    if (skillsLearn != null) {
      updateData['skillsLearn'] = skillsLearn;
    }
    
    await _db.collection('users').doc(uid).update(updateData);
  }
}