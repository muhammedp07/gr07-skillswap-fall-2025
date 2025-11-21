import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool acceptedConduct = false;
  String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1126),
      appBar: AppBar(backgroundColor: const Color(0xFF0E1126), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Create account or sign in",
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Use your @mun.ca email to join SkillSwap.",
              style: TextStyle(color: Colors.white70),
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

            const SizedBox(height: 24),

            _buildCodeOfConduct(),

            const SizedBox(height: 20),

            if (errorMessage != null)
              Text(
                errorMessage!,
                style: const TextStyle(color: Colors.redAccent),
              ),

            const SizedBox(height: 20),

            _buildButtons(),
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
        prefixIcon: icon != null ? Icon(icon, color: Colors.white70) : null,
        filled: true,
        fillColor: const Color(0xFF1A1D36),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _buildCodeOfConduct() {
    return Container(
      width: double.infinity,
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

  Widget _buildButtons() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text("Create account"),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {},
          child: const Text(
            "Already have an account? Sign in",
            style: TextStyle(color: Colors.white70),
          ),
        ),
      ],
    );
  }
}
