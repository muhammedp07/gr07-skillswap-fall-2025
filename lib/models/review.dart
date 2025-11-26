// lib/models/review.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// A rating / review given after a SkillSwap
class SwapReview {
  final String id; // Firestore doc id
  final String chatId; // which chat this review belongs to
  final String fromUserId; // who wrote the review
  final String toUserId; // who is being reviewed
  final int rating; // 1–5 stars
  final String? comment; // optional text feedback
  final DateTime createdAt;

  SwapReview({
    required this.id,
    required this.chatId,
    required this.fromUserId,
    required this.toUserId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory SwapReview.fromMap(String id, Map<String, dynamic> map) {
    final rawCreated = map['createdAt'];
    DateTime createdAt;

    if (rawCreated is Timestamp) {
      createdAt = rawCreated.toDate();
    } else if (rawCreated is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(rawCreated);
    } else {
      createdAt = DateTime.now();
    }

    return SwapReview(
      id: id,
      chatId: map['chatId'] as String? ?? '',
      fromUserId: map['fromUserId'] as String? ?? '',
      toUserId: map['toUserId'] as String? ?? '',
      rating: (map['rating'] as num?)?.toInt() ?? 0,
      comment: map['comment'] as String?,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
