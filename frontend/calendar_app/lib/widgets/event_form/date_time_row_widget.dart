import 'package:flutter/material.dart';

class DateTimeRowWidget extends StatelessWidget {
  final String label;
  final String displayText;
  final VoidCallback onPressed;

  const DateTimeRowWidget({
    super.key,
    required this.label,
    required this.displayText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(displayText)),
        TextButton(
          onPressed: onPressed, 
          child: Text('Change $label'),
        ),
      ],
    );
  }
}
