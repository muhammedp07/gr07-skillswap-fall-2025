// In services/bookmark_service.dart - Ensure the stream method exists

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gr07_skillswap/models/post.dart';

class BookmarkService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> toggleBookmark(String userId, String postId) async {
    final bookmarkRef = _db
        .collection('users')
        .doc(userId)
        .collection('bookmarks')
        .doc(postId);

    final bookmark = await bookmarkRef.get();
    
    if (bookmark.exists) {
      await bookmarkRef.delete();
    } else {
      await bookmarkRef.set({
        'postId': postId,
        'savedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<bool> isBookmarked(String userId, String postId) async {
    final bookmark = await _db
        .collection('users')
        .doc(userId)
        .collection('bookmarks')
        .doc(postId)
        .get();
    
    return bookmark.exists;
  }

  // ADD THIS METHOD - This is crucial for the stream to work
  Stream<bool> isBookmarkedStream(String userId, String postId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('bookmarks')
        .doc(postId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  Stream<List<String>> getUserBookmarks(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('bookmarks')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  Stream<List<Post>> getBookmarkedPosts(String userId) {
    return getUserBookmarks(userId).asyncMap((bookmarkIds) async {
      if (bookmarkIds.isEmpty) return [];
      
      final postsSnapshot = await _db
          .collection('posts')
          .where(FieldPath.documentId, whereIn: bookmarkIds)
          .get();
      
      return postsSnapshot.docs
          .map((doc) => Post.fromMap(doc.data()))
          .toList();
    });
  }
}