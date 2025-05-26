import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calendar_app/providers/auth_provider.dart';
import 'package:calendar_app/widgets/display/theme_switch.dart';

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class AppBarActions extends StatelessWidget {
  final Widget? additionalAction;

  const AppBarActions({super.key, this.additionalAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const ThemeSwitch(),
        if (additionalAction != null) additionalAction!,
        IconButton(
          icon: const Icon(Icons.exit_to_app),
          onPressed: () {
            Provider.of<AuthProvider>(context, listen: false).logout();
          },
        ),
      ],
    );
  }
}

class CalendarBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;
  final String? employeesLabel;

  const CalendarBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    this.employeesLabel,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: onTap,
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'Calendar',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.people),
          label: employeesLabel ?? 'Colleagues',
        ),
      ],
    );
  }
}
