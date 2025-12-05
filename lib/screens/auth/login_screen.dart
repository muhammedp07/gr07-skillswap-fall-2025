import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/user_service.dart';
import '../home/home_screen.dart';
import '../onboarding/profile_setup_screen.dart';
import '../auth/reset_password_screen.dart';

enum AuthMode { signIn, signUp }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool acceptedConduct = false;
  bool loading = false;
  String? errorMessage;

  AuthMode _mode = AuthMode.signIn;

  @override
  Widget build(BuildContext context) {
    final isSignUp = _mode == AuthMode.signUp;

    // Improved readability and ensured input streams are light-themed
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isSignUp ? "Create your account" : "Welcome back",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              isSignUp
                  ? "Use your @mun.ca email to join SkillSwap."
                  : "Sign in with your MUN email.",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium?.color
                        ?.withOpacity(0.8),
                  ),
            ),

            const SizedBox(height: 24),

            _buildTextField(
              controller: emailController,
              label: "MUN Email",
              icon: Icons.email_outlined,
            ),

            const SizedBox(height: 16),

            _buildTextField(
              controller: passwordController,
              label: "Password",
              obscure: true,
              icon: Icons.lock_outline,
            ),

            if (!isSignUp)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ResetPasswordScreen(),
                      ),
                    );
                  },
                  child: Text(
                    "Forgot password?",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

            if (isSignUp) ...[
              const SizedBox(height: 16),
              _buildTextField(
                controller: confirmPasswordController,
                label: "Confirm Password",
                obscure: true,
                icon: Icons.lock_outline,
              ),
            ],

            const SizedBox(height: 20),

            if (isSignUp) _buildCodeOfConduct(),

            if (errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                errorMessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],

            const SizedBox(height: 20),

            _buildSubmitButton(isSignUp),

            const SizedBox(height: 12),

            _buildSwitchModeButton(isSignUp),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool obscure = false,
    IconData? icon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: Theme.of(context).textTheme.bodySmall,
        filled: true,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
        prefixIcon: icon != null
            ? Icon(icon, color: Theme.of(context).iconTheme.color)
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  // Improved readability for sign-in button, sign-up button, and Code of Conduct area
  Widget _buildSubmitButton(bool isSignUp) {
    return ElevatedButton(
      onPressed: loading
          ? null
          : () => isSignUp ? _handleSignUp() : _handleSignIn(),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        backgroundColor: Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
      child: loading
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Text(
              isSignUp ? "Create Account" : "Sign In",
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
    );
  }

  Widget _buildSwitchModeButton(bool isSignUp) {
    return Center(
      child: TextButton(
        onPressed: () {
          if (!mounted) return;
          setState(() {
            _mode = isSignUp ? AuthMode.signIn : AuthMode.signUp;
            errorMessage = null;
          });
        },
        child: Text(
          isSignUp
              ? "Already have an account? Sign in"
              : "Don't have an account? Create one",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.secondary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }

  Widget _buildCodeOfConduct() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Code of Conduct",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            "\u2022 Be respectful\n\u2022 No harassment\n\u2022 Meet in public places\n\u2022 Not a dating app",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color
                      ?.withOpacity(0.8),
                ),
          ),
          Row(
            children: [
              Checkbox(
                value: acceptedConduct,
                onChanged: (v) {
                  if (!mounted) return;
                  setState(() => acceptedConduct = v!);
                },
              ),
              Text(
                "I agree",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // SIGN IN
  Future<void> _handleSignIn() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (!email.endsWith('@mun.ca')) {
      if (!mounted) return;
      setState(() => errorMessage = "Please use your @mun.ca email.");
      return;
    }

    if (!mounted) return;
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      // Check if user has completed profile setup
      final hasProfile = await UserService().doesProfileExist();

      if (!mounted) return;

      // Navigate to appropriate screen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) =>
              hasProfile ? const HomeScreen() : const ProfileSetupScreen(),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = e.message;
        loading = false;
      });
    }
  }

  // SIGN UP
  Future<void> _handleSignUp() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (!email.endsWith('@mun.ca')) {
      if (!mounted) return;
      setState(() => errorMessage = "Please use your @mun.ca email.");
      return;
    }

    if (!acceptedConduct) {
      if (!mounted) return;
      setState(() => errorMessage = "You must agree to the Code of Conduct.");
      return;
    }

    if (password != confirmPassword) {
      if (!mounted) return;
      setState(() => errorMessage = "Passwords do not match.");
      return;
    }

    if (password.length < 6) {
      if (!mounted) return;
      setState(() => errorMessage = "Password must be at least 6 characters.");
      return;
    }

    if (!mounted) return;
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      // After successful sign up, navigate to profile setup
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = e.message;
        loading = false;
      });
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
