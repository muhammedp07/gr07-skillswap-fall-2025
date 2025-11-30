import 'package:flutter/material.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/notifications/notification_screen.dart';

class NotificationNavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = 
      GlobalKey<NavigatorState>();

  static void handleNotificationNavigation(Map<String, dynamic> data) {
    final type = data['type'];
    final relatedId = data['relatedId'];
    final fromUserId = data['fromUserId'];
    final fromUserName = data['fromUserName'] ?? 'User';

    // Use the navigator key to push screens without context
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    switch (type) {
      case 'message':
        if (relatedId != null && relatedId.isNotEmpty && fromUserId != null) {
          navigator.push(
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                chatId: relatedId,
                otherUserId: fromUserId,
                otherUserName: fromUserName,
              ),
            ),
          );
        } else {
           // Fallback if data is missing
           navigator.push(
            MaterialPageRoute(builder: (_) => const NotificationScreen()),
          );
        }
        break;
        
      case 'swapRequest':
      case 'swapAccepted':
        // Navigate to notifications screen for now (or SwapDetailScreen if you have one)
        navigator.push(
          MaterialPageRoute(builder: (_) => const NotificationScreen()),
        );
        break;
        
      case 'reviewReminder':
        // Navigate to notifications screen for now
        navigator.push(
          MaterialPageRoute(builder: (_) => const NotificationScreen()),
        );
        break;
        
      default:
        navigator.push(
          MaterialPageRoute(builder: (_) => const NotificationScreen()),
        );
    }
  }
}
