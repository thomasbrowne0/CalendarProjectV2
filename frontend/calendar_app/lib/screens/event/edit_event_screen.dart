import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calendar_app/models/calendar_event.dart';
import 'package:calendar_app/providers/company_provider.dart';
import 'package:calendar_app/widgets/events/event_form.dart';
import '../../services/event_service.dart';
import '../../utils/dialog_util.dart';

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
              EventFormWidgets.buildEventFormFields(
                titleController: _titleController,
                descriptionController: _descriptionController,
              ),
              const SizedBox(height: 20),
              EventFormWidgets.buildTimeSection(
                sectionTitle: 'Start Time',
                date: _startDate,
                time: _startTime,
                context: context,
                onTimeChanged: (picked) => setState(() => _startTime = picked),
              ),
              const SizedBox(height: 16),
              EventFormWidgets.buildTimeSection(
                sectionTitle: 'End Time',
                date: _endDate,
                time: _endTime,
                context: context,
                onTimeChanged: (picked) => setState(() => _endTime = picked),
              ),
              const SizedBox(height: 20),
              EventFormWidgets.buildParticipantsSection(
                employees: employees,
                selectedIds: _selectedParticipantIds,
                onParticipantToggle: _toggleParticipant,
              ),
              const SizedBox(height: 20),
              EventFormWidgets.buildSubmitButton(
                isLoading: _isLoading,
                buttonText: 'UPDATE EVENT',
                onPressed: () => _updateEvent(context),
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
