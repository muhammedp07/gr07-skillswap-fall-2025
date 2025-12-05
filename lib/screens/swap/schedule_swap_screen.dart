// screens/swap/schedule_swap_screen.dart
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/swap_session.dart';
import '../../services/swap_session_service.dart';

class ScheduleSwapScreen extends StatefulWidget {
  final String postId;
  final String chatId;
  final String otherUserId;
  final String otherUserName;

  const ScheduleSwapScreen({
    super.key,
    required this.postId,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ScheduleSwapScreen> createState() => _ScheduleSwapScreenState();
}

class _ScheduleSwapScreenState extends State<ScheduleSwapScreen> {
  final SwapSessionService _sessionService = SwapSessionService();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 14, minute: 0);
  int _selectedDuration = 60; // minutes

  Future<void> _scheduleSwap() async {
    final scheduledDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    if (scheduledDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a future date and time')),
      );
      return;
    }

    if (_locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a location')),
      );
      return;
    }

    final session = SwapSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      postId: widget.postId,
      chatId: widget.chatId,
      participantIds: [widget.otherUserId, FirebaseAuth.instance.currentUser!.uid],
      initiatorId: FirebaseAuth.instance.currentUser!.uid,
      scheduledTime: scheduledDateTime,
      duration: Duration(minutes: _selectedDuration),
      location: _locationController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      createdAt: DateTime.now(),
    );

    try {
      await _sessionService.createSwapSession(session);
      
      // Send notification to the other user
      // You can integrate with your notification service here
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Swap session scheduled!')),
      );
      
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to schedule: $e')),
      );
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        title: Text('Schedule Swap', style: theme.appBarTheme.titleTextStyle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.group, color: theme.colorScheme.primary, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Schedule with ${widget.otherUserName}',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Date Selection
              _buildSection(
                title: 'Date',
                child: ListTile(
                  leading: Icon(Icons.calendar_today, color: theme.colorScheme.primary),
                  title: Text(
                    DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                    style: theme.textTheme.bodyMedium,
                  ),
                  trailing: Icon(Icons.arrow_drop_down, color: theme.iconTheme.color),
                  onTap: _selectDate,
                ),
              ),

              // Time Selection
              _buildSection(
                title: 'Time',
                child: ListTile(
                  leading: Icon(Icons.access_time, color: theme.colorScheme.primary),
                  title: Text(
                    _selectedTime.format(context),
                    style: theme.textTheme.bodyMedium,
                  ),
                  trailing: Icon(Icons.arrow_drop_down, color: theme.iconTheme.color),
                  onTap: _selectTime,
                ),
              ),

              // Duration Selection
              _buildSection(
                title: 'Duration',
                child: DropdownButtonFormField<int>(
                  value: _selectedDuration,
                  dropdownColor: theme.colorScheme.surfaceVariant,
                  style: theme.textTheme.bodyMedium,
                  items: [30, 60, 90, 120].map((duration) {
                    return DropdownMenuItem(
                      value: duration,
                      child: Text('$duration minutes'),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedDuration = value!),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                  ),
                ),
              ),

              // Location
              _buildSection(
                title: 'Location',
                child: TextField(
                  controller: _locationController,
                  style: theme.textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'E.g., Library study room, QEII Library, etc.',
                    hintStyle: theme.textTheme.bodySmall,
                    border: InputBorder.none,
                  ),
                ),
              ),

              // Notes
              _buildSection(
                title: 'Notes (Optional)',
                child: TextField(
                  controller: _notesController,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Any specific topics or materials to bring...',
                    hintStyle: theme.textTheme.bodySmall,
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Schedule Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _scheduleSwap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Schedule Swap Session',
                    style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onPrimary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Builder(builder: (context) {
          final theme = Theme.of(context);
          return Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          );
        }),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: child,
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}