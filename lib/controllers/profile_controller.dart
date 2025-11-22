import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';

class ProfileController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get the current user's ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Method 1: Fetch the user's profile data
  Future<UserProfile?> getUserProfile() async {
    if (currentUserId == null) return null;

    try {
      DocumentSnapshot doc = await _firestore
          .collection('users') // This must match the collection name used in ProfileSetupScreen
          .doc(currentUserId)
          .get();

      if (doc.exists && doc.data() != null) {
        return UserProfile.fromMap(doc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      print("Error loading profile: $e");
    }
    return null;
  }

  // Method 2: Sign out (Logout)
  Future<void> signOut() async {
    await _auth.signOut();
  }
}