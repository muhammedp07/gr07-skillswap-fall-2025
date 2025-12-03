// lib/services/video_call_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/video_call_session.dart';

class VideoCallService {
  VideoCallService._();

  /// Simple singleton: use `VideoCallService.instance` everywhere.
  static final VideoCallService instance = VideoCallService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _collection = 'video_call_sessions';

  /// Create a new video-call session for a given chat.
  ///
  /// [roomId] is the ID we’ll eventually get from the video SDK (e.g. ZEGOCLOUD,
  /// Daily, etc). For now we keep it optional and default to an empty string,
  /// so we can still compile and store the doc.
  Future<VideoCallSession> createSession({
    required String chatId,
    required String hostUserId,
    String? roomId,
  }) async {
    final docRef = _db.collection(_collection).doc();
    final now = DateTime.now();

    // Adjust these field names if your model is slightly different.
    final session = VideoCallSession(
      id: docRef.id,
      chatId: chatId,
      hostUserId: hostUserId,
      participantIds: [hostUserId],
      status: VideoCallStatus.active, // or `.pending` if your enum has that
      createdAt: now,
      endedAt: null,
      roomId: roomId ?? '',
    );

    await docRef.set(session.toMap());
    return session;
  }

  /// Join an existing call (we just track you in the participants array).
  Future<void> joinSession({
    required String sessionId,
    required String userId,
  }) async {
    await _db.collection(_collection).doc(sessionId).update({
      'participantIds': FieldValue.arrayUnion([userId]),
    });
  }

  /// Optionally leave a call without ending it.
  Future<void> leaveSession({
    required String sessionId,
    required String userId,
  }) async {
    await _db.collection(_collection).doc(sessionId).update({
      'participantIds': FieldValue.arrayRemove([userId]),
    });
  }

  /// End the call
  Future<void> endSession({required String sessionId}) async {
    await _db.collection(_collection).doc(sessionId).update({
      'status': VideoCallStatus.ended.name,
      'endedAt': DateTime.now(),
    });
  }

  /// Watch a single session by id (live updates while people join/leave).
  Stream<VideoCallSession?> watchSessionById(String sessionId) {
    return _db.collection(_collection).doc(sessionId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return VideoCallSession.fromMap(snap.id, snap.data()!);
    });
  }

  /// Watch the active call (if any) for a given chat.
  ///
  /// This lets the chat screen show “Join call” / “In call” banners.
  Stream<VideoCallSession?> watchActiveSessionForChat(String chatId) {
    return _db
        .collection(_collection)
        .where('chatId', isEqualTo: chatId)
        .where('status', isEqualTo: VideoCallStatus.active.name)
        .limit(1)
        .snapshots()
        .map((snap) {
          if (snap.docs.isEmpty) return null;
          final doc = snap.docs.first;
          return VideoCallSession.fromMap(doc.id, doc.data());
        });
  }
}
