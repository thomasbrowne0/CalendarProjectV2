import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:calendar_app/providers/auth_provider.dart';
import 'package:calendar_app/providers/company_provider.dart';
import 'package:calendar_app/screens/create_event_screen.dart';
import 'package:calendar_app/widgets/calendar_widgets.dart';
import '../cubit/calendar_cubit.dart';
import '../widgets/calendar/calendar_view.dart';
import '../widgets/calendar/event_list_view.dart';

class CompanyCalendarScreen extends StatefulWidget {
  const CompanyCalendarScreen({super.key});

  @override
  State<CompanyCalendarScreen> createState() => _CompanyCalendarScreenState();
}

class _CompanyCalendarScreenState extends State<CompanyCalendarScreen> {
  bool _isInit = true;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    if (_isInit) {
      setState(() {
        _isLoading = true;
      });

      final companyProvider = Provider.of<CompanyProvider>(context, listen: false);
      if (companyProvider.selectedCompany != null) {
        final companyId = companyProvider.selectedCompany!.id;

        context.read<CalendarCubit>().setCompanyId(companyId);
        context.read<CalendarCubit>().fetchEvents(companyId).then((_) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }).catchError((error) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to load events: ${error.toString()}')),
            );
          }
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
      _isInit = false;
    }
    super.didChangeDependencies();
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
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        body: CalendarWidgets.noCompanySelectedWidget(context),
      );
    }

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: const [
                CalendarView(),
                Expanded(child: EventListView()),
              ],
            ),
      floatingActionButton: isCompanyOwner
          ? FloatingActionButton(
              onPressed: () {
                final focusedDate = context.read<CalendarCubit>().state.focusedDay;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CreateEventScreen(selectedDate: focusedDate),
                  ),
                );
              },
              tooltip: 'Create Event',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
