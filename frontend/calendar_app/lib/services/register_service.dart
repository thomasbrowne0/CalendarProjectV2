import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calendar_app/providers/auth_provider.dart';

class RegisterService {
  static Future<bool> submitRegistrationForm({
    required BuildContext context,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    if (password != confirmPassword) {
      _showErrorDialog(context, 'Password mismatch', 'Passwords do not match');
      return false;
    }

    try {
      await Provider.of<AuthProvider>(context, listen: false).registerCompanyOwner(
        firstName.trim(),
        lastName.trim(),
        email.trim(),
        password.trim(),
      );
      return true;
    } catch (error) {
      _showErrorDialog(context, 'Registration failed', error.toString());
      return false;
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
