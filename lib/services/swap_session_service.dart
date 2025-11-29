// services/swap_session_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/swap_session.dart';

class SwapSessionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createSwapSession(SwapSession session) async {
    await _db.collection('swap_sessions').doc(session.id).set(session.toMap());
  }

  // Existing method that might cause index error
  Stream<List<SwapSession>> getSessionsForUser(String userId) {
    return _db
        .collection('swap_sessions')
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          final sessions = snapshot.docs
              .map((doc) => SwapSession.fromMap(doc.id, doc.data()))
              .toList();

          // Sort on the client side
          sessions.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
          return sessions;
        });
  }

  // Alternative method without complex query (no index needed)
  Stream<List<SwapSession>> getSessionsForUserSimple(String userId) {
    return _db
        .collection('swap_sessions')
        .snapshots()
        .map((snapshot) {
          final sessions = snapshot.docs
              .map((doc) => SwapSession.fromMap(doc.id, doc.data()))
              .where((session) => session.participantIds.contains(userId))
              .toList();

          // Sort on the client side
          sessions.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
          return sessions;
        });
  }

  Stream<List<SwapSession>> getUpcomingSessionsForUser(String userId) {
    return getSessionsForUser(userId).map(
      (sessions) => sessions.where((session) => session.isUpcoming).toList(),
    );
  }

  Future<void> updateSessionStatus(String sessionId, String status) async {
    await _db.collection('swap_sessions').doc(sessionId).update({
      'status': status,
    });
  }

  Future<void> addSessionNote(String sessionId, String note) async {
    await _db.collection('swap_sessions').doc(sessionId).update({
      'notes': note,
    });
  }

  Future<void> deleteSession(String sessionId) async {
    await _db.collection('swap_sessions').doc(sessionId).delete();
  }
}
