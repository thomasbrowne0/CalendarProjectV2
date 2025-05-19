import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calendar_app/providers/company_provider.dart';
import 'package:calendar_app/widgets/create_event_widgets.dart';
import 'package:calendar_app/services/create_event_service.dart';

import '../utils/dialog_util.dart';

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

  late DateTime _startDate;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  late DateTime _endDate;
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);

  final Set<String> _selectedParticipantIds = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startDate = widget.selectedDate;
    _endDate = widget.selectedDate;
  }
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _toggleParticipant(String id, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedParticipantIds.add(id);
      } else {
        _selectedParticipantIds.remove(id);
      }
    });
  }

  void _setLoading(bool value) => setState(() => _isLoading = value);

  @override
  Widget build(BuildContext context) {
    final employees = Provider.of<CompanyProvider>(context).employees;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Event')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            CreateEventWidgets.buildTextField(
              controller: _titleController,
              label: 'Event Title',
              validator: (value) => (value == null || value.isEmpty) ? 'Please enter an event title' : null,
            ),
            const SizedBox(height: 12),
            CreateEventWidgets.buildTextField(
              controller: _descriptionController,
              label: 'Description',
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            const Text('Start Time', style: TextStyle(fontWeight: FontWeight.bold)),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text('Date: ${CreateEventWidgets.dateFormat.format(_startDate)}'),
            ),
            CreateEventWidgets.buildDateTimeRow(
              label: 'Time',
              displayText: _startTime.format(context),
              onPressed: () async {
                final picked = await CreateEventService.pickTime(context, _startTime);
                if (picked != null) setState(() => _startTime = picked);
              },
            ),
            const SizedBox(height: 16),
            const Text('End Time', style: TextStyle(fontWeight: FontWeight.bold)),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text('Date: ${CreateEventWidgets.dateFormat.format(_endDate)}'),
            ),
            CreateEventWidgets.buildDateTimeRow(
              label: 'Time',
              displayText: _endTime.format(context),
              onPressed: () async {
                final picked = await CreateEventService.pickTime(context, _endTime);
                if (picked != null) setState(() => _endTime = picked);
              },
            ),
            const SizedBox(height: 20),
            const Text('Participants', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...CreateEventWidgets.buildParticipantCheckboxes(
              employees: employees,
              selectedIds: _selectedParticipantIds,
              onChanged: _toggleParticipant,
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                onPressed: () {
                  CreateEventService.submit(
                    context: context,
                    formKey: _formKey,
                    titleController: _titleController,
                    descriptionController: _descriptionController,
                    startDate: _startDate,
                    startTime: _startTime,
                    endDate: _endDate,
                    endTime: _endTime,
                    selectedParticipantIds: _selectedParticipantIds,
                    onSuccess: () => Navigator.of(context).pop(),
                    showError: (title, msg) => DialogUtil.showErrorDialog(context, title, msg),
                    setLoading: _setLoading,
                  );
                },
                child: const Text('CREATE EVENT'),
              ),
          ]),
        ),
      ),
    );
  }
}