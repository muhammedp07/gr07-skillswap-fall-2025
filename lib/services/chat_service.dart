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
    required String senderName,
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
      fromUserName: senderName,
      title: 'New message from $senderName',
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

  /// Update the SkillSwap status for a chat (open/completed, etc).
  Future<void> setSwapStatus({
    required String chatId,
    required SwapStatus status,
    String? markedByUserId,
  }) async {
    try {
      final data = <String, dynamic>{'swapStatus': status.name};

      // Optional: track which user marked it as done
      if (markedByUserId != null) {
        data['swapMarkedByUserId'] = markedByUserId;
      }

      await _db.collection(chatsCollection).doc(chatId).update(data);
    } catch (e) {
      // optional: log for debugging
    }
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
    } catch (e) {
      // optional: log error
      // debugPrint('Failed to update swap status: $e');
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

  /// Watch a single chat document by id (for swap status, etc).
  Stream<Chat?> watchChat(String chatId) {
    return _db.collection(chatsCollection).doc(chatId).snapshots().map((
      docSnap,
    ) {
      if (!docSnap.exists) return null;
      return Chat.fromMap(docSnap.id, docSnap.data()!);
    });
  }

  /// Delete a single message from a chat.
  /// Only the message sender should be allowed to delete their own messages.
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

    // Update the chat's lastMessage if we deleted the most recent one
    final latestMessages = await _db
        .collection(chatsCollection)
        .doc(chatId)
        .collection(messagesSubcollection)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (latestMessages.docs.isNotEmpty) {
      final latestMsg = latestMessages.docs.first.data();
      await _db.collection(chatsCollection).doc(chatId).update({
        'lastMessage': latestMsg['text'] ?? '',
        'lastMessageAt': latestMsg['createdAt'],
        'lastMessageSenderId': latestMsg['senderId'],
      });
    } else {
      // No messages left, reset the lastMessage fields
      await _db.collection(chatsCollection).doc(chatId).update({
        'lastMessage': '',
        'lastMessageAt': Timestamp.now(),
        'lastMessageSenderId': null,
      });
    }
  }

  /// Delete an entire chat thread and all its messages.
  /// This will remove the chat document and all messages in the subcollection.
  Future<void> deleteChat(String chatId) async {
    final chatRef = _db.collection(chatsCollection).doc(chatId);
    final messagesRef = chatRef.collection(messagesSubcollection);

    // First, delete all messages in the subcollection
    final messagesSnapshot = await messagesRef.get();
    final batch = _db.batch();

    for (final doc in messagesSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Then delete the chat document itself
    batch.delete(chatRef);

    await batch.commit();
  }

  /// Check if a chat already exists between two users (regardless of postId).
  /// Returns the existing chatId if found, null otherwise.
  Future<String?> getExistingChatBetweenUsers({
    required String userId1,
    required String userId2,
  }) async {
    final chatsRef = _db.collection(chatsCollection);

    // Query for chats that contain userId1
    final existing = await chatsRef
        .where('members', arrayContains: userId1)
        .get();

    for (final doc in existing.docs) {
      final data = doc.data();
      final members = List<String>.from(data['members'] ?? []);
      if (members.contains(userId2)) {
        // found a matching chat between the two users
        return doc.id;
      }
    }

    return null;
  }

  /// Create a chat for a given post (or return the existing one)
  /// between the current user and the owner of the post.
  /// This will return an existing chat if one already exists between the two users.
  ///
  /// Returns the chatId to navigate to.
  Future<String> createOrGetChatBetweenUsers({
    required String currentUserId,
    required String otherUserId,
    String? postId,
  }) async {
    // First check if there's already a chat between these two users
    final existingChatId = await getExistingChatBetweenUsers(
      userId1: currentUserId,
      userId2: otherUserId,
    );

    if (existingChatId != null) {
      return existingChatId;
    }

    // If not found, create a new chat doc
    final chatsRef = _db.collection(chatsCollection);
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
}
