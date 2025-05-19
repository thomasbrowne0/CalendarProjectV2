import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calendar_app/models/calendar_event.dart';
import 'package:calendar_app/providers/company_provider.dart';
import 'package:calendar_app/widgets/create_event_widgets.dart';
import 'package:calendar_app/services/create_event_service.dart';
import 'package:calendar_app/cubit/calendar_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
              CreateEventWidgets.buildTextField(
                controller: _titleController,
                label: 'Event Title',
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Please enter an event title' : null,
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
    try {
      // Combine dates with selected times
      final startDateTime = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        _startTime.hour,
        _startTime.minute,
      );

      final endDateTime = DateTime(
        _endDate.year,
        _endDate.month,
        _endDate.day,
        _endTime.hour,
        _endTime.minute,
      );

      final companyId = Provider.of<CompanyProvider>(context, listen: false).selectedCompany!.id;
      await context.read<CalendarCubit>().updateEvent(
        widget.event.id,
        companyId,
        _titleController.text,
        _descriptionController.text,
        startDateTime.toUtc(),
        endDateTime.toUtc(),
        _selectedParticipantIds.toList(),
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        DialogUtil.showErrorDialog(
          context,
          'Failed to Update Event. Check event times and participants',
          error.toString(),
        );
      }
    } finally {
      _setLoading(false);
    }
  }
}
