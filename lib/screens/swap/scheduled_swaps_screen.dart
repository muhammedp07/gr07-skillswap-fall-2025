// screens/swap/scheduled_swaps_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/swap_session.dart';
import '../../services/swap_session_service.dart';
import 'schedule_swap_screen.dart';

class ScheduledSwapsScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;

  const ScheduledSwapsScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ScheduledSwapsScreen> createState() => _ScheduledSwapsScreenState();
}

class _ScheduledSwapsScreenState extends State<ScheduledSwapsScreen> {
  final SwapSessionService _sessionService = SwapSessionService();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  bool _isLoading = true;
  String? _error;
  bool _useFallbackQuery = false;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      // Try the main query first
      final initialSnapshot = await _sessionService
          .getSessionsForUser(_currentUserId)
          .first;
      
      setState(() {
        _isLoading = false;
        _useFallbackQuery = false;
      });
    } catch (e) {
      // If main query fails, try fallback
      if (e.toString().contains('index') || e.toString().contains('FAILED_PRECONDITION')) {
        _useFallbackQuery = true;
        setState(() {
          _isLoading = false;
          _error = 'Using simplified query (index required for optimal performance)';
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // In the StreamBuilder, use the appropriate stream
    Stream<List<SwapSession>> sessionStream = _useFallbackQuery
        ? _sessionService.getSessionsForUserSimple(_currentUserId)
        : _sessionService.getSessionsForUser(_currentUserId);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        title: Text(
          'Scheduled Swaps with ${widget.otherUserName}',
          style: theme.appBarTheme.titleTextStyle,
        ),
      ),
      body: Column(
        children: [
          // Header with new schedule button
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surfaceVariant,
            child: Row(
              children: [
                Icon(Icons.schedule, color: theme.colorScheme.primary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Manage your scheduled swap sessions',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _navigateToScheduleSwap();
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New Schedule'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
          ),

          // Error state (non-fatal warning about index)
          if (_error != null && _error!.contains('simplified'))
            _buildWarningState(),

          // Fatal error state
          if (_error != null && !_error!.contains('simplified'))
            _buildErrorState(),

          // Loading state
          if (_isLoading) _buildLoadingState(),

          // Scheduled swaps list (only show if no fatal error and not loading)
          if (!_isLoading && (_error == null || _error!.contains('simplified')))
            Expanded(
              child: StreamBuilder<List<SwapSession>>(
                stream: sessionStream, // This uses the conditional stream
                builder: (context, snapshot) {
                  if (snapshot.hasError && !_useFallbackQuery) {
                    return _buildStreamErrorState(snapshot.error!);
                  }

                  final allSessions = snapshot.data ?? [];
                  // Filter sessions for this specific chat
                  final chatSessions = allSessions
                      .where((session) => session.chatId == widget.chatId)
                      .toList();

                  if (chatSessions.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: chatSessions.length,
                    itemBuilder: (context, index) {
                      return _buildSessionCard(chatSessions[index]);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWarningState() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      color: theme.colorScheme.secondary.withOpacity(0.08),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: theme.colorScheme.secondary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
            ),
          ),
          TextButton(
            onPressed: _showIndexHelp,
            child: const Text(
              'Fix',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final theme = Theme.of(context);
    return Expanded(
          child: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: theme.colorScheme.error, size: 48),
              const SizedBox(height: 16),
              Text(
                'Unable to load sessions',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _error ?? 'Unknown error',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _loadSessions,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                    child: const Text('Try Again'),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: _showIndexHelp,
                    child: Text('Get Help', style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreamErrorState(dynamic error) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error loading sessions',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSessions,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    final theme = Theme.of(context);
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading sessions...',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.schedule_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.38),
            ),
            const SizedBox(height: 16),
            Text(
              'No Scheduled Swaps',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Schedule your first swap session with ${widget.otherUserName}',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToScheduleSwap,
              icon: const Icon(Icons.add),
              label: const Text('Schedule First Swap'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(SwapSession session) {
    final theme = Theme.of(context);
    final isUpcoming = session.isUpcoming;
    final isInitiator = session.initiatorId == _currentUserId;

    return Card(
      color: theme.colorScheme.surfaceVariant,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status and actions
            Row(
              children: [
                _buildStatusIndicator(session),
                const Spacer(),
                if (isUpcoming) _buildSessionActions(session),
              ],
            ),

            const SizedBox(height: 12),

            // Date and Time
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.7)),
                const SizedBox(width: 8),
                Text(
                  DateFormat('EEE, MMM d, yyyy').format(session.scheduledTime),
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.7)),
                const SizedBox(width: 8),
                Text(
                  DateFormat('h:mm a').format(session.scheduledTime),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Duration and Location
            Row(
              children: [
                Icon(Icons.timer, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.7)),
                const SizedBox(width: 8),
                Text(
                  '${session.duration.inMinutes} minutes',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(width: 16),
                Icon(Icons.location_on, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.7)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    session.location,
                    style: theme.textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // Notes (if any)
            if (session.notes != null && session.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Notes:',
                style: theme.textTheme.bodySmall,
              ),
              Text(
                session.notes!,
                style: theme.textTheme.bodySmall,
              ),
            ],

            // Initiator info
            const SizedBox(height: 8),
            Text(
              isInitiator ? 'You scheduled this session' : '${widget.otherUserName} scheduled this session',
              style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(SwapSession session) {
    final theme = Theme.of(context);
    Color color;
    String statusText;
    IconData icon;

    if (session.isCompleted) {
      color = Colors.green;
      statusText = 'Completed';
      icon = Icons.check_circle;
    } else if (session.isCancelled) {
      color = Colors.red;
      statusText = 'Cancelled';
      icon = Icons.cancel;
    } else if (session.isUpcoming) {
      color = Colors.blue;
      statusText = 'Upcoming';
      icon = Icons.upcoming;
    } else {
      color = Colors.orange;
      statusText = 'Past';
      icon = Icons.history;
    }

    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(
          statusText,
          style: theme.textTheme.bodyMedium?.copyWith(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildSessionActions(SwapSession session) {
    final theme = Theme.of(context);
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: theme.iconTheme.color?.withOpacity(0.7)),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'cancel',
          child: Row(
            children: [
              Icon(Icons.cancel, color: Colors.red),
              SizedBox(width: 8),
              Text('Cancel Session'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete'),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'cancel') {
          _cancelSession(session);
        } else if (value == 'delete') {
          _deleteSession(session);
        }
      },
    );
  }

  void _navigateToScheduleSwap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScheduleSwapScreen(
          postId: 'from_chat_${widget.chatId}',
          chatId: widget.chatId,
          otherUserId: widget.otherUserId,
          otherUserName: widget.otherUserName,
        ),
      ),
    ).then((refresh) {
      if (refresh == true) {
        // Optional: Refresh the list if needed
        setState(() {});
      }
    });
  }

  void _cancelSession(SwapSession session) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: theme.colorScheme.surfaceVariant,
          title: Text('Cancel Session', style: theme.textTheme.titleMedium),
          content: Text(
            'Are you sure you want to cancel this swap session?',
            style: theme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('No', style: theme.textTheme.bodyMedium),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await _sessionService.updateSessionStatus(session.id, 'cancelled');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Session cancelled'),
                      backgroundColor: theme.colorScheme.secondary,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to cancel: $e'),
                      backgroundColor: theme.colorScheme.error,
                    ),
                  );
                }
              },
              child: Text('Yes, Cancel', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
            ),
          ],
        );
      },
    );
  }

  void _deleteSession(SwapSession session) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: theme.colorScheme.surfaceVariant,
          title: Text('Delete Session', style: theme.textTheme.titleMedium),
          content: Text(
            'Are you sure you want to delete this session? This action cannot be undone.',
            style: theme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: theme.textTheme.bodyMedium),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await _sessionService.deleteSession(session.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Session deleted'),
                      backgroundColor: theme.colorScheme.error,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete: $e'),
                      backgroundColor: theme.colorScheme.error,
                    ),
                  );
                }
              },
              child: Text('Delete', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
            ),
          ],
        );
      },
    );
  }

  void _showIndexHelp() {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: theme.colorScheme.surfaceVariant,
          title: Text('Firestore Index Required', style: theme.textTheme.titleMedium),
          content: Text(
            'This feature requires a Firestore index to be created.\n\n'
            'Please ask your project administrator to create the index or click the link in the error message to create it automatically.',
            style: theme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK', style: theme.textTheme.bodyMedium),
            ),
          ],
        );
      },
    );
  }
}