import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post.dart';

class PostService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new post
  Future<void> createPost(Post post) async {
    await _db.collection('posts').doc(post.id).set(post.toMap());
  }

  // Get all posts (with real-time updates)
  Stream<List<Post>> getPostsStream() {
    return _db.collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Post.fromMap(doc.data()))
            .toList());
  }

  // Get posts filtered by skills (for intelligent matching)
  Stream<List<Post>> getPostsForUser(List<String> userSkillsTeach, List<String> userSkillsLearn) {
    return _db.collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final allPosts = snapshot.docs.map((doc) => Post.fromMap(doc.data())).toList();
          
          // Sort posts by relevance (posts that match user's interests first)
          allPosts.sort((a, b) {
            final scoreA = _calculateRelevanceScore(a, userSkillsTeach, userSkillsLearn);
            final scoreB = _calculateRelevanceScore(b, userSkillsTeach, userSkillsLearn);
            return scoreB.compareTo(scoreA);
          });
          
          return allPosts;
        });
  }

  // Calculate how relevant a post is to the current user
  int _calculateRelevanceScore(Post post, List<String> userSkillsTeach, List<String> userSkillsLearn) {
    int score = 0;
    
    // User can teach what the post wants to learn
    for (String skill in post.skillsLearn) {
      if (userSkillsTeach.contains(skill)) score += 2;
    }
    
    // User wants to learn what the post can teach
    for (String skill in post.skillsTeach) {
      if (userSkillsLearn.contains(skill)) score += 2;
    }
    
    return score;
  }

  // Search posts by skill, name, or major
  Stream<List<Post>> searchPosts(String query) {
    return _db.collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Post.fromMap(doc.data()))
            .where((post) =>
                post.skillsTeach.any((skill) => skill.toLowerCase().contains(query.toLowerCase())) ||
                post.skillsLearn.any((skill) => skill.toLowerCase().contains(query.toLowerCase())) ||
                post.userName.toLowerCase().contains(query.toLowerCase()) ||
                (post.userMajor.toLowerCase().contains(query.toLowerCase())))
            .toList());
  }

  // Delete a post
  Future<void> deletePost(String postId) async {
    final userId = _auth.currentUser!.uid;
    final postDoc = await _db.collection('posts').doc(postId).get();
    
    if (postDoc.exists && postDoc.data()!['userId'] == userId) {
      await _db.collection('posts').doc(postId).delete();
    } else {
      throw Exception('You can only delete your own posts');
    }
  }

  // Get posts by a specific user
  Stream<List<Post>> getPostsByUser(String userId) {
    return _db.collection('posts')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Post.fromMap(doc.data()))
            .toList());
  }

  // Update a post
  Future<void> updatePost(Post post) async {
    final userId = _auth.currentUser!.uid;
    final postDoc = await _db.collection('posts').doc(post.id).get();
    
    if (postDoc.exists && postDoc.data()!['userId'] == userId) {
      await _db.collection('posts').doc(post.id).update(post.toMap());
    } else {
      throw Exception('You can only update your own posts');
    }
  }
}