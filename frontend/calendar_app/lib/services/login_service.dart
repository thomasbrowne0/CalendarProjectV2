import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calendar_app/providers/auth_provider.dart';

class LoginService {
  static Future<void> submitLoginForm({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    try {
      await Provider.of<AuthProvider>(context, listen: false).login(
        email.trim(),
        password.trim(),
      );
    } catch (error) {
      _showErrorDialog(context, 'Authentication failed', error.toString());
    }
  }

  static void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
