import 'package:flutter/material.dart';
import 'package:gr07_skillswap/utils/navigation_utils.dart';
import '../../utils/theme_manager.dart';

import '../feed/feed_screen.dart';
import '../feed/create_post_screen.dart';
import '../profile/profile_view.dart';
import '../notifications/notification_screen.dart';
import '../../controllers/notification_controller.dart';
import '../chat/chat_list_screen.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;

  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;
  final GlobalKey<CreatePostScreenState> _createPostKey = GlobalKey();
  final NotificationController _notificationController =
      NotificationController();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  // Tabs for bottom navigation
  List<Widget> get _pages => [
    FeedScreen(onTabChange: (index) {}),
    CreatePostScreen(
      key: _createPostKey,
      onTabChange: (index) => setCurrentIndex(index),
    ),
    const ChatListScreen(),
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor:
            theme.appBarTheme.backgroundColor ?? theme.colorScheme.background,
        elevation: theme.appBarTheme.elevation ?? 0,
        title: Text(
          _pageTitles[_currentIndex],
          style: theme.textTheme.titleLarge,
        ),
        actions: [
          // Notification bell with badge (from main)
          StreamBuilder<int>(
            stream: _notificationController.unreadCount,
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.notifications_outlined,
                      color:
                          theme.iconTheme.color ??
                          theme.colorScheme.onBackground,
                    ),
                    tooltip: "Notifications",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NotificationScreen(),
                        ),
                      );
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : unreadCount.toString(),
                          style: TextStyle(
                            color: theme.colorScheme.onError,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          // Theme toggle
          ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemeManager.themeNotifier,
            builder: (context, mode, _) {
              final isDark = mode == ThemeMode.dark;
              return IconButton(
                icon: Icon(
                  isDark ? Icons.dark_mode : Icons.light_mode,
                  color: Theme.of(context).iconTheme.color,
                ),
                tooltip: isDark ? 'Switch to light' : 'Switch to dark',
                onPressed: () {
                  ThemeManager.setThemeMode(
                    isDark ? ThemeMode.light : ThemeMode.dark,
                  );
                },
              );
            },
          ),

          if (_currentIndex == 0 || _currentIndex == 3)
            IconButton(
              icon: Icon(Icons.logout, color: theme.colorScheme.error),
              tooltip: "Log out",
              onPressed: () => _confirmLogout(context),
            ),
          if (_currentIndex == 1)
            IconButton(
              icon: Icon(Icons.check, color: theme.colorScheme.secondary),
              tooltip: "Submit Post",
              onPressed: _submitPostFromAppBar,
            ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: theme.colorScheme.surface,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: theme.colorScheme.onSurface.withOpacity(0.6),
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Feed"),
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
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text("Log Out", style: theme.textTheme.titleLarge),
        content: Text(
          "Are you sure you want to log out?",
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: theme.textTheme.bodyMedium),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await NavigationUtils.logout(context);
            },
            child: Text(
              "Log Out",
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildPlaceholderPage(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: theme.iconTheme.color?.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(
            "$title Page",
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.textTheme.bodyLarge?.color?.withOpacity(0.8),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Coming Soon",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
