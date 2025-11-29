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
    return Scaffold(
      backgroundColor: const Color(0xFF0E1126),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1126),
        title: const Text('Schedule Swap', style: TextStyle(color: Colors.white)),
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
                  color: const Color(0xFF1A1D36),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.group, color: Colors.blue, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Schedule with ${widget.otherUserName}',
                        style: const TextStyle(color: Colors.white, fontSize: 16),
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
                  leading: const Icon(Icons.calendar_today, color: Colors.blue),
                  title: Text(
                    DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  onTap: _selectDate,
                ),
              ),

              // Time Selection
              _buildSection(
                title: 'Time',
                child: ListTile(
                  leading: const Icon(Icons.access_time, color: Colors.blue),
                  title: Text(
                    _selectedTime.format(context),
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  onTap: _selectTime,
                ),
              ),

              // Duration Selection
              _buildSection(
                title: 'Duration',
                child: DropdownButtonFormField<int>(
                  value: _selectedDuration,
                  dropdownColor: const Color(0xFF1A1D36),
                  style: const TextStyle(color: Colors.white),
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
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'E.g., Library study room, QEII Library, etc.',
                    hintStyle: TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                  ),
                ),
              ),

              // Notes
              _buildSection(
                title: 'Notes (Optional)',
                child: TextField(
                  controller: _notesController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Any specific topics or materials to bring...',
                    hintStyle: TextStyle(color: Colors.white54),
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
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Schedule Swap Session',
                    style: TextStyle(fontSize: 16, color: Colors.white),
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
        Text(
          title,
          style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1D36),
            borderRadius: BorderRadius.circular(12),
          ),
          child: child,
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}