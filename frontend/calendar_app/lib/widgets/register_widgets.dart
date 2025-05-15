import 'package:flutter/material.dart';

class RegisterWidgets {
  static Widget title(BuildContext context) {
    return Text(
      'Register',
      style: Theme.of(context).textTheme.headlineSmall,
    );
  }

  static Widget firstNameField(TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(labelText: 'First Name'),
      validator: (value) =>
      (value == null || value.isEmpty) ? 'Please enter your first name' : null,
    );
  }

  static Widget lastNameField(TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(labelText: 'Last Name'),
      validator: (value) =>
      (value == null || value.isEmpty) ? 'Please enter your last name' : null,
    );
  }

  static Widget emailField(TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(labelText: 'Email'),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.isEmpty || !value.contains('@')) {
          return 'Please enter a valid email address';
        }
        return null;
      },
    );
  }

  static Widget passwordField(TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(labelText: 'Password'),
      obscureText: true,
      validator: (value) {
        if (value == null || value.isEmpty || value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }

  static Widget confirmPasswordField(
      TextEditingController controller, TextEditingController passwordController) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(labelText: 'Confirm Password'),
      obscureText: true,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please confirm your password';
        }
        if (value != passwordController.text) {
          return 'Passwords do not match';
        }
        return null;
      },
    );
  }

  static Widget registerButton(VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
      ),
      child: const Text('REGISTER'),
    );
  }

  static Widget backToLoginButton(BuildContext context) {
    return TextButton(
      onPressed: () => Navigator.of(context).pop(),
      child: const Text('Back to Login'),
    );
  }
}
