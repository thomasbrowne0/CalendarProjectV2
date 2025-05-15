import 'package:flutter/material.dart';
import 'package:calendar_app/services/create_event_service.dart';
import 'package:calendar_app/widgets/event_widget.dart';

class CreateEventScreen extends StatefulWidget {
  final DateTime selectedDate;

  const CreateEventScreen({
    super.key,
    required this.selectedDate,
  });

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  bool _isLoading = false;
  final Set<String> _selectedParticipantIds = {};

  @override
  void initState() {
    super.initState();
    _startTime = TimeOfDay.now();
    _endTime = TimeOfDay(hour: TimeOfDay.now().hour + 1, minute: 0);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() async {
    setState(() {
      _isLoading = true;
    });

    await CreateEventService.submitEvent(
      context: context,
      formKey: _formKey,
      selectedDate: widget.selectedDate,
      startTime: _startTime,
      endTime: _endTime,
      title: _titleController.text,
      description: _descriptionController.text,
      selectedParticipantIds: _selectedParticipantIds,
      onSuccess: () {
        if (mounted) Navigator.of(context).pop();
      },
      onError: _showErrorDialog,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _toggleParticipant(String id, bool selected) {
    setState(() {
      if (selected) {
        _selectedParticipantIds.add(id);
      } else {
        _selectedParticipantIds.remove(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Event')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Event Title'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter an event title'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              EventWidget(
                selectedDate: widget.selectedDate,
                startTime: _startTime,
                endTime: _endTime,
                onStartTimeChanged: (time) => setState(() => _startTime = time),
                onEndTimeChanged: (time) => setState(() => _endTime = time),
                selectedParticipantIds: _selectedParticipantIds,
                onParticipantToggle: _toggleParticipant,
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Create Event'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
