import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_models.dart';

class ChatService {
  ChatService._();

  /// Simple singleton so we can call ChatService.instance everywhere.
  static final ChatService instance = ChatService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String chatsCollection = 'chats';
  static const String messagesSubcollection = 'messages';

  /// Watch all chats where the given user is a member.
  Stream<List<Chat>> watchChatsForUser(String userId) {
    return _db
        .collection(chatsCollection)
        .where('members', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Chat.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Watch all messages for a chat (we'll use this later).
  Stream<List<ChatMessage>> watchMessages(String chatId) {
    return _db
        .collection(chatsCollection)
        .doc(chatId)
        .collection(messagesSubcollection)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatMessage.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Send a simple text message (image/file can be added later).
  Future<void> sendTextMessage({
    required String chatId,
    required String senderId,
    required String text,
    String? imageUrl,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty && (imageUrl == null || imageUrl.isEmpty)) {
      return; // nothing to send
    }

    final chatRef = _db.collection(chatsCollection).doc(chatId);
    final messagesRef = chatRef.collection(messagesSubcollection).doc();
    final now = Timestamp.now();

    await _db.runTransaction((txn) async {
      final chatSnap = await txn.get(chatRef);

      // If the chat doc doesn't exist yet, create a very basic one.
      if (!chatSnap.exists) {
        txn.set(chatRef, {
          'members': [senderId], // we'll add the other user later
          'lastMessage': trimmed,
          'lastMessageAt': now,
          'lastMessageSenderId': senderId,
          'postId': null,
        });
      } else {
        txn.update(chatRef, {
          'lastMessage': trimmed,
          'lastMessageAt': now,
          'lastMessageSenderId': senderId,
        });
      }

      txn.set(messagesRef, {
        'chatId': chatId,
        'senderId': senderId,
        'text': trimmed,
        'imageUrl': imageUrl,
        'createdAt': now,
        'readBy': [senderId],
      });
    });
  }

  /// Create a chat for a given post (or return the existing one)
  /// between the current user and the owner of the post.
  ///
  /// Returns the chatId to navigate to.
  Future<String> createOrGetChatForPost({
    required String currentUserId,
    required String otherUserId,
    required String postId,
  }) async {
    final chatsRef = _db.collection(chatsCollection);

    // 1) Look for an existing chat with BOTH users and this postId
    final existing = await chatsRef
        .where('members', arrayContains: currentUserId)
        .where('postId', isEqualTo: postId)
        .get();

    for (final doc in existing.docs) {
      final data = doc.data();
      final members = List<String>.from(data['members'] ?? []);
      if (members.contains(otherUserId)) {
        // found a matching chat
        return doc.id;
      }
    }

    // 2) If not found, create a new chat doc
    final now = Timestamp.now();
    final newChatRef = chatsRef.doc();

    await newChatRef.set({
      'members': [currentUserId, otherUserId],
      'lastMessage': '',
      'lastMessageAt': now,
      'lastMessageSenderId': currentUserId,
      'postId': postId,
    });

    return newChatRef.id;
  }
}
