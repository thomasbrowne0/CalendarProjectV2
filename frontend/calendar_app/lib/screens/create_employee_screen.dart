import 'package:flutter/material.dart';
import '../services/create_employee_service.dart';
import '../widgets/create_employee_widgets.dart';

class CreateEmployeeScreen extends StatefulWidget {
  const CreateEmployeeScreen({super.key});

  @override
  State<CreateEmployeeScreen> createState() => _CreateEmployeeScreenState();
}

class _CreateEmployeeScreenState extends State<CreateEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _jobTitleController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _jobTitleController.dispose();
    super.dispose();
  }

  void _setLoading(bool value) {
    setState(() {
      _isLoading = value;
    });
  }

  void _handleSubmit() {
    CreateEmployeeService.submit(
      context: context,
      formKey: _formKey,
      firstNameController: _firstNameController,
      lastNameController: _lastNameController,
      emailController: _emailController,
      passwordController: _passwordController,
      confirmPasswordController: _confirmPasswordController,
      jobTitleController: _jobTitleController,
      setLoading: _setLoading,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Employee')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CreateEmployeeWidgets.textField(
                controller: _firstNameController,
                label: 'First Name',
                validator: (v) => (v == null || v.isEmpty) ? 'Please enter first name' : null,
              ),
              CreateEmployeeWidgets.spacing(),
              CreateEmployeeWidgets.textField(
                controller: _lastNameController,
                label: 'Last Name',
                validator: (v) => (v == null || v.isEmpty) ? 'Please enter last name' : null,
              ),
              CreateEmployeeWidgets.spacing(),
              CreateEmployeeWidgets.textField(
                controller: _emailController,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                (v == null || v.isEmpty || !v.contains('@')) ? 'Please enter a valid email' : null,
              ),
              CreateEmployeeWidgets.spacing(),
              CreateEmployeeWidgets.textField(
                controller: _passwordController,
                label: 'Password',
                obscure: true,
                validator: (v) =>
                (v == null || v.isEmpty || v.length < 6) ? 'Password must be at least 6 characters' : null,
              ),
              CreateEmployeeWidgets.spacing(),
              CreateEmployeeWidgets.textField(
                controller: _confirmPasswordController,
                label: 'Confirm Password',
                obscure: true,
                validator: (v) =>
                (v == null || v.isEmpty) ? 'Please confirm password' : null,
              ),
              CreateEmployeeWidgets.spacing(),
              CreateEmployeeWidgets.textField(
                controller: _jobTitleController,
                label: 'Job Title',
                validator: (v) => (v == null || v.isEmpty) ? 'Please enter job title' : null,
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? CreateEmployeeWidgets.loadingIndicator()
                  : CreateEmployeeWidgets.submitButton(_handleSubmit),
            ],
          ),
        ),
      ),
    );
  }
}
