import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/company_provider.dart';

class CreateCompanyService {
  static Future<void> submit({
    required BuildContext context,
    required GlobalKey<FormState> formKey,
    required TextEditingController nameController,
    required TextEditingController cvrController,
    required Function(bool) setLoading,
  }) async {
    if (!formKey.currentState!.validate()) return;

    setLoading(true);
    try {
      await Provider.of<CompanyProvider>(context, listen: false).createCompany(
        nameController.text.trim(),
        cvrController.text.trim(),
      );
      Navigator.of(context).pop();
    } catch (error) {
      _showErrorDialog(context, 'Failed to create company', error.toString());
    }
    setLoading(false);
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
