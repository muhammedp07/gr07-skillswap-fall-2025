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
  Stream<List<Chat>> watchChatsForUser(String userId) {
    return _db
        .collection(chatsCollection)
        .where('members', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          final chats = snapshot.docs
              .map((doc) => Chat.fromMap(doc.id, doc.data()))
              .toList();

          // newest first
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

  /// Send a simple text message (image/file can be attached).
  Future<void> sendTextMessage({
    required String chatId,
    required String senderId,
    required String text,
    String? imageUrl,
    String? attachmentUrl,
    String? attachmentType,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty && (imageUrl == null || imageUrl.isEmpty) && (attachmentUrl == null || attachmentUrl.isEmpty)) {
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
        'attachmentUrl': attachmentUrl,
        'attachmentType': attachmentType,
        'createdAt': now,
        'readBy': [senderId],
      });
    });
  }

  /// Send a text message AND create a notification for the other user.
  ///
  /// NOTE: senderName is used in the notification.
  Future<void> sendTextMessageAndNotify({
    required String chatId,
    required String senderId,
    required String recipientId,
    required String text,
    required String senderName,
    String? imageUrl,
    String? attachmentUrl,
    String? attachmentType,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty && (imageUrl == null || imageUrl.isEmpty) && (attachmentUrl == null || attachmentUrl.isEmpty)) {
      return;
    }

    // 1) send the message
    await sendTextMessage(
      chatId: chatId,
      senderId: senderId,
      text: trimmed,
      imageUrl: imageUrl,
      attachmentUrl: attachmentUrl,
      attachmentType: attachmentType,
    );

    // 2) in-app notification for the recipient
    if (senderId == recipientId) return;

    final preview = trimmed.isEmpty ? 'You received a new message.' : trimmed;

    final notification = NotificationModel(
      id: '',
      fromUserId: senderId,
      fromUserName: senderName,
      title: senderName.isEmpty
          ? 'New message in SkillSwap'
          : '$senderName sent you a message',
      body: preview.length > 80 ? '${preview.substring(0, 80)}…' : preview,
      type: NotificationType.message,
      timestamp: DateTime.now(),
      relatedId: chatId,
    );

    try {
      await _notificationService.sendNotification(recipientId, notification);
    } catch (_) {
      // don't crash if notification fails
    }
  }

  /// Create a chat for a given post (or return the existing one)
  /// between the current user and the owner of the post.
  Future<String> createOrGetChatForPost({
    required String currentUserId,
    required String otherUserId,
    required String postId,
  }) async {
    final chatsRef = _db.collection(chatsCollection);

    final existing = await chatsRef
        .where('members', arrayContains: currentUserId)
        .where('postId', isEqualTo: postId)
        .get();

    for (final doc in existing.docs) {
      final data = doc.data();
      final members = List<String>.from(data['members'] ?? []);
      if (members.contains(otherUserId)) {
        return doc.id;
      }
    }

    final now = Timestamp.now();
    final newChatRef = chatsRef.doc();

    await newChatRef.set({
      'members': [currentUserId, otherUserId],
      'lastMessage': '',
      'lastMessageAt': now,
      'lastMessageSenderId': currentUserId,
      'postId': postId,
      'swapStatus': SwapStatus.open.name,
      'swapMarkedByUserId': null,
    });

    return newChatRef.id;
  }

  /// Convenience wrapper used by FeedScreen.
  Future<String> createOrGetChatBetweenUsers({
    required String postId,
    required String currentUserId,
    required String otherUserId,
  }) {
    return createOrGetChatForPost(
      currentUserId: currentUserId,
      otherUserId: otherUserId,
      postId: postId,
    );
  }

  /// Mark the chat as read for this user.
  Future<void> markChatAsRead({
    required String chatId,
    required String userId,
  }) async {
    try {
      await _db.collection(chatsCollection).doc(chatId).update({
        'unreadFor': FieldValue.arrayRemove([userId]),
      });
    } catch (_) {}
  }

  /// Update the SkillSwap status for a chat (open/completed, etc).
  Future<void> setSwapStatus({
    required String chatId,
    required SwapStatus status,
    String? markedByUserId,
  }) async {
    try {
      final data = <String, dynamic>{'swapStatus': status.name};
      if (markedByUserId != null) {
        data['swapMarkedByUserId'] = markedByUserId;
      }
      await _db.collection(chatsCollection).doc(chatId).update(data);
    } catch (_) {}
  }

  /// Update the swap status for a chat (e.g. mark as completed).
  Future<void> updateSwapStatus({
    required String chatId,
    required SwapStatus status,
    required String markedByUserId,
  }) async {
    try {
      await _db.collection(chatsCollection).doc(chatId).update({
        'swapStatus': status.name,
        'swapMarkedByUserId': markedByUserId,
      });
    } catch (_) {}
  }

  /// Watch just the last message in a chat.
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

  /// Watch a single chat document by id (for swap status, etc).
  Stream<Chat?> watchChat(String chatId) {
    return _db.collection(chatsCollection).doc(chatId).snapshots().map((
      docSnap,
    ) {
      if (!docSnap.exists) return null;
      return Chat.fromMap(docSnap.id, docSnap.data()!);
    });
  }

  /// Delete an entire chat (all messages + chat doc).
  Future<void> deleteChat(String chatId) async {
    final chatRef = _db.collection(chatsCollection).doc(chatId);
    final messagesRef = chatRef.collection(messagesSubcollection);

    final messagesSnap = await messagesRef.get();
    final batch = _db.batch();

    for (final doc in messagesSnap.docs) {
      batch.delete(doc.reference);
    }

    batch.delete(chatRef);
    await batch.commit();
  }

  /// Delete a single message.
  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
  }) async {
    final msgRef = _db
        .collection(chatsCollection)
        .doc(chatId)
        .collection(messagesSubcollection)
        .doc(messageId);

    await msgRef.delete();
  }
}
