import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  message,      // "New Message from Sara"
  swapRequest,  // "Abul wants to swap skills"
  swapAccepted, // "Swap Accepted!"
  reviewReminder // "Don't forget to review..."
}

class NotificationModel {
  final String id;
  final String fromUserId; // Who triggered this?
  final String title;
  final String body;
  final NotificationType type;
  final bool isRead;
  final DateTime timestamp;
  final String? relatedId; // Optional: ID of the chat or swap document

  NotificationModel({
    required this.id,
    required this.fromUserId,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.relatedId,
  });

  // Serialization (Consistent with UserProfile.toMap)
  Map<String, dynamic> toMap() {
    return {
      'fromUserId': fromUserId,
      'title': title,
      'body': body,
      'type': type.toString().split('.').last, // Store as string "message"
      'isRead': isRead,
      'timestamp': Timestamp.fromDate(timestamp),
      'relatedId': relatedId,
    };
  }

  // Deserialization (Consistent with UserProfile.fromMap)
  factory NotificationModel.fromMap(Map<String, dynamic> map, String docId) {
    return NotificationModel(
      id: docId,
      fromUserId: map['fromUserId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: _parseType(map['type']),
      isRead: map['isRead'] ?? false,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      relatedId: map['relatedId'],
    );
  }

  static NotificationType _parseType(String? typeStr) {
    return NotificationType.values.firstWhere(
      (e) => e.toString().split('.').last == typeStr,
      orElse: () => NotificationType.message, // Fallback
    );
  }
}