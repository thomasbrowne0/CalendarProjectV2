import 'package:flutter/material.dart';
import 'package:calendar_app/services/create_company_service.dart';

class CreateCompanyScreen extends StatefulWidget {
  const CreateCompanyScreen({super.key});

  @override
  _CreateCompanyScreenState createState() => _CreateCompanyScreenState();
}

class _CreateCompanyScreenState extends State<CreateCompanyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cvrController = TextEditingController();
  bool _isLoading = false;

  late final CreateCompanyService _companyService;

  @override
  void initState() {
    super.initState();
    _companyService = CreateCompanyService(context);
  }

  void _setLoading(bool value) {
    setState(() {
      _isLoading = value;
    });
  }

  void _submit() {
    _companyService.submit(
      formKey: _formKey,
      nameController: _nameController,
      cvrController: _cvrController,
      setLoading: _setLoading,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cvrController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Company'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Company Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a company name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cvrController,
                decoration: const InputDecoration(labelText: 'CVR Number'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a CVR number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _submit,
                  child: const Text('CREATE COMPANY'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
