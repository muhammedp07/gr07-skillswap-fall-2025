// lib/services/review_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/review.dart';

class ReviewService {
  ReviewService._();

  static final ReviewService instance = ReviewService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String reviewsCollection = 'reviews';

  /// Submit a review for a completed swap.
  Future<void> submitReview({
    required String chatId,
    required String fromUserId,
    required String toUserId,
    required int rating,
    String? comment,
  }) async {
    // Basic sanity check
    if (rating < 1 || rating > 5) {
      throw ArgumentError('Rating must be between 1 and 5');
    }

    final now = DateTime.now();
    final docRef = _db.collection(reviewsCollection).doc();

    final review = Review(
      id: docRef.id,
      chatId: chatId,
      fromUserId: fromUserId,
      toUserId: toUserId,
      rating: rating,
      comment: (comment != null && comment.trim().isNotEmpty)
          ? comment.trim()
          : null,
      createdAt: now,
    );

    await docRef.set(review.toMap());
  }

  /// Optionally: get all reviews received by a user (for later profile stats).
  Stream<List<Review>> watchReviewsForUser(String userId) {
    return _db
        .collection(reviewsCollection)
        .where('toUserId', isEqualTo: userId)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => Review.fromMap(d.id, d.data())).toList(),
        );
  }
}
