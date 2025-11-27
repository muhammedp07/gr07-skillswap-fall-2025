// lib/services/review_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/review.dart';

/// Small helper model for rating summary (avg + count).
class RatingSummary {
  final double average;
  final int count;

  const RatingSummary({required this.average, required this.count});
}

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

  /// Get a live list of all reviews received by a user.
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

  /// 🔹 NEW: live rating summary (average + count) for a user.
  ///
  /// This is what you'll use in the header to show:
  /// "4.5 ★ • 3 reviews"  or "No reviews yet".
  Stream<RatingSummary> watchRatingForUser(String userId) {
    return _db
        .collection(reviewsCollection)
        .where('toUserId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) {
            return const RatingSummary(average: 0.0, count: 0);
          }

          double sum = 0;
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final rating = (data['rating'] as num?)?.toDouble() ?? 0.0;
            sum += rating;
          }

          final count = snapshot.docs.length;
          final avg = sum / count;
          return RatingSummary(average: avg, count: count);
        });
  }
}
