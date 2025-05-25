import 'package:flutter/material.dart';
import '../services/create_company_service.dart';
import '../widgets/create_company_widgets.dart';

class CreateCompanyScreen extends StatefulWidget {
  const CreateCompanyScreen({super.key});

  @override
  State<CreateCompanyScreen> createState() => _CreateCompanyScreenState();
}

class _CreateCompanyScreenState extends State<CreateCompanyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cvrController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _cvrController.dispose();
    super.dispose();
  }

  void _setLoading(bool value) {
    setState(() {
      _isLoading = value;
    });
  }

  void _handleSubmit() {
    CreateCompanyService.submit(
      context: context,
      formKey: _formKey,
      nameController: _nameController,
      cvrController: _cvrController,
      setLoading: _setLoading,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Company')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CreateCompanyWidgets.nameField(_nameController),
              const SizedBox(height: 12),
              CreateCompanyWidgets.cvrField(_cvrController),
              const SizedBox(height: 20),
              _isLoading
                  ? CreateCompanyWidgets.loadingIndicator()
                  : CreateCompanyWidgets.submitButton(_handleSubmit),
            ],
          ),
        ),
      ),
    );
  }
}
