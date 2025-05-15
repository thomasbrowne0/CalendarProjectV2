import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calendar_app/providers/company_provider.dart';

class CreateCompanyService {
  final BuildContext context;

  CreateCompanyService(this.context);

  Future<void> submit({
    required GlobalKey<FormState> formKey,
    required TextEditingController nameController,
    required TextEditingController cvrController,
    required Function(bool) setLoading,
  }) async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    setLoading(true);

    try {
      await Provider.of<CompanyProvider>(context, listen: false).createCompany(
        nameController.text.trim(),
        cvrController.text.trim(),
      );
      Navigator.of(context).pop();
    } catch (error) {
      _showErrorDialog('Failed to create company', error.toString());
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
