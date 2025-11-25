import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationController {
  final NotificationService _service = NotificationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  Stream<List<NotificationModel>> get myNotifications {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);
    return _service.getUserNotifications(uid);
  }

  Stream<int> get unreadCount {
    final uid = currentUserId;
    if (uid == null) return Stream.value(0);
    return _service.getUnreadCount(uid);
  }

  Future<void> markAsRead(String notificationId) async {
    final uid = currentUserId;
    if (uid != null) {
      await _service.markAsRead(uid, notificationId);
    }
  }

  Future<void> markAllAsRead() async {
    final uid = currentUserId;
    if (uid != null) {
      await _service.markAllAsRead(uid);
    }
  }

  // Helper for Teammates to trigger notifications easily
  Future<void> triggerNotification({
    required String toUserId,
    required String title,
    required String body,
    required NotificationType type,
    String? relatedId,
  }) async {
    // Note: In a real app, 'fromUserId' is the current user.
    final fromId = currentUserId ?? 'system';

    final notification = NotificationModel(
      id: '', // Firestore generates this
      fromUserId: fromId,
      title: title,
      body: body,
      type: type,
      timestamp: DateTime.now(),
      relatedId: relatedId,
    );

    await _service.sendNotification(toUserId, notification);
  }
}
