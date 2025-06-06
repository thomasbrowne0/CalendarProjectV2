import 'package:flutter/material.dart';
import 'package:calendar_app/services/login_service.dart';
import 'package:calendar_app/widgets/auth/auth_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    await LoginService.submitLoginForm(
      context: context,
      email: _emailController.text,
      password: _passwordController.text,
    );

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Company Calendar')),
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
                  AuthWidgets.loginTitle(context),
                  const SizedBox(height: 20),
                  AuthWidgets.emailField(_emailController),
                  const SizedBox(height: 10),
                  AuthWidgets.passwordField(_passwordController),
                  const SizedBox(height: 20),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : AuthWidgets.loginButton(_submit),
                  const SizedBox(height: 10),
                  AuthWidgets.registerLink(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
