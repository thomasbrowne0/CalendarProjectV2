import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calendar_app/models/calendar_event.dart';
import 'package:calendar_app/providers/company_provider.dart';
import 'package:calendar_app/widgets/event_widgets.dart';
import 'package:calendar_app/cubit/calendar_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/event_service.dart';
import '../utils/dialog_util.dart';

class EditEventScreen extends StatefulWidget {
  final CalendarEvent event;

  const EditEventScreen({super.key, required this.event});

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _startDate;
  late TimeOfDay _startTime;
  late DateTime _endDate;
  late TimeOfDay _endTime;
  late Set<String> _selectedParticipantIds;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event.title);
    _descriptionController = TextEditingController(text: widget.event.description);
    _startDate = widget.event.startTime;
    _startTime = TimeOfDay.fromDateTime(widget.event.startTime);
    _endDate = widget.event.endTime;
    _endTime = TimeOfDay.fromDateTime(widget.event.endTime);
    _selectedParticipantIds = widget.event.participants.map((e) => e.id).toSet();
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
      appBar: AppBar(title: const Text('Edit Event')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EventWidgets.buildTextField(
                controller: _titleController,
                label: 'Event Title',
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Please enter an event title' : null,
              ),
              const SizedBox(height: 12),
              EventWidgets.buildTextField(
                controller: _descriptionController,
                label: 'Description',
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              const Text('Start Time', style: TextStyle(fontWeight: FontWeight.bold)),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text('Date: ${EventWidgets.dateFormat.format(_startDate)}'),
              ),
              EventWidgets.buildDateTimeRow(
                label: 'Time',
                displayText: _startTime.format(context),
                onPressed: () async {
                  final picked = await EventService.pickTime(context, _startTime);
                  if (picked != null) setState(() => _startTime = picked);
                },
              ),
              const SizedBox(height: 16),
              const Text('End Time', style: TextStyle(fontWeight: FontWeight.bold)),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text('Date: ${EventWidgets.dateFormat.format(_endDate)}'),
                ),
              EventWidgets.buildDateTimeRow(
                label: 'Time',
                displayText: _endTime.format(context),
                onPressed: () async {
                  final picked = await EventService.pickTime(context, _endTime);
                  if (picked != null) setState(() => _endTime = picked);
                },
              ),
              const SizedBox(height: 20),
              const Text('Participants', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...EventWidgets.buildParticipantCheckboxes(
                employees: employees,
                selectedIds: _selectedParticipantIds,
                onChanged: _toggleParticipant,
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: () => _updateEvent(context),
                  child: const Text('UPDATE EVENT'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateEvent(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    _setLoading(true);
    await EventService.updateEvent(
      context: context,
      eventId: widget.event.id,
      title: _titleController.text,
      description: _descriptionController.text,
      startDate: _startDate,
      startTime: _startTime,
      endDate: _endDate,
      endTime: _endTime,
      participantIds: _selectedParticipantIds.toList(),
      onSuccess: () {
        if (mounted) Navigator.of(context).pop(true);
      },
      onError: (errorMsg) {
        if (mounted) {
          DialogUtil.showErrorDialog(
            context,
            'Failed to Update Event. Check event times and participants',
            errorMsg,
          );
        }
      },
    );
    _setLoading(false);
  }
}
