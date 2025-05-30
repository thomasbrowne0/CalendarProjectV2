import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubit/calendar_cubit.dart';
import '../../cubit/calendar_state.dart';
import '../calendar/calendar_widgets.dart';
import '../../services/company_calendar_service.dart';

class EventsListView extends StatelessWidget {
  const EventsListView({super.key});

  @override
  Widget build(BuildContext context) {
    final calendarService = CompanyCalendarService();

    return BlocBuilder<CalendarCubit, CalendarState>(
      buildWhen: (previous, current) =>
      previous.events != current.events ||
          previous.focusedDay != current.focusedDay,
      builder: (context, state) {
        final events = context.read<CalendarCubit>().getEventsForDay(
            state.focusedDay);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Icon(
                    Icons.event,
                    color: Theme
                        .of(context)
                        .colorScheme
                        .primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    calendarService.getEventsHeaderText(state.focusedDay),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (events.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.event_busy,
                        size: 64,
                        color: Theme
                            .of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No events for this day',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme
                              .of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (ctx, index) =>
                      CalendarWidgets.buildEventCard(events[index], context),
                ),
              ),
          ],
        );
      },
    );
  }
}
