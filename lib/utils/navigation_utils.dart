// utils/navigation_utils.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/auth/welcome_screen.dart';

class NavigationUtils {
  static Future<void> logout(BuildContext context) async {
    try {
      // Clear any pending navigations
      if (Navigator.canPop(context)) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
      
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