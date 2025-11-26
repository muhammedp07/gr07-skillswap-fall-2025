// lib/services/review_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/review.dart';

class ReviewService {
  ReviewService._();

  /// Simple singleton pattern: ReviewService.instance
  static final ReviewService instance = ReviewService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String reviewsCollection = 'reviews';

  /// Add (or update) a review for a given chat/fromUser/toUser combo.
  ///
  /// You can call this after a swap is marked completed.
  Future<void> submitReview({
    required String chatId,
    required String fromUserId,
    required String toUserId,
    required int rating, // 1–5
    String? comment,
  }) async {
    // Clamp rating to 1–5 just in case
    final safeRating = rating.clamp(1, 5);

    // We’ll keep reviews unique per (chatId, fromUserId, toUserId)
    final query = await _db
        .collection(reviewsCollection)
        .where('chatId', isEqualTo: chatId)
        .where('fromUserId', isEqualTo: fromUserId)
        .where('toUserId', isEqualTo: toUserId)
        .limit(1)
        .get();

    final now = Timestamp.now();

    if (query.docs.isEmpty) {
      // Create new review
      await _db.collection(reviewsCollection).add({
        'chatId': chatId,
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'rating': safeRating,
        'comment': comment,
        'createdAt': now,
      });
    } else {
      // Update existing review (if they edit it)
      final docId = query.docs.first.id;
      await _db.collection(reviewsCollection).doc(docId).update({
        'rating': safeRating,
        'comment': comment,
        'createdAt': now,
      });
    }
  }

  /// Get all reviews *about* a specific user (they are the person being rated).
  Future<List<SwapReview>> getReviewsForUser(String userId) async {
    final snapshot = await _db
        .collection(reviewsCollection)
        .where('toUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => SwapReview.fromMap(doc.id, doc.data()))
        .toList();
  }

  /// Optionally: watch reviews about a user in real-time (for profile later)
  Stream<List<SwapReview>> watchReviewsForUser(String userId) {
    return _db
        .collection(reviewsCollection)
        .where('toUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => SwapReview.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }
}
