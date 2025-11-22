import 'package:flutter/material.dart';
import 'package:gr07_skillswap/utils/navigation_utils.dart';
import '../profile/profile_view.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;

  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;

  final List<String> _pageTitles = [
    "SkillSwap Feed",
    "Create Post",
    "Messages",
    "Profile",
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  // Public method to allow child screens to change tabs
  void setCurrentIndex(int index) {
    if (mounted) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  Widget _getCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return _buildPlaceholderPage(_pageTitles[0], Icons.home);
      case 1:
        return _buildPlaceholderPage(_pageTitles[1], Icons.add_circle_outline);
      case 2:
        return _buildPlaceholderPage(_pageTitles[2], Icons.chat_bubble_outline);
      case 3:
        return const ProfileView();
      default:
        return _buildPlaceholderPage(_pageTitles[0], Icons.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1126),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1126),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          _pageTitles[_currentIndex],
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          if (_currentIndex == 0 || _currentIndex == 3) // Only show logout on Feed and Profile screens
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              tooltip: "Log out",
              onPressed: () => _confirmLogout(context),
            ),
        ],
      ),
      body: _getCurrentPage(),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1A1D36),
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.white54,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Feed",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: "Create",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: "Messages",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Profile",
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D36),
        title: const Text("Log Out", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Are you sure you want to log out?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close dialog first
              if (context.mounted) {
                await NavigationUtils.logout(context);
              }
            },
            child: const Text("Log Out", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderPage(String title, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.white38),
          const SizedBox(height: 16),
          Text(
            "$title Page",
            style: const TextStyle(color: Colors.white70, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            "Coming Soon",
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
        ],
      ),
    );
  }
}