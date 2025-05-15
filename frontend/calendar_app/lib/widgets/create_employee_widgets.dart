import 'package:flutter/material.dart';

class CreateEmployeeWidgets {
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
  static Widget loadingIndicator() => const Center(child: CircularProgressIndicator());

  static Widget submitButton(VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      child: const Text('ADD EMPLOYEE'),
    );
  }
}
