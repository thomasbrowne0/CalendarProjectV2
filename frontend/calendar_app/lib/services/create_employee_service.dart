import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/company_provider.dart';
import '../utils/dialog_util.dart';

class CreateEmployeeService {
  static Future<void> submit({
    required BuildContext context,
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
      final navigator = Navigator.of(context);
      final companyProvider =
          Provider.of<CompanyProvider>(context, listen: false);
      await companyProvider.addEmployee(
        companyProvider.selectedCompany!.id,
        firstNameController.text.trim(),
        lastNameController.text.trim(),
        emailController.text.trim(),
        passwordController.text,
        jobTitleController.text.trim(),
      );
      navigator.pop();
    } catch (error) {
      if (context.mounted) {
        DialogUtil.showErrorDialog(
            context, 'Failed to add employee', error.toString());
      }
    }
    setLoading(false);
  }
}
