import 'package:flutter/material.dart';
import 'package:calendar_app/services/register_service.dart';
import 'package:calendar_app/widgets/register_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
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

    if (success) Navigator.of(context).pop();
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
                  RegisterWidgets.title(context),
                  const SizedBox(height: 20),
                  RegisterWidgets.firstNameField(_firstNameController),
                  const SizedBox(height: 10),
                  RegisterWidgets.lastNameField(_lastNameController),
                  const SizedBox(height: 10),
                  RegisterWidgets.emailField(_emailController),
                  const SizedBox(height: 10),
                  RegisterWidgets.passwordField(_passwordController),
                  const SizedBox(height: 10),
                  RegisterWidgets.confirmPasswordField(
                    _confirmPasswordController,
                    _passwordController,
                  ),
                  const SizedBox(height: 20),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : RegisterWidgets.registerButton(_submit),
                  const SizedBox(height: 10),
                  RegisterWidgets.backToLoginButton(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
