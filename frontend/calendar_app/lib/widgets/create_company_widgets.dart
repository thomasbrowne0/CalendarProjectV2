import 'package:flutter/material.dart';

class CreateCompanyWidgets {
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

  static Widget submitButton(VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      child: const Text('CREATE COMPANY'),
    );
  }

  static Widget loadingIndicator() {
    return const Center(child: CircularProgressIndicator());
  }
}
