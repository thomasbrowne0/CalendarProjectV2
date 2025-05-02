import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calendar_app/providers/company_provider.dart';
import 'package:calendar_app/providers/auth_provider.dart';
import 'package:calendar_app/screens/create_employee_screen.dart';

class EmployeeListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final companyProvider = Provider.of<CompanyProvider>(context);
    final employees = companyProvider.employees;
    final isCompanyOwner = Provider.of<AuthProvider>(context).isCompanyOwner;

    return Scaffold(
      body: employees.isEmpty
          ? Center(
              child: Text('No employees found.'),
            )
          : ListView.builder(
              itemCount: employees.length,
              itemBuilder: (ctx, index) {
                final employee = employees[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
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
              child: Icon(Icons.add),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CreateEmployeeScreen(),
                  ),
                );
              },
              tooltip: 'Add Employee',
            )
          : null,
    );
  }
}
