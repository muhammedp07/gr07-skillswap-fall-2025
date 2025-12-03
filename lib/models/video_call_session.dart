// lib/models/video_call_session.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum VideoCallStatus { active, ended }

class VideoCallSession {
  final String id;
  final String chatId;
  final String hostUserId;
  final List<String> participantIds;
  final VideoCallStatus status;
  final DateTime createdAt;
  final DateTime? endedAt;
  final String? sdkRoomId; // Zego room ID we’ll join with

  VideoCallSession({
    required this.id,
    required this.chatId,
    required this.hostUserId,
    required this.participantIds,
    required this.status,
    required this.createdAt,
    this.endedAt,
    this.sdkRoomId,
  });

  factory VideoCallSession.fromMap(String id, Map<String, dynamic> map) {
    final tsCreated = map['createdAt'];
    final tsEnded = map['endedAt'];

    return VideoCallSession(
      id: id,
      chatId: map['chatId'] ?? '',
      hostUserId: map['hostUserId'] ?? '',
      participantIds: List<String>.from(map['participantIds'] ?? const []),
      status: (map['status'] == 'ended')
          ? VideoCallStatus.ended
          : VideoCallStatus.active,
      createdAt: tsCreated is Timestamp
          ? tsCreated.toDate()
          : DateTime.fromMillisecondsSinceEpoch(
              (tsCreated ?? 0) as int,
              isUtc: true,
            ),
      endedAt: tsEnded is Timestamp ? tsEnded.toDate() : null,
      sdkRoomId: map['sdkRoomId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'hostUserId': hostUserId,
      'participantIds': participantIds,
      'status': status == VideoCallStatus.ended ? 'ended' : 'active',
      'createdAt': Timestamp.fromDate(createdAt),
      'endedAt': endedAt != null ? Timestamp.fromDate(endedAt!) : null,
      'sdkRoomId': sdkRoomId,
    };
  }
}
