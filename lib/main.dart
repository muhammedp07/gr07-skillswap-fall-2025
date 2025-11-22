import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gr07_skillswap/screens/auth/welcome_screen.dart';
import 'package:gr07_skillswap/screens/home/home_screen.dart';
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
      navigatorKey: GlobalKey<NavigatorState>(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }

        final user = snapshot.data;

        // User not logged in - show welcome screen
        if (user == null) {
          return const WelcomeScreen();
        }

        // User is logged in - check if profile exists
        return FutureBuilder<bool>(
          future: UserService().doesProfileExist(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingScreen();
            }

            if (profileSnapshot.hasError) {
              return _buildErrorScreen(profileSnapshot.error.toString());
            }

            final profileExists = profileSnapshot.data ?? false;
            
            // Navigate based on profile existence
            return profileExists
                ? const HomeScreen()
                : const ProfileSetupScreen();
          },
        );
      },
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1126),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 20),
            Text(
              'Loading SkillSwap...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(String error) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1126),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 20),
              const Text(
                'Something went wrong',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                error,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  setState(() {});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Try Again'),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
                child: const Text(
                  'Sign Out',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}