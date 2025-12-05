// lib/screens/notifications/notification_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../controllers/notification_controller.dart';
import '../../models/notification_model.dart';
import '../chat/chat_screen.dart';
import '../reviews/leave_review_screen.dart';
import '../swap/scheduled_swaps_screen.dart';

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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text("Notifications", style: theme.appBarTheme.titleTextStyle)),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _controller.myNotifications,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No notifications yet.", style: theme.textTheme.bodyMedium));
          }

          final notifications = snapshot.data!;

          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (context, index) => Divider(height: 1, color: theme.dividerColor),
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
    final theme = Theme.of(context);
    return Container(
      color: notif.isRead ? Colors.transparent : theme.colorScheme.primary.withOpacity(0.05),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getTypeColor(context, notif.type),
          child: Icon(_getTypeIcon(notif.type), color: theme.colorScheme.onPrimary),
        ),
        title: Text(
          notif.title,
          style: TextStyle(
            fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notif.body, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM d, h:mm a').format(notif.timestamp),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        onTap: () {
          // Still mark this one as read explicitly (safe even if already read)
          _controller.markAsRead(notif.id);

          // Navigate based on notification type
          if (notif.relatedId == null || notif.relatedId!.isEmpty) return;

          switch (notif.type) {
            case NotificationType.message:
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    chatId: notif.relatedId!,
                    otherUserId: notif.fromUserId,
                    otherUserName: notif.fromUserName,
                  ),
                ),
              );
              break;

            case NotificationType.swapCompleted:
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => LeaveReviewScreen(
                    chatId: notif.relatedId!,
                    otherUserId: notif.fromUserId,
                    otherUserName: notif.fromUserName,
                  ),
                ),
              );
              break;

            case NotificationType.swapReminder:
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ScheduledSwapsScreen(
                    chatId: notif.relatedId!,
                    otherUserId: notif.fromUserId,
                    otherUserName: notif.fromUserName,
                  ),
                ),
              );
              break;

            case NotificationType.swapRequest:
            case NotificationType.swapAccepted:
            case NotificationType.reviewReminder:
              // No specific navigation for these yet
              break;
          }
        },
      ),
    );
  }

  Color _getTypeColor(BuildContext context, NotificationType type) {
    final theme = Theme.of(context);
    switch (type) {
      case NotificationType.message:
        return theme.colorScheme.primary;
      case NotificationType.swapRequest:
        return theme.colorScheme.secondary;
      case NotificationType.swapAccepted:
        return theme.colorScheme.primaryContainer;
      case NotificationType.swapCompleted:
        return theme.colorScheme.secondaryContainer;
      case NotificationType.swapReminder:
        return theme.colorScheme.primary.withOpacity(0.75);
      case NotificationType.reviewReminder:
        return theme.colorScheme.secondary.withOpacity(0.75);
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
      case NotificationType.swapCompleted:
        return Icons.done_all;
      case NotificationType.swapReminder:
        return Icons.schedule;
      case NotificationType.reviewReminder:
        return Icons.star;
    }
  }
}
