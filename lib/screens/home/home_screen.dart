import 'package:flutter/material.dart';
import 'package:gr07_skillswap/utils/navigation_utils.dart';
import '../feed/feed_screen.dart';
import '../feed/create_post_screen.dart';
import '../profile/profile_view.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;

  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;
  final GlobalKey<CreatePostScreenState> _createPostKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  List<Widget> get _pages => [
    FeedScreen(onTabChange: (index) {}),
    CreatePostScreen(
      key: _createPostKey,
      onTabChange: (index) => setCurrentIndex(index),
    ),
    _buildPlaceholderPage("Messages", Icons.chat_bubble_outline),
    const ProfileView(),
  ];

  final List<String> _pageTitles = [
    "SkillSwap Feed",
    "Create Post",
    "Messages",
    "Profile",
  ];

  // Public method to allow child screens to change tabs
  void setCurrentIndex(int index) {
    if (mounted) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1126),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1126),
        elevation: 0,
        title: Text(
          _pageTitles[_currentIndex],
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          if (_currentIndex == 0 || _currentIndex == 3)
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              tooltip: "Log out",
              onPressed: () => _confirmLogout(context),
            ),
          if (_currentIndex == 1)
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              tooltip: "Submit Post",
              onPressed: _submitPostFromAppBar,
            ),
        ],
      ),
      body: _pages[_currentIndex],
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

  void _submitPostFromAppBar() {
    if (_createPostKey.currentState != null) {
      _createPostKey.currentState!.submitPost();
    }
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D36),
        title: const Text("Log Out", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Are you sure you want to log out?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await NavigationUtils.logout(context);
            },
            child: const Text("Log Out", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  static Widget _buildPlaceholderPage(String title, IconData icon) {
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