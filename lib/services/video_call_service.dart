// lib/services/video_call_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/video_call_session.dart';

class VideoCallService {
  VideoCallService._();

  static final VideoCallService instance = VideoCallService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'video_call_sessions';

  /// Create a new video call session for a chat.
  Future<VideoCallSession> createSession({
    required String chatId,
    required String hostUserId,
    String? sdkRoomId, // can be wired to Zego later
  }) async {
    final docRef = _db.collection(_collection).doc();
    final now = DateTime.now();

    final session = VideoCallSession(
      id: docRef.id,
      chatId: chatId,
      hostUserId: hostUserId,
      participantIds: [hostUserId],
      status: VideoCallStatus.active,
      createdAt: now,
      endedAt: null,
      sdkRoomId: sdkRoomId,
    );

    await docRef.set(session.toMap());
    return session;
  }

  /// Try to reuse an active session for this chat, otherwise create one.
  Future<VideoCallSession> createOrGetActiveSession({
    required String chatId,
    required String hostUserId,
  }) async {
    // look for an active session for this chat
    final snap = await _db
        .collection(_collection)
        .where('chatId', isEqualTo: chatId)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      final doc = snap.docs.first;
      return VideoCallSession.fromMap(doc.id, doc.data());
    }

    // nothing active, make a new one
    return createSession(
      chatId: chatId,
      hostUserId: hostUserId,
      sdkRoomId: null,
    );
  }

  /// Watch a single session (to see join/leave, end, etc.).
  Stream<VideoCallSession?> watchSession(String sessionId) {
    return _db.collection(_collection).doc(sessionId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return VideoCallSession.fromMap(snap.id, snap.data()!);
    });
  }

  /// Mark the call as ended.
  Future<void> endSession(String sessionId) async {
    await _db.collection(_collection).doc(sessionId).update({
      'status': 'ended',
      'endedAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}
