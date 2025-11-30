// utils/navigation_utils.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/auth/welcome_screen.dart';
import '../services/push_notification_service.dart';

class NavigationUtils {
  static Future<void> logout(BuildContext context) async {
    try {
      // Clear any pending navigations
      if (Navigator.canPop(context)) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
      
      // Clear FCM token BEFORE signing out (while we still have access to user's UID)
      await PushNotificationService().clearFcmToken();
      
      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();
      
      // Wait a brief moment for Firebase to process the sign out
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Navigate to WelcomeScreen and remove all previous routes
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {

      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          (route) => false,
        );
      }
    }
  }
}