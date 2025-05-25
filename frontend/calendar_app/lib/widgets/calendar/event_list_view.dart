import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:calendar_app/cubit/calendar_cubit.dart';
import 'package:calendar_app/cubit/calendar_state.dart';
import 'package:calendar_app/widgets/calendar_widgets.dart';
import 'package:intl/intl.dart';

class EventListView extends StatelessWidget {
  const EventListView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalendarCubit, CalendarState>(
      buildWhen: (previous, current) =>
          previous.events != current.events ||
          previous.focusedDay != current.focusedDay,
      builder: (context, state) {
        final events = context.read<CalendarCubit>().getEventsForDay(state.focusedDay);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, state.focusedDay),
            if (events.isEmpty)
              _buildEmptyState(context)
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

  Widget _buildHeader(BuildContext context, DateTime focusedDay) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Icon(
            Icons.event,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            'Events for ${DateFormat('MMMM d, yyyy').format(focusedDay)}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No events for this day',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
