import 'package:calendar_app/utils/dialog_util.dart';
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

    final navigator = Navigator.of(context);
    final companyProvider =
    Provider.of<CompanyProvider>(context, listen: false);
    setLoading(true);
    try {
      await companyProvider.createCompany(
        nameController.text.trim(),
        cvrController.text.trim(),
      );
      navigator.pop();
    } catch (error) {
      if (context.mounted) {
        DialogUtil.showErrorDialog(
            context, 'Failed to create company', error.toString());
      }
    }
    setLoading(false);
  }
}
