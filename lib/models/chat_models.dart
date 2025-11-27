// lib/models/chat_models.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of a SkillSwap inside a chat
enum SwapStatus {
  open, // default: swap still ongoing / not confirmed done
  completed, // swap marked as done
}

/// Simple model for a chat conversation.
class Chat {
  final String id;
  final List<String> members; // userIds in this chat
  final String lastMessage;
  final DateTime lastMessageAt;
  final String lastMessageSenderId;
  final List<String> unreadFor;
  final String? postId; // optional: SkillSwap post this chat is about
  final SwapStatus swapStatus;

  Chat({
    required this.id,
    required this.members,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.lastMessageSenderId,
    this.unreadFor = const [],
    this.postId,
    this.swapStatus = SwapStatus.open,
  });

  factory Chat.fromMap(String id, Map<String, dynamic> map) {
    final rawLastAt = map['lastMessageAt'];

    DateTime lastAt;
    if (rawLastAt is Timestamp) {
      lastAt = rawLastAt.toDate();
    } else if (rawLastAt is int) {
      lastAt = DateTime.fromMillisecondsSinceEpoch(rawLastAt);
    } else {
      lastAt = DateTime.now();
    }

    final String rawStatus = (map['swapStatus'] ?? 'open') as String;
    final SwapStatus status = SwapStatus.values.firstWhere(
      (s) => s.name == rawStatus,
      orElse: () => SwapStatus.open,
    );

    return Chat(
      id: id,
      members: List<String>.from(map['members'] ?? const []),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageAt: lastAt,
      lastMessageSenderId: map['lastMessageSenderId'] ?? '',
      postId: map['postId'],
      swapStatus: status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'members': members,
      'lastMessage': lastMessage,
      'lastMessageAt': Timestamp.fromDate(lastMessageAt),
      'lastMessageSenderId': lastMessageSenderId,
      'postId': postId,
      'swapStatus': swapStatus.name,
    };
  }
}

/// Model for a single chat message.
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
    required this.readBy,
  });

  factory ChatMessage.fromMap(String id, Map<String, dynamic> map) {
    final rawCreated = map['createdAt'];

    DateTime createdAt;
    if (rawCreated is Timestamp) {
      createdAt = rawCreated.toDate();
    } else if (rawCreated is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(rawCreated);
    } else {
      createdAt = DateTime.now();
    }

    return ChatMessage(
      id: id,
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      imageUrl: map['imageUrl'],
      createdAt: createdAt,
      readBy: List<String>.from(map['readBy'] ?? const []),
    );
  }

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
}

/// Dummy current user id used for local data / preview.
const String dummyCurrentUserId = 'user_me';

/// Dummy chats for UI when Firestore is empty.
final List<Chat> dummyChats = [
  Chat(
    id: 'chat_jane',
    members: ['user_me', 'user_jane'],
    lastMessage: 'Sounds great! See you then.',
    lastMessageAt: DateTime.now().subtract(const Duration(minutes: 2)),
    lastMessageSenderId: 'user_jane',
    postId: 'post_jane_flutter',
    swapStatus: SwapStatus.open,
  ),
  Chat(
    id: 'chat_john',
    members: ['user_me', 'user_john'],
    lastMessage: 'Hey, I am interested in the guitar lesson.',
    lastMessageAt: DateTime.now().subtract(const Duration(hours: 1)),
    lastMessageSenderId: 'user_me',
    postId: 'post_john_guitar',
    swapStatus: SwapStatus.open,
  ),
  Chat(
    id: 'chat_emily',
    members: ['user_me', 'user_emily'],
    lastMessage: 'Perfect, see you then!',
    lastMessageAt: DateTime.now().subtract(const Duration(days: 1)),
    lastMessageSenderId: 'user_emily',
    postId: 'post_emily_spanish',
    swapStatus: SwapStatus.completed,
  ),
];

/// Dummy messages grouped by chat id (used only as preview / fallback).
final Map<String, List<ChatMessage>> dummyMessagesByChatId = {
  'chat_jane': [
    ChatMessage(
      id: 'm1',
      chatId: 'chat_jane',
      senderId: 'user_jane',
      text:
          'Hey! Are you free to meet tomorrow to discuss the Flutter project?',
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      imageUrl: null,
      readBy: const ['user_me', 'user_jane'],
    ),
    ChatMessage(
      id: 'm2',
      chatId: 'chat_jane',
      senderId: 'user_me',
      text: 'Hi Jane! Yes, I am. How about 2 PM at the library?',
      createdAt: DateTime.now().subtract(const Duration(minutes: 4)),
      imageUrl: null,
      readBy: const ['user_me', 'user_jane'],
    ),
    ChatMessage(
      id: 'm3',
      chatId: 'chat_jane',
      senderId: 'user_jane',
      text: 'Sounds perfect! See you then.',
      createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
      imageUrl: null,
      readBy: const ['user_me', 'user_jane'],
    ),
  ],
  'chat_john': [
    ChatMessage(
      id: 'm4',
      chatId: 'chat_john',
      senderId: 'user_me',
      text: 'Hey, I am interested in the guitar lesson.',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      imageUrl: null,
      readBy: const ['user_me', 'user_john'],
    ),
  ],
  'chat_emily': [
    ChatMessage(
      id: 'm5',
      chatId: 'chat_emily',
      senderId: 'user_emily',
      text: 'Perfect, see you then!',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      imageUrl: null,
      readBy: const ['user_me', 'user_emily'],
    ),
  ],
};
