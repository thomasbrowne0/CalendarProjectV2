import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calendar_app/providers/company_provider.dart';

class CreateEmployeeService {
  final BuildContext context;

  CreateEmployeeService(this.context);

  Future<void> submit({
    required GlobalKey<FormState> formKey,
    required TextEditingController firstNameController,
    required TextEditingController lastNameController,
    required TextEditingController emailController,
    required TextEditingController passwordController,
    required TextEditingController confirmPasswordController,
    required TextEditingController jobTitleController,
    required Function(bool) setLoading,
  }) async {
    if (!formKey.currentState!.validate()) return;

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setLoading(true);

    try {
      final companyProvider = Provider.of<CompanyProvider>(context, listen: false);
      final companyId = companyProvider.selectedCompany?.id;

      if (companyId == null) {
        throw Exception("No company selected.");
      }

      await companyProvider.addEmployee(
        companyId,
        firstNameController.text.trim(),
        lastNameController.text.trim(),
        emailController.text.trim(),
        passwordController.text,
        jobTitleController.text.trim(),
      );

      Navigator.of(context).pop();
    } catch (error) {
      _showErrorDialog('Failed to add employee', error.toString());
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
