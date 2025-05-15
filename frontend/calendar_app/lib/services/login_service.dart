import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calendar_app/providers/auth_provider.dart';

class LoginService {
  final BuildContext context;

  LoginService(this.context);

  Future<void> submit({
    required GlobalKey<FormState> formKey,
    required TextEditingController emailController,
    required TextEditingController passwordController,
    required Function(bool) setLoading,
  }) async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    setLoading(true);

    try {
      await Provider.of<AuthProvider>(context, listen: false).login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );
    } catch (error) {
      _showErrorDialog('Authentication failed', error.toString());
    }

    setLoading(false);
  }

  void _showErrorDialog(String title, String message) {
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
