// lib/screens/notifications/notification_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../controllers/notification_controller.dart';
import '../../models/notification_model.dart';
import '../chat/chat_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationController _controller = NotificationController();

  StreamSubscription<List<NotificationModel>>? _markAllSub;

  @override
  void initState() {
    super.initState();

    // As soon as we open this screen, mark all current notifications as read.
    // This uses the existing controller.markAsRead for each unread item.
    _markAllSub = _controller.myNotifications.listen((notifs) {
      for (final n in notifs) {
        if (!n.isRead) {
          _controller.markAsRead(n.id);
        }
      }
    });
  }

  @override
  void dispose() {
    _markAllSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _controller.myNotifications,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No notifications yet."));
          }

          final notifications = snapshot.data!;

          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationTile(context, notification);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationTile(BuildContext context, NotificationModel notif) {
    return Container(
      color: notif.isRead ? Colors.transparent : Colors.blue.withOpacity(0.05),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getTypeColor(notif.type),
          child: Icon(_getTypeIcon(notif.type), color: Colors.white),
        ),
        title: Text(
          notif.title,
          style: TextStyle(
            fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notif.body),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM d, h:mm a').format(notif.timestamp),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        onTap: () {
          // Still mark this one as read explicitly (safe even if already read)
          _controller.markAsRead(notif.id);

          // If it's a message notification and we have a chatId stored, open that chat.
          if (notif.type == NotificationType.message &&
              notif.relatedId != null &&
              notif.relatedId!.isNotEmpty) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  chatId: notif.relatedId!, // stored chatId
                  otherUserId: notif.fromUserId, // person who messaged you
                  otherUserName: 'User', // person who messaged you
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.message:
        return Colors.blue;
      case NotificationType.swapRequest:
        return Colors.orange;
      case NotificationType.swapAccepted:
        return Colors.green;
      case NotificationType.reviewReminder:
        return Colors.purple;
    }
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.message:
        return Icons.chat;
      case NotificationType.swapRequest:
        return Icons.swap_horiz;
      case NotificationType.swapAccepted:
        return Icons.check_circle;
      case NotificationType.reviewReminder:
        return Icons.star;
    }
  }
}
