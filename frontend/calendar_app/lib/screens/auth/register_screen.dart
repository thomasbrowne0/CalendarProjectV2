import 'package:flutter/material.dart';
import 'package:calendar_app/services/register_service.dart';
import 'package:calendar_app/widgets/auth/auth_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() async {
    final navigator = Navigator.of(context);

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await RegisterService.submitRegistrationForm(
      context: context,
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );

    setState(() => _isLoading = false);

    if (success) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register as Company Owner')),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AuthWidgets.registerTitle(context),
                  const SizedBox(height: 20),
                  AuthWidgets.firstNameField(_firstNameController),
                  const SizedBox(height: 10),
                  AuthWidgets.lastNameField(_lastNameController),
                  const SizedBox(height: 10),
                  AuthWidgets.emailField(_emailController),
                  const SizedBox(height: 10),
                  AuthWidgets.passwordField(_passwordController),
                  const SizedBox(height: 10),
                  AuthWidgets.confirmPasswordField(
                    _confirmPasswordController,
                    _passwordController,
                  ),
                  const SizedBox(height: 20),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : AuthWidgets.registerButton(_submit),
                  const SizedBox(height: 10),
                  AuthWidgets.backToLoginButton(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
