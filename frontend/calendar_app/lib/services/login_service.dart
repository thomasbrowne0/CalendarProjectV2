import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calendar_app/providers/auth_provider.dart';

import '../utils/dialog_util.dart';

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
      DialogUtil.showErrorDialog(context, 'Authentication failed', error.toString());
    }
  }
}
