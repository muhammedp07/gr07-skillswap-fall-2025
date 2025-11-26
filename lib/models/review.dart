// lib/models/review.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String chatId;
  final String fromUserId;
  final String toUserId;
  final int rating; // 1–5 stars
  final String? comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.chatId,
    required this.fromUserId,
    required this.toUserId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory Review.fromMap(String id, Map<String, dynamic> map) {
    final rawCreated = map['createdAt'];

    DateTime createdAt;
    if (rawCreated is Timestamp) {
      createdAt = rawCreated.toDate();
    } else if (rawCreated is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(rawCreated);
    } else {
      createdAt = DateTime.now();
    }

    return Review(
      id: id,
      chatId: map['chatId'] ?? '',
      fromUserId: map['fromUserId'] ?? '',
      toUserId: map['toUserId'] ?? '',
      rating: (map['rating'] ?? 0) as int,
      comment: map['comment'],
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
