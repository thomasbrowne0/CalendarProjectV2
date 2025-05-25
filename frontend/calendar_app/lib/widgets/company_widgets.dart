import 'package:flutter/material.dart';

class CompanyWidgets {
  // Company Creation Widgets
  static Widget nameField(TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(labelText: 'Company Name'),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a company name';
        }
        return null;
      },
    );
  }

  static Widget cvrField(TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(labelText: 'CVR Number'),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a CVR number';
        }
        return null;
      },
    );
  }

  static Widget createCompanyButton(VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      child: const Text('CREATE COMPANY'),
    );
  }

  // Employee Creation Widgets
  static Widget textField({
    required TextEditingController controller,
    required String label,
    bool obscure = false,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  static Widget spacing() => const SizedBox(height: 12);

  static Widget loadingIndicator() =>
      const Center(child: CircularProgressIndicator());

  static Widget addEmployeeButton(VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      child: const Text('ADD EMPLOYEE'),
    );
  }
}
