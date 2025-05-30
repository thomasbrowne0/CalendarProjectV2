import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:calendar_app/providers/auth_provider.dart';
import 'package:calendar_app/providers/company_provider.dart';
import 'package:calendar_app/screens/event/create_event_screen.dart';
import 'package:calendar_app/widgets/calendar/calendar_widgets.dart';
import 'package:calendar_app/widgets/calendar/company_calendar_view.dart';
import 'package:calendar_app/widgets/calendar/calendar_header.dart';
import 'package:calendar_app/widgets/events/events_list_view.dart';
import '../../cubit/calendar_cubit.dart';
import 'package:calendar_app/services/company_calendar_service.dart';

class CompanyCalendarScreen extends StatefulWidget {
  const CompanyCalendarScreen({super.key});

  @override
  State<CompanyCalendarScreen> createState() => _CompanyCalendarScreenState();
}

class _CompanyCalendarScreenState extends State<CompanyCalendarScreen> {
  bool _isInit = true;
  bool _isLoading = false;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  final CompanyCalendarService _calendarService = CompanyCalendarService();

  @override
  void didChangeDependencies() {
    if (_isInit) {
      _initializeCalendar();
      _isInit = false;
    }
    super.didChangeDependencies();
  }

  void _initializeCalendar() {
    setState(() => _isLoading = true);

    final companyProvider = Provider.of<CompanyProvider>(
        context, listen: false);
    if (companyProvider.selectedCompany != null) {
      final companyId = companyProvider.selectedCompany!.id;

      context.read<CalendarCubit>().setCompanyId(companyId);
      context.read<CalendarCubit>().fetchEvents(companyId).then((_) {
        if (mounted) setState(() => _isLoading = false);
      }).catchError((error) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showErrorSnackBar('Failed to load events: ${error.toString()}');
        }
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _toggleCalendarFormat() {
    setState(() {
      _calendarFormat = _calendarService.getNextCalendarFormat(_calendarFormat);
    });
  }

  void _onCalendarFormatChanged(CalendarFormat format) {
    setState(() => _calendarFormat = format);
  }

  void _navigateToCreateEvent() {
    final focusedDate = context
        .read<CalendarCubit>()
        .state
        .focusedDay;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateEventScreen(selectedDate: focusedDate),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final companyProvider = Provider.of<CompanyProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final selectedCompany = companyProvider.selectedCompany;
    final isCompanyOwner = authProvider.user?.userType == 'CompanyOwner';

    if (selectedCompany == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Company Calendar'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: CalendarWidgets.noCompanySelectedWidget(context),
      );
    }

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          CalendarHeader(
            calendarFormat: _calendarFormat,
            onFormatToggle: _toggleCalendarFormat,
          ),
          CompanyCalendarView(
            companyId: selectedCompany.id,
            calendarFormat: _calendarFormat,
            onFormatChanged: _onCalendarFormatChanged,
          ),
          const Expanded(child: EventsListView()),
        ],
      ),
      floatingActionButton: isCompanyOwner
          ? FloatingActionButton(
        onPressed: _navigateToCreateEvent,
        tooltip: 'Create Event',
        child: const Icon(Icons.add),
      )
          : null,
    );
  }
}
