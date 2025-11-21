import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePlaceholder extends StatelessWidget {
  const HomePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1126),
      appBar: AppBar(
        title: const Text("Home Page (Placeholder)"),
        backgroundColor: const Color(0xFF0E1126),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: const Center(
        child: Text(
          "Home Page will be implemented in the next feature branch.",
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}
