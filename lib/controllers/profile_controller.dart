import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_profile.dart';

class ProfileController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

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

  // Method 2: Update user profile
  Future<void> updateUserProfile(UserProfile profile) async {
    if (currentUserId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .update(profile.toMap());
    } catch (e) {
      print("Error updating profile: $e");
      rethrow;
    }
  }

  // Method 3: Upload profile image
  Future<String?> uploadProfileImage(File imageFile) async {
    if (currentUserId == null) return null;

    try {
      final ref = _storage.ref().child('profile_images/$currentUserId.jpg');
      final uploadTask = await ref.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Error uploading image: $e");
      rethrow;
    }
  }

  // Method 4: Sign out (Logout)
  Future<void> signOut() async {
    await _auth.signOut();
  }
}