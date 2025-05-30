import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

class ThemeSwitch extends StatelessWidget {
  const ThemeSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) =>
          Switch(
            value: themeProvider.themeMode == ThemeMode.dark,
            onChanged: (_) => themeProvider.toggleTheme(),
            activeColor: const Color(0xFFFFFFFF),
          ),
    );
  }
}
