// lib/services/chat_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_models.dart';
import '../models/notification_model.dart';
import 'notification_service.dart';

class ChatService {
  ChatService._();

  /// Simple singleton so we can call ChatService.instance everywhere.
  static final ChatService instance = ChatService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String chatsCollection = 'chats';
  static const String messagesSubcollection = 'messages';

  final NotificationService _notificationService = NotificationService();

  /// Watch all chats where the given user is a member.
  /// We only filter by `members` in Firestore (no orderBy) so we don't need a
  /// composite index. Then we sort by `lastMessageAt` on the client.
  Stream<List<Chat>> watchChatsForUser(String userId) {
    return _db
        .collection(chatsCollection)
        .where('members', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          final chats = snapshot.docs
              .map((doc) => Chat.fromMap(doc.id, doc.data()))
              .toList();

          // Sort newest first on the client
          chats.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));

          return chats;
        });
  }

  /// Watch all messages for a chat.
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
          // if your Chat model has swapStatus, this keeps it in sync:
          'swapStatus': SwapStatus.open.name,
          'swapMarkedByUserId': null,
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

  /// Send a text message AND create a notification for the other user.
  Future<void> sendTextMessageAndNotify({
    required String chatId,
    required String senderId,
    required String recipientId,
    required String text,
    String? imageUrl,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty && (imageUrl == null || imageUrl.isEmpty)) {
      return;
    }

    // 1) send the message (re-use the existing logic)
    await sendTextMessage(
      chatId: chatId,
      senderId: senderId,
      text: trimmed,
      imageUrl: imageUrl,
    );

    // 2) fire an in-app notification for the recipient
    if (senderId == recipientId) return; // just in case

    final preview = trimmed.isEmpty ? 'You received a new message.' : trimmed;

    final notification = NotificationModel(
      id: '', // Firestore will generate it
      fromUserId: senderId,
      title: 'New message in SkillSwap',
      body: preview.length > 80 ? '${preview.substring(0, 80)}…' : preview,
      type: NotificationType.message,
      timestamp: DateTime.now(),
      relatedId: chatId, // so you can navigate to this chat later
    );

    try {
      await _notificationService.sendNotification(recipientId, notification);
    } catch (e) {
      // Don't blow up the whole send if notification fails.
      // In a real app you'd log this.
    }
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
      // keep in sync with Chat model defaults
      'swapStatus': SwapStatus.open.name,
      'swapMarkedByUserId': null,
    });

    return newChatRef.id;
  }

  /// Mark the chat as read for this user (used for chat-level unread lists).
  Future<void> markChatAsRead({
    required String chatId,
    required String userId,
  }) async {
    try {
      await _db.collection(chatsCollection).doc(chatId).update({
        'unreadFor': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      // optional: log for debugging
    }
  }

  /// Watch just the last message in a chat (for unread indicator).
  Stream<ChatMessage?> watchLastMessage(String chatId) {
    return _db
        .collection(chatsCollection)
        .doc(chatId)
        .collection(messagesSubcollection)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          final doc = snapshot.docs.first;
          return ChatMessage.fromMap(doc.id, doc.data());
        });
  }

  /// Mark a single message as read by a user.
  Future<void> markMessageRead({
    required String chatId,
    required String messageId,
    required String userId,
  }) async {
    final msgRef = _db
        .collection(chatsCollection)
        .doc(chatId)
        .collection(messagesSubcollection)
        .doc(messageId);

    await msgRef.update({
      'readBy': FieldValue.arrayUnion([userId]),
    });
  }
}
