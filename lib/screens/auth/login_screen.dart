import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum AuthMode { signIn, signUp }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

final confirmPasswordController = TextEditingController();

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool acceptedConduct = false;
  bool loading = false;
  String? errorMessage;

  AuthMode _mode = AuthMode.signIn;

  @override
  Widget build(BuildContext context) {
    final isSignUp = _mode == AuthMode.signUp;

    return Scaffold(
      backgroundColor: const Color(0xFF0E1126),
      appBar: AppBar(backgroundColor: const Color(0xFF0E1126), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isSignUp ? "Create your account" : "Welcome back",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSignUp
                  ? "Use your @mun.ca email to join SkillSwap."
                  : "Sign in with your MUN email.",
              style: const TextStyle(color: Colors.white70),
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
                style: const TextStyle(color: Colors.redAccent),
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
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF1A1D36),
        prefixIcon: icon != null ? Icon(icon, color: Colors.white70) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _buildCodeOfConduct() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Code of Conduct",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            "• Be respectful\n• No harassment\n• Meet in public places\n• Not a dating app",
            style: TextStyle(color: Colors.white70),
          ),
          Row(
            children: [
              Checkbox(
                value: acceptedConduct,
                onChanged: (v) => setState(() => acceptedConduct = v!),
              ),
              const Text("I agree", style: TextStyle(color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(bool isSignUp) {
    return ElevatedButton(
      onPressed: loading
          ? null
          : () => isSignUp ? _handleSignUp() : _handleSignIn(),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        backgroundColor: Colors.blue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          : Text(isSignUp ? "Create account" : "Sign in"),
    );
  }

  Widget _buildSwitchModeButton(bool isSignUp) {
    return Center(
      child: TextButton(
        onPressed: () {
          setState(() {
            _mode = isSignUp ? AuthMode.signIn : AuthMode.signUp;
            errorMessage = null; // clear errors
          });
        },
        child: Text(
          isSignUp
              ? "Already have an account? Sign in"
              : "Don't have an account? Create one",
          style: const TextStyle(color: Colors.white70),
        ),
      ),
    );
  }

  Future<void> _handleSignIn() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (!email.endsWith('@mun.ca')) {
      setState(() => errorMessage = "Please use your @mun.ca email.");
      return;
    }

    setState(() => loading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      setState(() => errorMessage = e.message);
    }

    setState(() => loading = false);
  }

  Future<void> _handleSignUp() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (!email.endsWith('@mun.ca')) {
      setState(() => errorMessage = "Please use your @mun.ca email.");
      return;
    }

    if (!acceptedConduct) {
      setState(() => errorMessage = "You must agree to the Code of Conduct.");
      return;
    }

    if (passwordController.text.trim() !=
        confirmPasswordController.text.trim()) {
      setState(() => errorMessage = "Passwords do not match.");
      return;
    }

    setState(() => loading = true);

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      setState(() => errorMessage = e.message);
    }

    setState(() => loading = false);
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
