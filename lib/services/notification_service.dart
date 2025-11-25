import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // STREAM: Real-time list of notifications for a specific user
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return NotificationModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // STREAM: Unread count (for the red badge on HomeScreen)
  Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      final userNotifRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications');

      final snapshot = await userNotifRef
          .where('isRead', isEqualTo: false)
          .get();

      if (snapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      // optional: log for debugging
      // debugPrint('Failed to mark all notifications as read: $e');
    }
  }

  // WRITE: Mark as read
  Future<void> markAsRead(String userId, String notificationId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  // WRITE: Send a notification (Used by other features)
  Future<void> sendNotification(
    String toUserId,
    NotificationModel notification,
  ) async {
    await _firestore
        .collection('users')
        .doc(toUserId)
        .collection('notifications')
        .add(notification.toMap());
  }
}
