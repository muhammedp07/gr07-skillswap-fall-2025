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
    // In the StreamBuilder, use the appropriate stream
    Stream<List<SwapSession>> sessionStream = _useFallbackQuery
        ? _sessionService.getSessionsForUserSimple(_currentUserId)
        : _sessionService.getSessionsForUser(_currentUserId);

    return Scaffold(
      backgroundColor: const Color(0xFF0E1126),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1126),
        title: Text(
          'Scheduled Swaps with ${widget.otherUserName}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // Header with new schedule button
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1A1D36),
            child: Row(
              children: [
                const Icon(Icons.schedule, color: Colors.blue, size: 24),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Manage your scheduled swap sessions',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _navigateToScheduleSwap();
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New Schedule'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
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
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.orange.withOpacity(0.1),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: _showIndexHelp,
            child: const Text(
              'Fix',
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1D36),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Unable to load sessions',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                _error ?? 'Unknown error',
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _loadSessions,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Try Again'),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: _showIndexHelp,
                    child: const Text('Get Help'),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Error loading sessions',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSessions,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading sessions...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.schedule_outlined,
              size: 64,
              color: Colors.white38,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Scheduled Swaps',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Schedule your first swap session with ${widget.otherUserName}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToScheduleSwap,
              icon: const Icon(Icons.add),
              label: const Text('Schedule First Swap'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(SwapSession session) {
    final isUpcoming = session.isUpcoming;
    final isInitiator = session.initiatorId == _currentUserId;

    return Card(
      color: const Color(0xFF1A1D36),
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
                const Icon(Icons.calendar_today, size: 16, color: Colors.white70),
                const SizedBox(width: 8),
                Text(
                  DateFormat('EEE, MMM d, yyyy').format(session.scheduledTime),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 16, color: Colors.white70),
                const SizedBox(width: 8),
                Text(
                  DateFormat('h:mm a').format(session.scheduledTime),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Duration and Location
            Row(
              children: [
                const Icon(Icons.timer, size: 16, color: Colors.white70),
                const SizedBox(width: 8),
                Text(
                  '${session.duration.inMinutes} minutes',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.location_on, size: 16, color: Colors.white70),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    session.location,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // Notes (if any)
            if (session.notes != null && session.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Notes:',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                session.notes!,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],

            // Initiator info
            const SizedBox(height: 8),
            Text(
              isInitiator ? 'You scheduled this session' : '${widget.otherUserName} scheduled this session',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(SwapSession session) {
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
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSessionActions(SwapSession session) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white70),
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
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D36),
        title: const Text('Cancel Session', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to cancel this swap session?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _sessionService.updateSessionStatus(session.id, 'cancelled');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Session cancelled'),
                    backgroundColor: Colors.orange,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to cancel: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _deleteSession(SwapSession session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D36),
        title: const Text('Delete Session', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete this session? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _sessionService.deleteSession(session.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Session deleted'),
                    backgroundColor: Colors.red,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showIndexHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D36),
        title: const Text('Firestore Index Required', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This feature requires a Firestore index to be created.\n\n'
          'Please ask your project administrator to create the index or click the link in the error message to create it automatically.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }
}