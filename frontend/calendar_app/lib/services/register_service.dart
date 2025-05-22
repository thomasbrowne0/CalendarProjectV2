import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calendar_app/providers/auth_provider.dart';

import '../utils/dialog_util.dart';

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
      DialogUtil.showErrorDialog(
          context, 'Password mismatch', 'Passwords do not match');
      return false;
    }

    try {
      await Provider.of<AuthProvider>(context, listen: false)
          .registerCompanyOwner(
        firstName.trim(),
        lastName.trim(),
        email.trim(),
        password.trim(),
      );
      return true;
    } catch (error) {
      if (context.mounted) {
        DialogUtil.showErrorDialog(
            context, 'Registration failed', error.toString());
      }
      return false;
    }
  }
}
