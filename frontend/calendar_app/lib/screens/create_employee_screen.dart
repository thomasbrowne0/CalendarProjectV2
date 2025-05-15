import 'package:flutter/material.dart';
import 'package:calendar_app/services/create_employee_service.dart';

class CreateEmployeeScreen extends StatefulWidget {
  const CreateEmployeeScreen({super.key});

  @override
  _CreateEmployeeScreenState createState() => _CreateEmployeeScreenState();
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

  late final CreateEmployeeService _employeeService;

  @override
  void initState() {
    super.initState();
    _employeeService = CreateEmployeeService(context);
  }

  void _setLoading(bool value) {
    setState(() {
      _isLoading = value;
    });
  }

  void _submit() {
    _employeeService.submit(
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
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _jobTitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Employee'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'First Name'),
                validator: (value) => value == null || value.isEmpty ? 'Please enter first name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
                validator: (value) => value == null || value.isEmpty ? 'Please enter last name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value == null || !value.contains('@') ? 'Please enter a valid email' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) => value == null || value.length < 6 ? 'Password must be at least 6 characters' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(labelText: 'Confirm Password'),
                obscureText: true,
                validator: (value) => value == null || value.isEmpty ? 'Please confirm password' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _jobTitleController,
                decoration: const InputDecoration(labelText: 'Job Title'),
                validator: (value) => value == null || value.isEmpty ? 'Please enter job title' : null,
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _submit,
                  child: const Text('ADD EMPLOYEE'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
