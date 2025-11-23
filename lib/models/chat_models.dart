// lib/models/chat_models.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  final String id;
  final List<String> memberIds; // uids of users in the chat (usually 2)
  final String lastMessage;
  final DateTime lastMessageAt;
  final String lastMessageSenderId;
  final String? postId; // optional: skill swap post that started this chat

  Chat({
    required this.id,
    required this.memberIds,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.lastMessageSenderId,
    this.postId,
  });

  Map<String, dynamic> toMap() {
    return {
      'members': memberIds,
      'lastMessage': lastMessage,
      'lastMessageAt': Timestamp.fromDate(lastMessageAt),
      'lastMessageSenderId': lastMessageSenderId,
      'postId': postId,
    };
  }

  factory Chat.fromMap(String id, Map<String, dynamic> map) {
    return Chat(
      id: id,
      memberIds: List<String>.from(map['members'] ?? []),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageAt: (map['lastMessageAt'] as Timestamp).toDate(),
      lastMessageSenderId: map['lastMessageSenderId'] ?? '',
      postId: map['postId'],
    );
  }
}

class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String text;
  final String? imageUrl;
  final DateTime createdAt;
  final List<String> readBy;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    this.imageUrl,
    required this.createdAt,
    this.readBy = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'text': text,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'readBy': readBy,
    };
  }

  factory ChatMessage.fromMap(String id, Map<String, dynamic> map) {
    return ChatMessage(
      id: id,
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      imageUrl: map['imageUrl'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      readBy: List<String>.from(map['readBy'] ?? []),
    );
  }
}

/// Pretend current user has this uid (we'll replace with real auth later).
const String dummyCurrentUserId = 'user_me';

final List<Chat> dummyChats = [
  Chat(
    id: 'chat1',
    memberIds: ['user_me', 'user_jane'],
    lastMessage: 'Sounds great! See you then.',
    lastMessageAt: DateTime.now().subtract(const Duration(minutes: 2)),
    lastMessageSenderId: 'user_jane',
    postId: 'post_flutter_help',
  ),
  Chat(
    id: 'chat2',
    memberIds: ['user_me', 'user_john'],
    lastMessage: 'Hey, I am interested in the guitar lesson.',
    lastMessageAt: DateTime.now().subtract(const Duration(hours: 1)),
    lastMessageSenderId: 'user_me',
    postId: 'post_guitar_lesson',
  ),
  Chat(
    id: 'chat3',
    memberIds: ['user_me', 'user_emily'],
    lastMessage: 'Perfect, see you then!',
    lastMessageAt: DateTime.now().subtract(const Duration(days: 1)),
    lastMessageSenderId: 'user_emily',
    postId: 'post_spanish_help',
  ),
];

final Map<String, List<ChatMessage>> dummyMessagesByChatId = {
  'chat1': [
    ChatMessage(
      id: 'm1',
      chatId: 'chat1',
      senderId: 'user_jane',
      text:
          'Hey! Are you free to meet tomorrow to discuss the Flutter project?',
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    ChatMessage(
      id: 'm2',
      chatId: 'chat1',
      senderId: dummyCurrentUserId,
      text: 'Hi Jane! Yes, I am. How about 2 PM at the library?',
      createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
    ),
    ChatMessage(
      id: 'm3',
      chatId: 'chat1',
      senderId: 'user_jane',
      text: 'Sounds perfect! See you then.',
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
  ],
  'chat2': [
    ChatMessage(
      id: 'm4',
      chatId: 'chat2',
      senderId: dummyCurrentUserId,
      text: 'Hey, I am interested in the guitar lesson.',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ],
  'chat3': [
    ChatMessage(
      id: 'm5',
      chatId: 'chat3',
      senderId: 'user_emily',
      text: 'Perfect, see you then!',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ],
};
