import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BadgeService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> updateHelperBadge(int swapsCompleted) async {
    if (swapsCompleted >= 5) {
      await _updateBadge("helper", true);
    }
  }

  Future<void> updateTopTeacherBadge(int goodReviews) async {
    if (goodReviews >= 5) {
      await _updateBadge("topTeacher", true);
    }
  }

  Future<void> updateActiveUserBadge(int loginStreak) async {
    if (loginStreak >= 7) {
      await _updateBadge("activeUser", true);
    }
  }

  Future<void> _updateBadge(String badge, bool value) async {
    final uid = _auth.currentUser!.uid;
    await _firestore.collection("users").doc(uid).update({
      "badges.$badge": value,
    });
  }
}
