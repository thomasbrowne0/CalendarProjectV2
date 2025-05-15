import 'package:flutter/material.dart';
import 'package:calendar_app/widgets/login_widget.dart';
import 'package:calendar_app/services/login_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  late final LoginService _loginService;

  @override
  void initState() {
    super.initState();
    _loginService = LoginService(context);
  }

  void _setLoading(bool value) {
    setState(() {
      _isLoading = value;
    });
  }

  void _submit() {
    _loginService.submit(
      formKey: _formKey,
      emailController: _emailController,
      passwordController: _passwordController,
      setLoading: _setLoading,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Calendar'),
      ),
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
                  const LoginTitle(),
                  const SizedBox(height: 20),
                  EmailFormField(controller: _emailController),
                  const SizedBox(height: 10),
                  PasswordFormField(controller: _passwordController),
                  const SizedBox(height: 20),
                  LoginButton(
                    onPressed: _submit,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 10),
                  const RegisterButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
