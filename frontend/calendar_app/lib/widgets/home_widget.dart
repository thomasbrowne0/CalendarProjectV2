import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calendar_app/providers/auth_provider.dart';

class UserProfileMenu extends StatelessWidget {
  final Color textColor;

  const UserProfileMenu({super.key, required this.textColor});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return PopupMenuButton<String>(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(Icons.person, color: textColor),
            const SizedBox(width: 8),
            Text(
              user?.fullName ?? '',
              style: TextStyle(color: textColor),
            ),
          ],
        ),
      ),
      onSelected: (value) {
        if (value == 'logout') {
          Provider.of<AuthProvider>(context, listen: false).logout();
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout),
              SizedBox(width: 8),
              Text('Logout'),
            ],
          ),
        ),
      ],
    );
  }
}

class AppBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;
  final bool isOwner;

  const AppBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.isOwner,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'Calendar',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.people),
          label: isOwner ? 'Employees' : 'Colleagues',
        ),
      ],
    );
  }
}

class LoadingWrapper extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const LoadingWrapper({super.key, required this.isLoading, required this.child});

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : child;
  }
}
