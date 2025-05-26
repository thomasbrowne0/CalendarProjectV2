import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calendar_app/providers/company_provider.dart';
import 'package:calendar_app/widgets/events/event_form.dart';
import 'package:calendar_app/services/event_service.dart';
import '../../utils/dialog_util.dart';

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
              buttonText: 'CREATE EVENT',
              onPressed: () {
                EventService.submit(
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
            ),
          ]),
        ),
      ),
    );
  }
}