import 'package:cloud_firestore/cloud_firestore.dart';

class SwapSession {
  final String id;
  final String postId;
  final String chatId;
  final List<String> participantIds;
  final String initiatorId;
  final DateTime scheduledTime;
  final Duration duration;
  final String location;
  final String status; // 'scheduled', 'completed', 'cancelled'
  final String? notes;
  final DateTime createdAt;

  SwapSession({
    required this.id,
    required this.postId,
    required this.chatId,
    required this.participantIds,
    required this.initiatorId,
    required this.scheduledTime,
    required this.duration,
    required this.location,
    this.status = 'scheduled',
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'chatId': chatId,
      'participantIds': participantIds,
      'initiatorId': initiatorId,
      'scheduledTime': Timestamp.fromDate(scheduledTime),
      'durationInMinutes': duration.inMinutes,
      'location': location,
      'status': status,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory SwapSession.fromMap(String id, Map<String, dynamic> map) {
    return SwapSession(
      id: id,
      postId: map['postId'] ?? '',
      chatId: map['chatId'] ?? '',
      participantIds: List<String>.from(map['participantIds'] ?? []),
      initiatorId: map['initiatorId'] ?? '',
      scheduledTime: (map['scheduledTime'] as Timestamp).toDate(),
      duration: Duration(minutes: map['durationInMinutes'] ?? 60),
      location: map['location'] ?? '',
      status: map['status'] ?? 'scheduled',
      notes: map['notes'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  bool get isUpcoming => scheduledTime.isAfter(DateTime.now()) && status == 'scheduled';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
}