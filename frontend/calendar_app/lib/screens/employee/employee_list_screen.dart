import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calendar_app/providers/company_provider.dart';
import 'package:calendar_app/providers/auth_provider.dart';
import 'package:calendar_app/screens/employee/create_employee_screen.dart';

class EmployeeListScreen extends StatelessWidget {
  const EmployeeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final companyProvider = Provider.of<CompanyProvider>(context);
    final employees = companyProvider.employees;
    final isCompanyOwner = Provider
        .of<AuthProvider>(context)
        .isCompanyOwner;

    return Scaffold(
      body: employees.isEmpty
          ? const Center(
        child: Text('No employees found.'),
      )
          : ListView.builder(
        itemCount: employees.length,
        itemBuilder: (ctx, index) {
          final employee = employees[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            child: ListTile(
              leading: CircleAvatar(
                child: Text(employee.firstName[0] + employee.lastName[0]),
              ),
              title: Text('${employee.firstName} ${employee.lastName}'),
              subtitle: Text('${employee.jobTitle}\n${employee.email}'),
              isThreeLine: true,
            ),
          );
        },
      ),
      floatingActionButton: isCompanyOwner
          ? FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const CreateEmployeeScreen(),
            ),
          );
        },
        tooltip: 'Add Employee',
        child: const Icon(Icons.add),
      )
          : null,
    );
  }
}
