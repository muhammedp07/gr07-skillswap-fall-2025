// lib/models/video_call_session.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of a video call tied to a chat.
enum VideoCallStatus {
  pending, // created, ring / ready to start
  active, // users currently in call
  ended, // call finished normally
  cancelled, // call cancelled / missed / failed
}

/// Basic representation of a video call session for a given chat.
class VideoCallSession {
  final String id; // Firestore doc id
  final String chatId; // which chat this call belongs to
  final String hostUserId; // user who started the call
  final List<String> participantIds; // all participants (including host)
  final String roomId; // SDK room/channel name
  final VideoCallStatus status;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? endedAt;

  VideoCallSession({
    required this.id,
    required this.chatId,
    required this.hostUserId,
    required this.participantIds,
    required this.roomId,
    required this.status,
    required this.createdAt,
    this.startedAt,
    this.endedAt,
  });

  factory VideoCallSession.fromMap(String id, Map<String, dynamic> map) {
    final rawCreated = map['createdAt'];
    final rawStarted = map['startedAt'];
    final rawEnded = map['endedAt'];

    DateTime _toDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      return DateTime.now();
    }

    final statusString = (map['status'] ?? 'pending') as String;
    final status = VideoCallStatus.values.firstWhere(
      (s) => s.name == statusString,
      orElse: () => VideoCallStatus.pending,
    );

    return VideoCallSession(
      id: id,
      chatId: map['chatId'] ?? '',
      hostUserId: map['hostUserId'] ?? '',
      participantIds: List<String>.from(map['participantIds'] ?? const []),
      roomId: map['roomId'] ?? '',
      status: status,
      createdAt: _toDate(rawCreated),
      startedAt: rawStarted != null ? _toDate(rawStarted) : null,
      endedAt: rawEnded != null ? _toDate(rawEnded) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'hostUserId': hostUserId,
      'participantIds': participantIds,
      'roomId': roomId,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'endedAt': endedAt != null ? Timestamp.fromDate(endedAt!) : null,
    };
  }
}
