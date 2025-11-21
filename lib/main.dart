import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gr07_skillswap/screens/auth/welcome_screen.dart';
import 'package:gr07_skillswap/screens/home/home_placeholder.dart';
import 'package:gr07_skillswap/services/user_service.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/onboarding/profile_setup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SkillSwapApp());
}

class SkillSwapApp extends StatelessWidget {
  const SkillSwapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkillSwap',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Not logged in → Welcome Screen
        if (user == null) {
          return const WelcomeScreen();
        }

        // User logged in → Check if profile exists
        return FutureBuilder<bool>(
          future: UserService().doesProfileExist(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final exists = snap.data!;
            return exists
                ? const HomePlaceholder() // User already has profile
                : const ProfileSetupScreen(); // New user
          },
        );
      },
    );
  }
}
