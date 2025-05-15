import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calendar_app/providers/calendar_provider.dart';
import 'package:calendar_app/providers/company_provider.dart';
import 'package:intl/intl.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  _CreateEventScreenState createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  DateTime _endDate = DateTime.now();
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  
  final Set<String> _selectedParticipantIds = {};
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate != null) {
      setState(() {
        _startDate = pickedDate;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate;
        }
      });
    }
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (pickedTime != null) {
      setState(() {
        _startTime = pickedTime;
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _endDate.isBefore(_startDate) ? _startDate : _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate != null) {
      setState(() {
        _endDate = pickedDate;
      });
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (pickedTime != null) {
      setState(() {
        _endTime = pickedTime;
      });
    }
  }

  DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final startDateTime = _combineDateAndTime(_startDate, _startTime);
    final endDateTime = _combineDateAndTime(_endDate, _endTime);

    if (endDateTime.isBefore(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final companyId = Provider.of<CompanyProvider>(context, listen: false).selectedCompany!.id;
      
      // Convert selected participant IDs to List<String>
      List<String> participantIds = _selectedParticipantIds.toList();
      
      // Debug output
      print("Creating event with participants: $participantIds");
      
      await Provider.of<CalendarProvider>(context, listen: false).createEvent(
        companyId,
        _titleController.text,
        _descriptionController.text,
        startDateTime,
        endDateTime,
        participantIds,
      );
      Navigator.of(context).pop();
    } catch (error) {
      _showErrorDialog('Failed to create event', error.toString());
    }

    setState(() {
      _isLoading = false;
    });
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

  @override
  Widget build(BuildContext context) {
    final employees = Provider.of<CompanyProvider>(context).employees;
    final dateFormat = DateFormat('MMM dd, yyyy');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Event'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Event Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an event title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              const Text('Start Date and Time', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(
                    child: Text(dateFormat.format(_startDate)),
                  ),
                  TextButton(
                    onPressed: () => _selectStartDate(context),
                    child: const Text('Change Date'),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(_startTime.format(context)),
                  ),
                  TextButton(
                    onPressed: () => _selectStartTime(context),
                    child: const Text('Change Time'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('End Date and Time', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(
                    child: Text(dateFormat.format(_endDate)),
                  ),
                  TextButton(
                    onPressed: () => _selectEndDate(context),
                    child: const Text('Change Date'),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(_endTime.format(context)),
                  ),
                  TextButton(
                    onPressed: () => _selectEndTime(context),
                    child: const Text('Change Time'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Participants', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (employees.isEmpty)
                const Text('No employees available')
              else
                ...employees.map((employee) => CheckboxListTile(
                  title: Text('${employee.firstName} ${employee.lastName}'),
                  subtitle: Text(employee.jobTitle),
                  value: _selectedParticipantIds.contains(employee.id),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedParticipantIds.add(employee.id);
                      } else {
                        _selectedParticipantIds.remove(employee.id);
                      }
                    });
                  },
                )),
              const SizedBox(height: 20),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _submit,
                  child: const Text('CREATE EVENT'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
